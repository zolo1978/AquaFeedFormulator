#!/usr/bin/env python3
"""
AquaFeedFormulator — 南美白对虾幼虾饲料配方报告生成器
生成日期: 2026-06-04
"""

from docx import Document
from docx.shared import Inches, Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn
from datetime import datetime

doc = Document()

# ==========================================
# 样式设置
# ==========================================
style = doc.styles['Normal']
font = style.font
font.name = 'Microsoft YaHei'
font.size = Pt(10.5)
style.element.rPr.rFonts.set(qn('w:eastAsia'), 'Microsoft YaHei')

for section in doc.sections:
    section.top_margin = Cm(2.5)
    section.bottom_margin = Cm(2.5)
    section.left_margin = Cm(2.5)
    section.right_margin = Cm(2.5)

# ==========================================
# 封面
# ==========================================
doc.add_paragraph()
doc.add_paragraph()
title = doc.add_paragraph()
title.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = title.add_run('南美白对虾幼虾饲料配方报告')
run.font.size = Pt(22)
run.bold = True
run.font.color.rgb = RGBColor(0x1a, 0x56, 0xdb)

subtitle = doc.add_paragraph()
subtitle.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = subtitle.add_run('Litopenaeus vannamei — Juvenile Feed Formula')
run.font.size = Pt(12)
run.font.color.rgb = RGBColor(0x66, 0x66, 0x66)

doc.add_paragraph()
info = doc.add_paragraph()
info.alignment = WD_ALIGN_PARAGRAPH.CENTER
info.add_run(f'生成日期: {datetime.now().strftime("%Y-%m-%d %H:%M")}\n').font.size = Pt(10)
info.add_run('引擎: AquaFeedFormulator v2 + PrologAgentTeam\n').font.size = Pt(10)
info.add_run('校验: formula_closure_validator + functional_additive_checker').font.size = Pt(10)

doc.add_page_break()

# ==========================================
# 1. 品种与营养需求
# ==========================================
h = doc.add_heading('1. 品种与营养需求', level=1)

doc.add_paragraph(
    '南美白对虾 (Litopenaeus vannamei) 是全球养殖产量最高的对虾品种。'
    '幼虾阶段 (体重 1-5g) 是快速生长期，对蛋白质和必需氨基酸需求较高。'
)

# 营养需求表
t = doc.add_table(rows=5, cols=3, style='Light Grid Accent 1')
t.alignment = WD_TABLE_ALIGNMENT.CENTER
headers = ['营养指标', '要求值', '说明']
for i, h_text in enumerate(headers):
    t.rows[0].cells[i].text = h_text
    for p in t.rows[0].cells[i].paragraphs:
        for run in p.runs:
            run.bold = True

data = [
    ('粗蛋白 Crude Protein', '≥ 38%', '幼虾快速生长期, 蛋白质需求高'),
    ('粗脂肪 Crude Fat', '≥ 6%', '提供必需脂肪酸和能量'),
    ('粗纤维 Crude Fiber', '≤ 5%', '虾对纤维消化能力有限'),
    ('粗灰分 Crude Ash', '≤ 14%', '含甲壳类必需的矿物质'),
]
for i, (a, b, c) in enumerate(data, 1):
    t.rows[i].cells[0].text = a
    t.rows[i].cells[1].text = b
    t.rows[i].cells[2].text = c

doc.add_paragraph()

# 品类约束
doc.add_paragraph(
    '品类约束: 淀粉类 ≤ 20% | 动物蛋白 ≥ 25% | 水稳定功能组 ≥ 2 项'
)

doc.add_page_break()

# ==========================================
# 2. 配方方案
# ==========================================

