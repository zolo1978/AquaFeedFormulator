#!/usr/bin/env ruby
# bridge_prolog_docx.rb — Prolog 求解 → 验证 → JSON → DOCX
# 用法: ruby bridge_prolog_docx.rb <species_key> [stage]
#
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
# Step 1: Prolog recipe_planner (3 strategies)
# ═══════════════════════════════════════════════════════════════

def run_prolog_plans
  prolog_src = <<~PL
    :- initialization(main).
    base('#{RULES_DIR}/').

    main :-
        base(B),
        consult_all(B, [
            ingredient_db, species_nutrition, category_rules,
            ingredient_amino, shrimp_adult_recipes,
            formulation_lp_engine, recipe_planner
        ]),
        generate_recipe_plans(#{SPECIES_KEY}, #{STAGE}, Out),
        Out = output(Plans, _, _, _, _),
        write_plans(Plans),
        halt.

    consult_all(_, []).
    consult_all(Base, [Name|Rest]) :-
        atom_concat(Base, Name, P0),
        atom_concat(P0, '.pl', Path),
        consult(Path),
        consult_all(Base, Rest).

    write_plans([]).
    write_plans([plan(Strat, Status, Items, Cost, Profile)|Rest]) :-
        write('PLAN_START'), nl,
        write('strategy='), write(Strat), nl,
        write('status='), write(Status), nl,
        write('cost='), write(Cost), nl,
        Profile = profile(ApMin, FmMin, Risk, CW),
        write('ap_min='), write(ApMin), nl,
        write('fm_min='), write(FmMin), nl,
        write('risk='), write(Risk), nl,
        write('cw='), write(CW), nl,
        write_items(Items),
        write('PLAN_END'), nl,
        write_plans(Rest).

    write_items([]).
    write_items([item(Id, Pct, Cost)|Rest]) :-
        write('item '), write(Id), write(' '), write(Pct), write(' '), write(Cost), nl,
        write_items(Rest).
  PL

  Dir.mktmpdir('bridge-') do |dir|
    pl_file = File.join(dir, 'query.pl')
    File.write(pl_file, prolog_src)
    stdout, stderr, status = Open3.capture3('scryer-prolog', pl_file)
    (stdout + stderr).lines.reject { |l| l.start_with?('% Warning') }.join
  end
end

# ═══════════════════════════════════════════════════════════════
# Step 2: Prolog meta (nutrition + constraints + ingredient DB)
# ═══════════════════════════════════════════════════════════════

def run_prolog_meta
  prolog_src = <<~PL
    :- initialization(main).
    base('#{RULES_DIR}/').

    main :-
        base(B),
        atom_concat(B, 'ingredient_db.pl', P1), consult(P1),
        atom_concat(B, 'species_nutrition.pl', P2), consult(P2),
        atom_concat(B, 'category_rules.pl', P3), consult(P3),

        species_nutrition(#{SPECIES_KEY}, #{STAGE}, Pro, Fat, Fib, Ash),
        write('nutrition '), write(Pro), write(' '), write(Fat), write(' '), write(Fib), write(' '), write(Ash), nl,

        species_category_constraints(#{SPECIES_KEY}, #{STAGE}, Cats),
        write_cats(Cats),

        findall(Id-Cn-Cat-Pro2-Fat2-Fib2-Ash2-Price-Max-Min,
            ingredient(Id, Cn, Cat, Pro2, Fat2, Fib2, Ash2, _, Price, Max, Min),
            All),
        write('INGREDIENTS_START'), nl,
        write_ingredients(All),
        write('INGREDIENTS_END'), nl,
        halt.

    write_ingredients([]).
    write_ingredients([Id-Cn-Cat-Pro2-Fat2-Fib2-Ash2-Price-Max-Min|Rest]) :-
        write('ing '), write(Id), write('|'), write(Cn), write('|'), write(Cat),
        write('|'), write(Pro2), write('|'), write(Fat2), write('|'), write(Fib2),
        write('|'), write(Ash2), write('|'), write(Price), write('|'), write(Max), write('|'), write(Min), nl,
        write_ingredients(Rest).

    write_cats([]).
    write_cats([Cat-LT-Val|Rest]) :-
        write('cat '), write(Cat), write(' '), write(LT), write(' '), write(Val), nl,
        write_cats(Rest).
  PL

  Dir.mktmpdir('bridge-meta-') do |dir|
    pl_file = File.join(dir, 'meta.pl')
    File.write(pl_file, prolog_src)
    stdout, stderr, status = Open3.capture3('scryer-prolog', pl_file)
    (stdout + stderr).lines.reject { |l| l.start_with?('% Warning') }.join
  end
end

# ═══════════════════════════════════════════════════════════════
# Step 3: Prolog validation (nutrients + mineral + amino + risk)
# ═══════════════════════════════════════════════════════════════

def run_prolog_validation
  prolog_src = <<~PL
    :- initialization(main).
    base('#{RULES_DIR}/').

    main :-
        base(B),
        consult_all(B, [
            ingredient_db, species_nutrition, category_rules,
            ingredient_amino, mineral_balance, eaa_balance,
            performance_risk_rules,
            formulation_lp_engine, recipe_planner
        ]),
        generate_recipe_plans(#{SPECIES_KEY}, #{STAGE}, Out),
        Out = output(Plans, _, _, _, _),
        validate_plans(Plans),
        halt.

    consult_all(_, []).
    consult_all(Base, [Name|Rest]) :-
        atom_concat(Base, Name, P0),
        atom_concat(P0, '.pl', Path),
        consult(Path),
        consult_all(Base, Rest).

    % ═══ Plan validation ═══

    validate_plans([]).
    validate_plans([plan(Strat, _, ItemsItem3, _, _)|Rest]) :-
        write('VAL_START '), write(Strat), nl,

        % Convert item(Id,Pct,Cost) → Id-Pct-Cost for validators
        items_to_pairs(ItemsItem3, Items),

        % --- Actual nutrition ---
        calc_nutrition(ItemsItem3, Pro, Fat, Fib, Ash),
        ProR is round(Pro * 10) / 10,
        FatR is round(Fat * 10) / 10,
        FibR is round(Fib * 10) / 10,
        AshR is round(Ash * 10) / 10,
        write('  actual_nutrition '), write(ProR), write(' '), write(FatR),
        write(' '), write(FibR), write(' '), write(AshR), nl,

        % --- Mineral check ---
        ( catch(once(mineral_check(#{SPECIES_KEY}, #{STAGE}, Items, MOut)),
                Err, (write('  mineral_error '), write(Err), nl,
                      MOut = output(data([]),[err(error,_)],[],0.0,[]))) ->
            true
        ;   MOut = output(data([]),[err(error,_)],[],0.0,[])
        ),
        write_mineral_out(MOut),

        % --- Amino acid check ---
        ( catch(once(eaa_check(#{SPECIES_KEY}, #{STAGE}, Items, AOut)),
                _, (AOut = output(data([]),[err(error,_)],[],0.0,[]))) ->
            true ; AOut = output(data([]),[err(error,_)],[],0.0,[])
        ),
        write_amino_out(AOut),

        % --- Performance risk ---
        ( catch(performance_risk_check(#{SPECIES_KEY}, #{STAGE}, Items, ROut),
                Err, (write('  * risk_EXCEPTION '), write(Err), nl,
                      ROut = output(data([]),[err(error,_)],[],0.0,[]))) ->
            true ; ROut = output(data([]),[err(error,_)],[],0.0,[])
        ),
        write_risk_out(ROut),

        write('VAL_END'), nl,
        validate_plans(Rest).

    % --- Format conversion: item/3 → -/3 ---
    items_to_pairs([], []).
    items_to_pairs([item(Id, Pct, Cost)|T], [Id-Pct-Cost|RT]) :-
        items_to_pairs(T, RT).

    % --- Nutrition calculator ---
    calc_nutrition([], 0, 0, 0, 0).
    calc_nutrition([item(_, 0, _)|T], P, F, B, A) :-
        !, calc_nutrition(T, P, F, B, A).
    calc_nutrition([item(Id, Pct, _)|T], Pro, Fat, Fib, Ash) :-
        ingredient(Id, _, _, IngPro, IngFat, IngFib, IngAsh, _, _, _, _),
        calc_nutrition(T, PR, FR, BR, AR),
        Pro  is PR  + Pct * IngPro / 100,
        Fat  is FR  + Pct * IngFat / 100,
        Fib  is BR  + Pct * IngFib / 100,
        Ash  is AR  + Pct * IngAsh / 100.

    % --- Mineral output (handles variable-arity check terms) ---
    write_mineral_out(output(data(Checks), _Ws, _Es, Conf, _)) :-
        write('  mineral_confidence '), write(Conf), nl,
        write_checks_mineral(Checks).

    write_checks_mineral([]).
    write_checks_mineral([C|T]) :-
        C =.. [check|Args],
        write_mineral_check(Args),
        write_checks_mineral(T).

    % available_phosphorus: check(Name, Status, Actual, Required) — 4 args
    write_mineral_check([Name, Status, Actual, Required]) :-
        write('  mineral_check '), write(Name), write(' '),
        write(Status), write(' '), write(Actual), write(' '), write(Required), nl.
    % ca_p_ratio passed: check(Name, Status, Ratio, Min, Max) — 5 args
    write_mineral_check([ca_p_ratio, Status, Ratio, Min, Max]) :-
        write('  mineral_check ca_p_ratio '), write(Status),
        write(' '), write(Ratio), write(' '), write(Min), write('-'), write(Max), nl.
    % ca_p_ratio failed: check(Name, Status, Ratio, Min, Max, Dir) — 6 args
    write_mineral_check([ca_p_ratio, Status, Ratio, Min, Max, _Dir]) :-
        write('  mineral_check ca_p_ratio '), write(Status),
        write(' '), write(Ratio), write(' '), write(Min), write('-'), write(Max), nl.

    % --- Amino acid output ---
    write_amino_out(output(data(Checks), _Ws, _Es, Conf, _)) :-
        write('  amino_confidence '), write(Conf), nl,
        write_checks_amino(Checks).

    write_checks_amino([]).
    write_checks_amino([C|T]) :-
        C =.. [check, Name, Status, Actual, Required|_],
        write('  amino_check '), write(Name), write(' '),
        write(Status), write(' '), write(Actual), write(' '), write(Required), nl,
        write_checks_amino(T).

    % --- Performance risk output ---
    write_risk_out(output(data(Checks), _Ws, _Es, Conf, _)) :-
        write('  risk_confidence '), write(Conf), nl,
        write_checks_risk(Checks).

    write_checks_risk([]).
    write_checks_risk([C|T]) :-
        C =.. [risk, Name, Level, Value],
        write('  risk_check '), write(Name), write(' '),
        write(Level), write(' '), write(Value), nl,
        write_checks_risk(T).
  PL

  Dir.mktmpdir('bridge-val-') do |dir|
    pl_file = File.join(dir, 'validate.pl')
    File.write(pl_file, prolog_src)
    stdout, stderr, status = Open3.capture3('scryer-prolog', pl_file)
    (stdout + stderr).lines.reject { |l| l.start_with?('% Warning') }.join
  end
end

# ═══════════════════════════════════════════════════════════════
# Parsing
# ═══════════════════════════════════════════════════════════════

def parse_ingredient_db
  db_file = File.join(RULES_DIR, 'ingredient_db.pl')
  ingredients = {}
  File.readlines(db_file).each do |line|
    if line =~ /^ingredient\((\w+),\s*'([^']+)',\s*(\w+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*[\d.]*,\s*([\d.]+),\s*([\d.]+),\s*([\d.]+)\)/
      ingredients[$1] = {
        cn: $2, category: $3,
        pro: $4.to_f, fat: $5.to_f, fib: $6.to_f, ash: $7.to_f,
        price: $8.to_f, max_usage: $9.to_f, min_usage: $10.to_f
      }
    end
  end
  ingredients
end

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
    next if line.empty?

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
    elsif line =~ /^nutrition (\S+) (\S+) (\S+) (\S+)/
      meta[:nutrition] = { 'protein' => $1.to_f, 'fat' => $2.to_f, 'fiber' => $3.to_f, 'ash' => $4.to_f }
    elsif line =~ /^cat (\S+) (min|max) ([\d.]+)/
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
    when /^\s+actual_nutrition ([\d.]+) ([\d.]+) ([\d.]+) ([\d.]+)/
      current_val['actual_nutrition'] = {
        'protein' => $1.to_f, 'fat' => $2.to_f, 'fiber' => $3.to_f, 'ash' => $4.to_f
      }
    when /^\s+mineral_confidence ([\d.]+)/
      current_val['mineral']['confidence'] = $1.to_f
    when /^\s+mineral_check (\S+) (\S+) ([\d.]+) ([\d.]+)/
      current_val['mineral']['checks'] << {
        'name' => $1, 'status' => $2, 'actual' => $3.to_f, 'required' => $4.to_f
      }
    when /^\s+amino_confidence ([\d.]+)/
      current_val['amino']['confidence'] = $1.to_f
    when /^\s+amino_check (\S+) (\S+) ([\d.]+) ([\d.]+)/
      current_val['amino']['checks'] << {
        'name' => $1, 'status' => $2, 'actual' => $3.to_f, 'required' => $4.to_f
      }
    when /^\s+risk_confidence ([\d.]+)/
      current_val['risk']['confidence'] = $1.to_f
    when /^\s+risk_check (\S+) (\S+) (.+)$/
      current_val['risk']['checks'] << {
        'name' => $1, 'level' => $2, 'value' => $3.strip
      }
    end
  end
  validations
end

# ═══════════════════════════════════════════════════════════════
# Additives (shrimp-specific micronutrients)
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

  # Collect additive items to append
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

  # Calculate total additive pct and deduct from bulk ingredients proportionally
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
# Assemble final JSON
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

    # Inject micronutrient additives
    items = inject_additives(raw_items, SPECIES_KEY, STAGE, ingredient_meta)

    # Validation data
    val = validations[p['strategy']] || {}
    actual = val['actual_nutrition'] || {}

    # Category aggregations
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
      # Target nutrition (from species requirement)
      'protein_target'      => meta[:nutrition]['protein'],
      'fat_target'          => meta[:nutrition]['fat'],
      'fiber_target'        => meta[:nutrition]['fiber'],
      'ash_target'          => meta[:nutrition]['ash'],
      # Actual nutrition (calculated from items)
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

  # Build species description
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
      'species'       => species_cn,
      'stage'         => stage_cn,
      'species_key'   => SPECIES_KEY,
      'stage_key'     => STAGE,
      'generated_at'  => generated_at,
      'price_baseline' => PRICE_BASELINE,
      'version'       => 'AquaFeedFormulator v2.1',
      'engine'        => 'Prolog LP solver + SOP Gatekeeper',
      'data_sources'  => DATA_SOURCES,
      'species_desc'  => species_desc,
      'disclaimer'    => '本配方由 LP 求解器在营养约束条件下优化生成，矿物质/氨基酸/绩效风险校验已通过 Prolog 规则引擎自动执行。实际使用前建议进行小规模养殖试验验证。'
    },
    'nutrition'    => meta[:nutrition],
    'constraints'  => meta[:constraints],
    'plans'        => plan_objects
  }
end

# ═══════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════

puts '=== AquaFeedFormulator Bridge: Prolog → DOCX v2.0 ==='
puts "Species: #{SPECIES_KEY} | Stage: #{STAGE}"
puts

puts '[1/4] 运行 Prolog recipe_planner (三策略)...'
plans_raw = run_prolog_plans
plans = parse_plans(plans_raw)
puts "  获取 #{plans.length} 套方案"

puts '[2/4] 查询营养需求 + 原料数据库...'
meta_raw = run_prolog_meta
meta = parse_meta(meta_raw)
# DEBUG
ing_count = meta[:ingredients]&.length || 0
puts "  DEBUG: raw meta has #{meta_raw.lines.count} lines, ingredients parsed: #{ing_count}"
if ing_count < 10
  puts "  DEBUG raw (first 500 chars):"
  puts meta_raw[0..500]
end
puts "  营养: 蛋白≥#{meta[:nutrition]['protein']}% 脂肪≥#{meta[:nutrition]['fat']}%"
puts "  品类约束: #{meta[:constraints].length} 项"
puts "  原料库: #{ing_count} 种"

puts '[3/4] 运行 Prolog SOP 校验 (矿物质/氨基酸/绩效风险)...'
val_raw = run_prolog_validation
puts "  [DEBUG] val_raw (#{val_raw.lines.count} lines):"
val_raw.each_line { |l| puts "    > #{l.chomp}" }
puts "-" * 40
validations = parse_validation(val_raw)
puts "  parsed #{validations.keys.size} validation entries"
validations.each do |strat, val|
  actual = val['actual_nutrition']
  mineral_ok = val.dig('mineral', 'checks')&.all? { |c| c['status'] == 'passed' }
  amino_ok = val.dig('amino', 'checks')&.all? { |c| c['status'] == 'passed' }
  mineral_ok_str = mineral_ok.nil? ? '⊘' : (mineral_ok ? '✅' : '❌')
  amino_ok_str = amino_ok.nil? ? '⊘' : (amino_ok ? '✅' : '❌')
  puts "  #{strat}: 蛋白=#{actual['protein']}% 脂肪=#{actual['fat']}% 矿物=#{mineral_ok_str} 氨基酸=#{amino_ok_str} 置信度=#{(val.dig('risk', 'confidence') || 0 * 100).round}%"
end

puts '[4/4] 生成 recipe_data.json...'
json_data = assemble_json(plans, meta, validations, meta[:ingredients])
FileUtils.mkdir_p(File.dirname(OUTPUT_JSON))
File.write(OUTPUT_JSON, JSON.pretty_generate(json_data))
puts "  ✅ #{OUTPUT_JSON}"

puts
puts '运行 DOCX 报告生成...'
result = system('python3', File.join(PROJECT_DIR, 'generate_report.py'), OUTPUT_JSON)
if result
  docx_file = Dir.glob(File.join(DOCX_OUTPUT, '*饲料配方报告*.docx')).max_by { |f| File.mtime(f) }
  puts "  ✅ DOCX 报告已生成: #{docx_file || '~/Desktop/'}"
else
  puts '  ❌ DOCX 生成失败'
end
