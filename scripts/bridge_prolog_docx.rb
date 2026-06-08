#!/usr/bin/env ruby
# bridge_prolog_docx.rb — Prolog 求解 → 验证 → JSON → DOCX (v3.0 Unified)
# 用法: ruby bridge_prolog_docx.rb <species_key> [stage]
#
# v3.0: 统一 Pipeline — 单次 scryer-prolog 调用，通过 sop_orchestrator.pl 完成全部流程
# v2.0: 集成 SOP 校验真实数据（氨基酸/矿物质/绩效风险）
#       每个数据点标注来源模块

require 'json'
require 'tmpdir'
require 'open3'
require 'fileutils'
require 'time'

SPECIES_KEY = ARGV[0] || 'white_shrimp'
STAGE       = ARGV[1] || 'adult'

RULES_DIR = File.expand_path('~/clacky_workspace/AquaFeedFormulator/rules')
PROJECT_DIR = File.expand_path('~/clacky_workspace/AquaFeedFormulator')
OUTPUT_JSON = File.join(PROJECT_DIR, 'generated', 'recipe_data.json')
DOCX_OUTPUT = File.expand_path('~/Desktop')
ADDITIVES_FILE = File.join(PROJECT_DIR, 'config', 'shrimp_additives.json')
PRICE_BASELINE = '2026-06-08 市场价格 (已执行价格监控校准)'

# ── Species metadata ──────────────────────────────────────
SPECIES_META = {
  'japanese_eel'    => { cn: '日本鳗鲡', en: 'Anguilla japonica', stage_cn: { 'adult' => '成鳗', 'juvenile' => '幼鳗' } },
  'white_shrimp'    => { cn: '南美白对虾', en: 'Litopenaeus vannamei', stage_cn: { 'adult' => '成虾', 'juvenile' => '幼虾' } },
  'common_carp'     => { cn: '鲤鱼', en: 'Cyprinus carpio', stage_cn: { 'adult' => '成鱼', 'juvenile' => '幼鱼' } },
  'grass_carp'      => { cn: '草鱼', en: 'Ctenopharyngodon idella', stage_cn: { 'adult' => '成鱼', 'juvenile' => '幼鱼' } },
  'largemouth_bass' => { cn: '加州鲈', en: 'Micropterus salmoides', stage_cn: { 'adult' => '成鱼', 'juvenile' => '幼鱼' } },
}.freeze

STRATEGY_NAMES = {
  'premium'  => { id: 'A', name: '高鱼粉精品型', desc: '高动物蛋白+强诱食体系。面向高密度精养，追求最高生长速度和成活率。' },
  'balanced' => { id: 'B', name: '平衡型', desc: '动物/植物蛋白均衡。成本与生长性能兼顾，适合主流商业养殖。' },
  'economic' => { id: 'C', name: '经济型', desc: '适度植物蛋白替代。控制原料成本，适合价格敏感市场。' },
}.freeze

CATEGORY_CN = {
  'animal_protein' => '动物蛋白',
  'plant_protein'  => '植物蛋白',
  'energy'         => '淀粉/粘合剂',
  'oil'            => '油脂',
  'mineral'        => '矿物质',
  'additive'       => '添加剂',
}.freeze