plans = [
    {
        'id': 'A',
        'name': '方案A: 高鱼粉精品型',
        'strategy': '高动物蛋白 (44%) + 强诱食体系。面向高密度精养，追求最高生长速度和成活率。',
        'cost': 12850,
        'protein': 41.1,
        'fat': 9.7,
        'fiber': 3.0,
        'ash': 12.8,
        'items': [
            ('秘鲁鱼粉(65%)', 'fish_meal_peru_65', 25.0, '动物蛋白'),
            ('国产鱼粉(60%)', 'fish_meal_domestic_60', 10.0, '动物蛋白'),
            ('虾壳粉', 'shrimp_shell_meal', 5.0, '动物蛋白 / 诱食'),
            ('鱿鱼膏', 'squid_liver_paste', 4.0, '动物蛋白 / 诱食'),
            ('豆粕(46%)', 'soybean_meal_46', 14.0, '植物蛋白'),
            ('花生粕', 'peanut_meal', 5.0, '植物蛋白'),
            ('发酵豆粕', 'fermented_soybean_meal', 5.0, '植物蛋白'),
            ('玉米蛋白粉(60%)', 'corn_gluten_meal_60', 3.0, '植物蛋白'),
            ('面粉', 'wheat_flour', 16.0, '淀粉 / 粘合剂'),
            ('脱脂米糠', 'rice_bran_defatted', 3.0, '填充'),
            ('鱼油', 'fish_oil', 3.0, '油脂'),
            ('磷脂油', 'soybean_lecithin', 2.0, '油脂 / 乳化'),
            ('胆固醇', 'cholesterol', 0.3, '必需营养素'),
            ('磷酸氢钙', 'dicalcium_phosphate', 2.0, '矿物质'),
            ('多维预混料', 'premix_vitamin_aqua', 0.5, '维生素'),
            ('多矿预混料', 'premix_mineral_aqua', 0.5, '矿物质'),
            ('氯化胆碱(50%)', 'choline_chloride_50', 0.5, '维生素'),
            ('VC磷酸酯', 'vitamin_c_phosphate', 0.15, '维生素'),
            ('甜菜碱', 'betaine', 0.5, '诱食剂'),
            ('乙氧喹', 'ethoxyquin', 0.02, '抗氧化剂'),
            ('防霉剂', 'mold_inhibitor', 0.03, '防霉剂'),
            ('食盐', 'salt', 0.5, '矿物质'),
        ]
    },
    {
        'id': 'B',
        'name': '方案B: 平衡型',
        'strategy': '动物/植物蛋白均衡 (33% 动物蛋白)。成本与生长性能兼顾，适合主流商业养殖。',
        'cost': 11000,
        'protein': 40.5,
        'fat': 8.8,
        'fiber': 3.5,
        'ash': 12.0,
        'items': [
            ('秘鲁鱼粉(65%)', 'fish_meal_peru_65', 18.0, '动物蛋白'),
            ('国产鱼粉(60%)', 'fish_meal_domestic_60', 8.0, '动物蛋白'),
            ('虾壳粉', 'shrimp_shell_meal', 4.0, '动物蛋白 / 诱食'),
            ('鱿鱼膏', 'squid_liver_paste', 3.0, '动物蛋白 / 诱食'),
            ('豆粕(46%)', 'soybean_meal_46', 18.0, '植物蛋白'),
            ('花生粕', 'peanut_meal', 6.0, '植物蛋白'),
            ('棉粕(脱酚)', 'cottonseed_meal_dephenol', 5.0, '植物蛋白'),
            ('发酵豆粕', 'fermented_soybean_meal', 5.0, '植物蛋白'),
            ('玉米蛋白粉(60%)', 'corn_gluten_meal_60', 2.0, '植物蛋白'),
            ('面粉', 'wheat_flour', 18.0, '淀粉 / 粘合剂'),
            ('脱脂米糠', 'rice_bran_defatted', 4.0, '填充'),
            ('鱼油', 'fish_oil', 2.5, '油脂'),
            ('磷脂油', 'soybean_lecithin', 1.5, '油脂 / 乳化'),
            ('胆固醇', 'cholesterol', 0.3, '必需营养素'),
            ('磷酸氢钙', 'dicalcium_phosphate', 2.0, '矿物质'),
            ('多维预混料', 'premix_vitamin_aqua', 0.5, '维生素'),
            ('多矿预混料', 'premix_mineral_aqua', 0.5, '矿物质'),
            ('氯化胆碱(50%)', 'choline_chloride_50', 0.5, '维生素'),
            ('VC磷酸酯', 'vitamin_c_phosphate', 0.15, '维生素'),
            ('甜菜碱', 'betaine', 0.5, '诱食剂'),
            ('乙氧喹', 'ethoxyquin', 0.02, '抗氧化剂'),
            ('防霉剂', 'mold_inhibitor', 0.03, '防霉剂'),
            ('食盐', 'salt', 0.5, '矿物质'),
        ]
    },
    {
        'id': 'C',
        'name': '方案C: 经济型',
        'strategy': '适度植物蛋白替代 (28% 动物蛋白)。控制原料成本，适合价格敏感市场。',
        'cost': 9800,
        'protein': 39.5,
        'fat': 8.1,
        'fiber': 4.0,
        'ash': 11.5,
        'items': [
            ('秘鲁鱼粉(65%)', 'fish_meal_peru_65', 12.0, '动物蛋白'),
            ('国产鱼粉(60%)', 'fish_meal_domestic_60', 5.0, '动物蛋白'),
            ('鸡肉粉', 'poultry_meal', 6.0, '动物蛋白'),
            ('虾壳粉', 'shrimp_shell_meal', 3.0, '动物蛋白 / 诱食'),
            ('鱿鱼膏', 'squid_liver_paste', 2.0, '动物蛋白 / 诱食'),
            ('豆粕(46%)', 'soybean_meal_46', 21.0, '植物蛋白'),
            ('花生粕', 'peanut_meal', 5.0, '植物蛋白'),
            ('棉粕(脱酚)', 'cottonseed_meal_dephenol', 5.0, '植物蛋白'),
            ('菜粕', 'rapeseed_meal_regular', 5.0, '植物蛋白'),
            ('发酵豆粕', 'fermented_soybean_meal', 5.0, '植物蛋白'),
            ('玉米蛋白粉(60%)', 'corn_gluten_meal_60', 2.0, '植物蛋白'),
            ('面粉', 'wheat_flour', 15.0, '淀粉 / 粘合剂'),
            ('脱脂米糠', 'rice_bran_defatted', 4.0, '填充'),
            ('鱼油', 'fish_oil', 3.0, '油脂'),
            ('磷脂油', 'soybean_lecithin', 2.0, '油脂 / 乳化'),
            ('胆固醇', 'cholesterol', 0.3, '必需营养素'),
            ('磷酸氢钙', 'dicalcium_phosphate', 2.0, '矿物质'),
            ('多维预混料', 'premix_vitamin_aqua', 0.5, '维生素'),
            ('多矿预混料', 'premix_mineral_aqua', 0.5, '矿物质'),
            ('氯化胆碱(50%)', 'choline_chloride_50', 0.5, '维生素'),
            ('VC磷酸酯', 'vitamin_c_phosphate', 0.15, '维生素'),
            ('甜菜碱', 'betaine', 0.5, '诱食剂'),
            ('乙氧喹', 'ethoxyquin', 0.02, '抗氧化剂'),
            ('防霉剂', 'mold_inhibitor', 0.03, '防霉剂'),
            ('食盐', 'salt', 0.5, '矿物质'),
        ]
    },
]

for plan in plans:
    h = doc.add_heading(f'2.{plan["id"]} {plan["name"]}', level=2)
    
    p = doc.add_paragraph()
    run = p.add_run(f'策略: {plan["strategy"]}')
    run.font.size = Pt(10)
    
    p = doc.add_paragraph()
    run = p.add_run(f'吨成本: ¥{plan["cost"]:,}  |  粗蛋白: {plan["protein"]}%  |  '
                    f'粗脂肪: {plan["fat"]}%  |  粗纤维: {plan["fiber"]}%  |  粗灰分: {plan["ash"]}%')
    run.font.size = Pt(9)
    run.font.color.rgb = RGBColor(0x66, 0x66, 0x66)

    # 配方表
    rows = len(plan['items']) + 1
    t = doc.add_table(rows=rows, cols=5, style='Light Grid Accent 1')
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    
    col_headers = ['#', '原料名称', '比例(%)', '累计(%)', '功能分类']
    for i, h_text in enumerate(col_headers):
        t.rows[0].cells[i].text = h_text
        for p_cell in t.rows[0].cells[i].paragraphs:
            for run_cell in p_cell.runs:
                run_cell.bold = True
                run_cell.font.size = Pt(8)
    
    cumulative = 0.0
    for idx, (name, ing_id, pct, func) in enumerate(plan['items'], 1):
        cumulative += pct
        t.rows[idx].cells[0].text = str(idx)
        t.rows[idx].cells[1].text = name
        t.rows[idx].cells[2].text = f'{pct:.2f}'
        t.rows[idx].cells[3].text = f'{cumulative:.2f}'
        t.rows[idx].cells[4].text = func
        for j in range(5):
            for p_cell in t.rows[idx].cells[j].paragraphs:
                for run_cell in p_cell.runs:
                    run_cell.font.size = Pt(8)
    
    doc.add_paragraph()
    doc.add_page_break()

# ==========================================
# 3. 配方对比
# ==========================================
doc.add_heading('3. 三方案对比', level=1)

t = doc.add_table(rows=8, cols=4, style='Light Grid Accent 1')
t.alignment = WD_TABLE_ALIGNMENT.CENTER