# ── Data sources metadata ─────────────────────────────────
DATA_SOURCES = [
  { section: '原料营养成分', module: 'ingredient_db.pl', source: '中国饲料成分及营养价值表 2024(第35版)', date: '2024' },
  { section: '原料价格', module: 'ingredient_db.pl', source: PRICE_BASELINE, date: '2026-06' },
  { section: '物种营养需求', module: 'species_nutrition.pl', source: 'NRC 2011 + GB/T 水产饲料标准', date: '2011/2024' },
  { section: '品类约束规则', module: 'category_rules.pl', source: '生产规范与行业实践', date: '—' },
  { section: '矿物质需求', module: 'species_nutrition.pl (mineral)', source: 'NRC 2011', date: '2011' },
  { section: '氨基酸需求', module: 'ingredient_amino.pl', source: 'NRC 2011 + 行业推荐', date: '2011' },
  { section: 'LP 配方求解', module: 'formulation_lp_engine.pl + recipe_planner.pl', source: 'scryer-prolog simplex 引擎', date: '实时计算' },
  { section: '矿物质平衡校验', module: 'mineral_balance.pl', source: 'Prolog 规则引擎', date: '实时计算' },
  { section: '氨基酸平衡校验', module: 'eaa_balance.pl', source: 'Prolog 规则引擎', date: '实时计算' },
  { section: '绩效风险评估', module: 'performance_risk_rules.pl', source: 'Prolog 规则引擎', date: '实时计算' },
  { section: '微量添加剂', module: 'shrimp_additives.json', source: '行业标准推荐量', date: '2026' },
].freeze

# ═══════════════════════════════════════════════════════════════
# Unified Prolog Runner (v3.0 — 单次调用替代 3 次)
# ═══════════════════════════════════════════════════════════════