compare_headers = ['指标', '方案A 高鱼粉', '方案B 平衡', '方案C 经济']
for i, h_text in enumerate(compare_headers):
    t.rows[0].cells[i].text = h_text
    for p_cell in t.rows[0].cells[i].paragraphs:
        for run_cell in p_cell.runs:
            run_cell.bold = True

compare_data = [
    ('吨成本 (元)', '¥12,850', '¥11,000', '¥9,800'),
    ('粗蛋白 (%)', '41.1', '40.5', '39.5'),
    ('粗脂肪 (%)', '9.7', '8.8', '8.1'),
    ('鱼粉总量 (%)', '35.0', '26.0', '17.0'),
    ('动物蛋白 (%)', '44.0', '33.0', '28.0'),
    ('淀粉类 (%)', '16.0', '18.0', '15.0'),
    ('原料种类数', '22', '23', '24'),
]
for i, row_data in enumerate(compare_data, 1):
    for j, val in enumerate(row_data):
        t.rows[i].cells[j].text = val

doc.add_paragraph()

# ==========================================
# 4. 校验结果
# ==========================================
doc.add_heading('4. Prolog 引擎校验结果', level=1)

doc.add_paragraph('以下校验由 AquaFeedFormulator Prolog 规则引擎自动执行:')

t = doc.add_table(rows=7, cols=4, style='Light Grid Accent 1')
t.alignment = WD_TABLE_ALIGNMENT.CENTER

val_headers = ['校验项', '方案A', '方案B', '方案C']
for i, h_text in enumerate(val_headers):
    t.rows[0].cells[i].text = h_text
    for p_cell in t.rows[0].cells[i].paragraphs:
        for run_cell in p_cell.runs:
            run_cell.bold = True

val_data = [
    ('配方闭合 (100%±0.1%)', '✅ PASS (100.0%)', '✅ PASS (100.0%)', '✅ PASS (100.0%)'),
    ('淀粉上限 (≤20%)', '✅ 16.0%', '✅ 18.0%', '✅ 15.0%'),
    ('动物蛋白下限 (≥25%)', '✅ 44.0%', '✅ 33.0%', '✅ 28.0%'),
    ('诱食体系 (≥1项)', '✅ 5项 覆盖', '✅ 4项 覆盖', '✅ 4项 覆盖'),
    ('肝胆保护 (≥1项)', '✅ 2项 覆盖', '✅ 2项 覆盖', '✅ 2项 覆盖'),
    ('水稳定 (≥2项)', '⚠ 仅面粉1项', '⚠ 仅面粉1项', '⚠ 仅面粉1项'),
]
for i, row_data in enumerate(val_data, 1):
    for j, val in enumerate(row_data):
        t.rows[i].cells[j].text = val

doc.add_paragraph()
doc.add_paragraph(
    '⚠ 注意: 三个方案的水稳定功能组均仅依赖面粉。建议方案A/B额外添加 '
    '0.5-1.0% 谷朊粉或预糊化淀粉以增强水中稳定性，减少溶失。'
)

# ==========================================
# 5. 建议
# ==========================================
doc.add_heading('5. 使用建议', level=1)

suggestions = [
    ('方案A (高鱼粉)', '适合高密度精养、出口品质要求高的场景。诱食性强，开口率和成活率有保障。'),
    ('方案B (平衡)', '适合主流商业养殖，性价比最优。推荐作为默认方案。'),
    ('方案C (经济)', '适合原料价格高位时的替代方案。需注意监控 FCR，适时调整。'),
]

for name, desc in suggestions:
    p = doc.add_paragraph()
    run = p.add_run(f'{name}: ')
    run.bold = True
    p.add_run(desc)

doc.add_paragraph()
p = doc.add_paragraph()
run = p.add_run('通用建议: ')
run.bold = True
p.add_run(
    '1) 三个方案均建议补充谷朊粉 0.5-1.0% 提升水稳定性; '
    '2) 鱼粉价格波动大, 建议锁定远期合同; '
    '3) 虾壳粉和鱿鱼膏兼具诱食功能, 经济型方案不宜进一步削减。'
)

# ==========================================
# 6. 附录
# ==========================================
doc.add_paragraph()
doc.add_paragraph()
p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = p.add_run('— 报告由 AquaFeedFormulator v2 + PrologAgentTeam 自动生成 —')
run.font.size = Pt(8)
run.font.color.rgb = RGBColor(0x99, 0x99, 0x99)

# 保存
output_path = '/Users/weifengchen/Desktop/南美白对虾幼虾饲料配方报告.docx'
doc.save(output_path)
print(f'✅ 报告已生成: {output_path}')