def run_unified_prolog
  Dir.mktmpdir('bridge-unified-') do |dir|
    pl_file = File.join(dir, 'unified.pl')
    File.write(pl_file, <<~PL)
      :- initialization(main).

      main :-
          consult_all('#{RULES_DIR}/', [
              ingredient_db, species_nutrition, category_rules,
              sop_engine,
              formulation_lp_engine, recipe_planner,
              mineral_balance, eaa_balance, ingredient_amino,
              performance_risk_rules,
              sop_orchestrator
          ]),
          run_unified_pipeline(#{SPECIES_KEY}, #{STAGE}),
          halt.

      consult_all(_, []).
      consult_all(Base, [Name|Rest]) :-
          atom_concat(Base, Name, P0),
          atom_concat(P0, '.pl', Path),
          consult(Path),
          consult_all(Base, Rest).
    PL

    stdout, stderr, status = Open3.capture3('scryer-prolog', pl_file)
    raw = stdout + stderr
    # Filter scryer warnings
    raw.lines.reject { |l| l.start_with?('% Warning') || l.start_with?('% ') }.join
  end
end

# ═══════════════════════════════════════════════════════════════
# Parsers (unchanged from v2.0 — compatible with unified output)
# ═══════════════════════════════════════════════════════════════

def parse_plans(raw)
  plans = []
  current = nil
  items = []

  raw.each_line do |line|
    line = line.strip
    next if line.empty?

    case line
    when 'PLAN_START'       then current = {}; items = []
    when 'PLAN_END'         then current['items'] = items; plans << current; current = nil
    when /^strategy=(.+)/   then current['strategy'] = $1.strip
    when /^status=(.+)/     then current['status'] = $1.strip
    when /^cost=(.+)/       then current['cost'] = $1.strip.to_f
    when /^ap_min=(.+)/     then current['ap_min'] = $1.strip.to_i
    when /^fm_min=(.+)/     then current['fm_min'] = $1.strip.to_i
    when /^risk=(.+)/       then current['risk'] = $1.strip
    when /^cw=(.+)/         then current['cw'] = $1.strip.to_f
    when /^item (\S+) (\S+) (\S+)/
      items << { 'id' => $1, 'pct' => $2.to_f, 'item_cost' => $3.to_f }
    end
  end
  plans
end

def parse_meta(raw)
  meta = { nutrition: {}, constraints: [], ingredients: {} }
  in_ingredients = false

  raw.each_line do |line|
    line = line.strip
    next if line.empty? || line.start_with?('META_')  # Skip META_START/META_END headers

    case line
    when 'INGREDIENTS_START' then in_ingredients = true; next
    when 'INGREDIENTS_END'   then in_ingredients = false; next
    end

    if in_ingredients
      if line =~ /^ing (\S+)\|([^|]+)\|([^|]+)\|([\d.]+)\|([\d.]+)\|([\d.]+)\|([\d.]+)\|([\d.]+)\|([\d.]+)\|([\d.]+)$/
        meta[:ingredients][$1] = {
          cn: $2, category: $3,
          pro: $4.to_f, fat: $5.to_f, fib: $6.to_f, ash: $7.to_f,
          price: $8.to_f, max_usage: $9.to_f, min_usage: $10.to_f
        }
      end
    elsif line =~ /^(?:NUTRITION|nutrition) ([\d.]+) ([\d.]+) ([\d.]+) ([\d.]+)/
      meta[:nutrition] = { 'protein' => $1.to_f, 'fat' => $2.to_f, 'fiber' => $3.to_f, 'ash' => $4.to_f }
    elsif line =~ /^(?:CONSTRAINT|cat) (\S+) (min|max) ([\d.]+)/
      cat_key = $1
      op = $2
      val = $3.to_f
      cn_desc = CATEGORY_CN[cat_key] || cat_key
      meta[:constraints] << {
        'type' => cat_key, 'limit' => val, 'op' => op,
        'desc' => "#{cn_desc}#{op == 'min' ? '下限' : '上限'}"
      }
    end
  end
  meta
end

def parse_validation(raw)
  validations = {}
  current_strat = nil
  current_val = nil

  raw.each_line do |line|
    line = line.strip
    next if line.empty?

    case line
    when /^VAL_START (\w+)/
      current_strat = $1
      current_val = {
        'actual_nutrition' => {},
        'mineral' => { 'checks' => [], 'confidence' => 0 },
        'amino' => { 'checks' => [], 'confidence' => 0 },
        'risk' => { 'checks' => [], 'confidence' => 0 }
      }
    when 'VAL_END'
      validations[current_strat] = current_val if current_strat
      current_strat = nil; current_val = nil
    when /^actual_nutrition ([\d.]+) ([\d.]+) ([\d.]+) ([\d.]+)/
      current_val['actual_nutrition'] = {
        'protein' => $1.to_f, 'fat' => $2.to_f, 'fiber' => $3.to_f, 'ash' => $4.to_f
      }
    when /^mineral_confidence ([\d.]+)/
      current_val['mineral']['confidence'] = $1.to_f
    when /^mineral_check ca_p_ratio (\S+) ([\d.]+) ([\d.]+)-([\d.]+)/
      current_val['mineral']['checks'] << {
        'name' => 'ca_p_ratio', 'status' => $1, 'actual' => $2.to_f, 'min' => $3.to_f, 'max' => $4.to_f
      }
    when /^mineral_check (\S+) (\S+) ([\d.]+) ([\d.]+)/
      current_val['mineral']['checks'] << {
        'name' => $1, 'status' => $2, 'actual' => $3.to_f, 'required' => $4.to_f
      }
    when /^amino_confidence ([\d.]+)/
      current_val['amino']['confidence'] = $1.to_f
    when /^amino_check (\S+) (\S+) ([\d.]+) ([\d.]+)/
      current_val['amino']['checks'] << {
        'name' => $1, 'status' => $2, 'actual' => $3.to_f, 'required' => $4.to_f
      }
    when /^risk_confidence ([\d.]+)/
      current_val['risk']['confidence'] = $1.to_f
    when /^risk_check (\S+) (\S+) (.+)$/
      current_val['risk']['checks'] << {
        'name' => $1, 'level' => $2, 'value' => $3.strip
      }
    end
  end
  validations
end

# ═══════════════════════════════════════════════════════════════
# Additives (shrimp-specific micronutrients) — unchanged
# ═══════════════════════════════════════════════════════════════

def load_additives
  if File.exist?(ADDITIVES_FILE)
    JSON.parse(File.read(ADDITIVES_FILE))
  else
    {}
  end
end

def inject_additives(items, species_key, stage, ingredient_meta)
  additives_config = load_additives
  species_additives = additives_config.dig(species_key, stage) || []
  return items if species_additives.empty?

  additive_items = species_additives.map do |add|
    ing = ingredient_meta[add['id']] || {}
    {
      'id'       => add['id'],
      'name'     => ing[:cn] || add['id'],
      'pct'      => add['pct'],
      'category' => '添加剂',
      'reason'   => add['reason'] || '',
      'price'    => ing[:price] || 0
    }
  end

  total_add = additive_items.sum { |a| a['pct'] }
  bulk_items = items.reject { |i| additive_items.any? { |a| a['id'] == i['id'] } }
  bulk_pct = bulk_items.sum { |i| i['pct'] }

  if bulk_pct > 0 && total_add > 0
    scale = (bulk_pct - total_add) / bulk_pct
    bulk_items.each { |i| i['pct'] = (i['pct'] * scale).round(2) }
  end

  bulk_items + additive_items
end

# ═══════════════════════════════════════════════════════════════
# Assemble final JSON — unchanged
# ═══════════════════════════════════════════════════════════════

def calculate_closure(items)
  items.sum { |i| i['pct'] }.round(1)
end

def assemble_json(plans, meta, validations, ingredient_meta)
  species_cn = SPECIES_META.dig(SPECIES_KEY, :cn) || SPECIES_KEY
  stage_cn = SPECIES_META.dig(SPECIES_KEY, :stage_cn, STAGE) || STAGE
  generated_at = Time.now.strftime('%Y-%m-%d %H:%M:%S')

  plan_objects = plans.map do |p|
    strat = STRATEGY_NAMES[p['strategy']] || { id: p['strategy'][0].upcase, name: p['strategy'], desc: '' }
    raw_items = p['items'].map do |item|
      ing = ingredient_meta[item['id']] || {}
      {
        'id'       => item['id'],
        'name'     => ing[:cn] || item['id'],
        'pct'      => item['pct'],
        'category' => CATEGORY_CN[ing[:category]] || ing[:category] || '未知',
        'pro'      => ing[:pro] || 0,
        'fat'      => ing[:fat] || 0,
        'fib'      => ing[:fib] || 0,
        'ash'      => ing[:ash] || 0,
        'price'    => ing[:price] || 0
      }
    end

    items = inject_additives(raw_items, SPECIES_KEY, STAGE, ingredient_meta)
    val = validations[p['strategy']] || {}
    actual = val['actual_nutrition'] || {}

    animal_pct = items.select { |i|
      cat = ingredient_meta[i['id']]&.dig(:category)
      cat == 'animal_protein'
    }.sum { |i| i['pct'] }.round(1)

    starch_pct = items.select { |i|
      cat = ingredient_meta[i['id']]&.dig(:category)
      cat == 'energy'
    }.sum { |i| i['pct'] }.round(1)

    oil_pct = items.select { |i|
      cat = ingredient_meta[i['id']]&.dig(:category)
      cat == 'oil'
    }.sum { |i| i['pct'] }.round(1)

    additive_items = items.select { |i| i['category'] == '添加剂' }

    {
      'id'                  => strat[:id],
      'name'                => strat[:name],
      'strategy'            => strat[:desc],
      'cost'                => (p['cost'] * 100).round,
      'cost_raw'            => p['cost'],
      'protein_target'      => meta[:nutrition]['protein'],
      'fat_target'          => meta[:nutrition]['fat'],
      'fiber_target'        => meta[:nutrition]['fiber'],
      'ash_target'          => meta[:nutrition]['ash'],
      'protein_actual'      => actual['protein'] || 0,
      'fat_actual'          => actual['fat'] || 0,
      'fiber_actual'        => actual['fiber'] || 0,
      'ash_actual'          => actual['ash'] || 0,
      'animal_protein_pct'  => animal_pct,
      'starch_pct'          => starch_pct,
      'oil_pct'             => oil_pct,
      'closure'             => calculate_closure(items),
      'items'               => items,
      'additives'           => additive_items,
      'validation'          => {
        'mineral'   => val.dig('mineral') || {},
        'amino'     => val.dig('amino') || {},
        'risk'      => val.dig('risk') || {}
      }
    }
  end

  species_desc = case SPECIES_KEY
  when 'white_shrimp'
    "#{species_cn} (Litopenaeus vannamei) 是全球养殖产量最高的对虾品种。#{stage_cn}阶段体重通常在 15g 以上，对蛋白质需求较幼虾阶段有所降低，但对饲料水中稳定性和诱食性要求较高。"
  when 'japanese_eel'
    "#{species_cn} (Anguilla japonica) 是东亚地区重要的养殖鱼类。#{stage_cn}阶段对高蛋白饲料依赖性高，需重视氨基酸平衡。"
  else
    "#{species_cn} #{stage_cn}阶段饲料配方，基于 Prolog LP 求解器在营养约束下优化生成。"
  end

  {
    'meta' => {
      'species'        => species_cn,
      'stage'          => stage_cn,
      'species_key'    => SPECIES_KEY,
      'stage_key'      => STAGE,
      'generated_at'   => generated_at,
      'price_baseline' => PRICE_BASELINE,
      'version'        => 'AquaFeedFormulator v3.0',
      'engine'         => 'Prolog SOP Orchestrator (Unified Pipeline)',
      'data_sources'   => DATA_SOURCES,
      'species_desc'   => species_desc,
      'disclaimer'     => '本配方由 LP 求解器在营养约束条件下优化生成，矿物质/氨基酸/绩效风险校验已通过 Prolog 规则引擎自动执行。实际使用前建议进行小规模养殖试验验证。'
    },
    'nutrition'    => meta[:nutrition],
    'constraints'  => meta[:constraints],
    'plans'        => plan_objects
  }
end

# ═══════════════════════════════════════════════════════════════
# Main (v3.0 — unified single Prolog call)
# ═══════════════════════════════════════════════════════════════

puts '=== AquaFeedFormulator Bridge: Prolog → DOCX v3.0 (Unified) ==='
puts "Species: #{SPECIES_KEY} | Stage: #{STAGE}"
puts

puts '[1/2] 运行统一 Prolog Pipeline (食谱+营养+约束+校验)...'
raw = run_unified_prolog

# Parse all sections from single output
plans = parse_plans(raw)
puts "  方案: #{plans.length} 套"

meta = parse_meta(raw)
ing_count = meta[:ingredients]&.length || 0
puts "  营养: 蛋白≥#{meta[:nutrition]['protein']}% 脂肪≥#{meta[:nutrition]['fat']}%"
puts "  品类约束: #{meta[:constraints].length} 项"
puts "  原料库: #{ing_count} 种"

validations = parse_validation(raw)
puts "  SOP校验: #{validations.keys.size} 套方案"
validations.each do |strat, val|
  actual = val['actual_nutrition']
  mineral_ok = val.dig('mineral', 'checks')&.all? { |c| c['status'] == 'passed' }
  amino_ok = val.dig('amino', 'checks')&.all? { |c| c['status'] == 'met' }
  mineral_str = mineral_ok.nil? ? '⊘' : (mineral_ok ? '✅' : '❌')
  amino_str = amino_ok.nil? ? '⊘' : (amino_ok ? '✅' : '❌')
  conf = ((val.dig('risk', 'confidence') || 0) * 100).round
  puts "    #{strat}: 蛋白=#{actual['protein']}% 矿物=#{mineral_str} 氨基酸=#{amino_str} 置信度=#{conf}%"
end

puts
puts '[2/2] 生成 recipe_data.json + DOCX 报告...'
json_data = assemble_json(plans, meta, validations, meta[:ingredients])
FileUtils.mkdir_p(File.dirname(OUTPUT_JSON))
File.write(OUTPUT_JSON, JSON.pretty_generate(json_data))
puts "  ✅ #{OUTPUT_JSON}"

result = system('python3', File.join(PROJECT_DIR, 'generate_report.py'), OUTPUT_JSON)
if result
  docx_file = Dir.glob(File.join(DOCX_OUTPUT, '*饲料配方报告*.docx')).max_by { |f| File.mtime(f) }
  puts "  ✅ DOCX 报告已生成: #{docx_file || '~/Desktop/'}"
else
  puts '  ❌ DOCX 生成失败'
end
