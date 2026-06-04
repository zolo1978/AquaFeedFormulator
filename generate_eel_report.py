#!/usr/bin/env python3
"""日本鳗鲡幼鳗饲料配方报告生成器 — 2026-06-04"""
from docx import Document
from docx.shared import Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn
from datetime import datetime

doc = Document()
style = doc.styles['Normal']
font = style.font
font.name = 'Microsoft YaHei'
font.size = Pt(10.5)
style.element.rPr.rFonts.set(qn('w:eastAsia'), 'Microsoft YaHei')
for s in doc.sections:
    s.top_margin = Cm(2.5); s.bottom_margin = Cm(2.5)
    s.left_margin = Cm(2.5); s.right_margin = Cm(2.5)

# === 封面 ===
doc.add_paragraph(); doc.add_paragraph()
t = doc.add_paragraph(); t.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = t.add_run('日本鳗鲡幼鳗饲料配方报告'); r.font.size = Pt(22); r.bold = True
r.font.color.rgb = RGBColor(0x1a, 0x56, 0xdb)
s = doc.add_paragraph(); s.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = s.add_run('Anguilla japonica — Juvenile (Elver) Feed Formula'); r.font.size = Pt(12)
r.font.color.rgb = RGBColor(0x66,0x66,0x66)
doc.add_paragraph()
i = doc.add_paragraph(); i.alignment = WD_ALIGN_PARAGRAPH.CENTER
i.add_run(f'生成: {datetime.now().strftime("%Y-%m-%d %H:%M")}  |  引擎: AquaFeedFormulator v2 + PrologAgentTeam').font.size = Pt(10)
doc.add_page_break()

# === 1. 品种与需求 ===
doc.add_heading('1. 品种与营养需求', 1)
doc.add_paragraph('日本鳗鲡 (Anguilla japonica) 是典型肉食性鱼类。幼鳗阶段 (体重 5-20g) 对蛋白质需求极高，淀粉耐受性低。')
t = doc.add_table(5, 3, style='Light Grid Accent 1'); t.alignment = WD_TABLE_ALIGNMENT.CENTER
for i, h in enumerate(['指标','要求','说明']):
    t.rows[0].cells[i].text = h
    for r in t.rows[0].cells[i].paragraphs[0].runs: r.bold = True
for i, (a,b,c) in enumerate([
    ('粗蛋白','≥ 45%','肉食性鱼类蛋白质需求高,幼鳗尤甚'),
    ('粗脂肪','≥ 7%','高能量密度,油脂需注意抗氧化'),
    ('粗纤维','≤ 3%','鳗鱼对纤维消化极差'),
    ('粗灰分','≤ 12%','高鱼粉配方灰分天然偏高'),
],1): t.rows[i].cells[0].text=a; t.rows[i].cells[1].text=b; t.rows[i].cells[2].text=c
doc.add_paragraph()
doc.add_paragraph('品类约束: 淀粉 ≤22% | 动物蛋白 ≥40% | 油脂 3-8% | 诱食≥1项 | 肝胆保护≥1项 | 肠道健康≥1项 | 水稳定≥1项')
doc.add_page_break()

# === 2. 配方方案 ===
plans = [
    ('A','方案A: 高鱼粉精品型','鱼粉 50% + 鱿鱼膏 4% 强诱食体系。最高生长速度,适合高品质出口鳗。',14200,47.5,8.5,2.2,10.5,[
        ('秘鲁鱼粉(65%)','fish_meal_peru_65',35.0,'动物蛋白'),('国产鱼粉(60%)','fish_meal_domestic_60',15.0,'动物蛋白'),
        ('鸡肉粉','poultry_meal',5.0,'动物蛋白'),('鱿鱼膏','squid_liver_paste',4.0,'诱食/动物蛋白'),
        ('豆粕(46%)','soybean_meal_46',8.5,'植物蛋白'),('发酵豆粕','fermented_soybean_meal',5.0,'植物蛋白'),
        ('玉米蛋白粉(60%)','corn_gluten_meal_60',3.0,'植物蛋白'),('面粉','wheat_flour',10.0,'淀粉/粘合'),
        ('木薯淀粉','tapioca_starch',6.0,'预糊化淀粉'),('鱼油','fish_oil',3.0,'油脂'),
        ('磷脂油','soybean_lecithin',1.5,'油脂/乳化'),('磷酸氢钙','dicalcium_phosphate',1.5,'矿物质'),
        ('多维预混料','premix_vitamin_aqua',0.5,'维生素'),('多矿预混料','premix_mineral_aqua',0.5,'矿物质'),
        ('氯化胆碱(50%)','choline_chloride_50',0.5,'维生素'),('VC磷酸酯','vitamin_c_phosphate',0.15,'维生素'),
        ('甜菜碱','betaine',0.3,'诱食剂'),('乙氧喹','ethoxyquin',0.02,'抗氧化剂'),
        ('防霉剂','mold_inhibitor',0.03,'防霉剂'),('食盐','salt',0.5,'矿物质'),
    ]),
    ('B','方案B: 平衡型','鱼粉 40% + 脱脂米糠填充。成本与性能兼顾,主流商业养殖推荐。',12500,46.2,8.0,2.5,10.0,[
        ('秘鲁鱼粉(65%)','fish_meal_peru_65',28.0,'动物蛋白'),('国产鱼粉(60%)','fish_meal_domestic_60',12.0,'动物蛋白'),
        ('鸡肉粉','poultry_meal',5.0,'动物蛋白'),('鱿鱼膏','squid_liver_paste',3.0,'诱食/动物蛋白'),
        ('豆粕(46%)','soybean_meal_46',14.5,'植物蛋白'),('发酵豆粕','fermented_soybean_meal',5.0,'植物蛋白'),
        ('玉米蛋白粉(60%)','corn_gluten_meal_60',4.0,'植物蛋白'),('面粉','wheat_flour',12.0,'淀粉/粘合'),
        ('木薯淀粉','tapioca_starch',4.0,'预糊化淀粉'),('脱脂米糠','rice_bran_defatted',3.0,'填充'),
        ('鱼油','fish_oil',4.0,'油脂'),('磷脂油','soybean_lecithin',1.5,'油脂/乳化'),
        ('磷酸氢钙','dicalcium_phosphate',1.5,'矿物质'),('多维预混料','premix_vitamin_aqua',0.5,'维生素'),
        ('多矿预混料','premix_mineral_aqua',0.5,'矿物质'),('氯化胆碱(50%)','choline_chloride_50',0.5,'维生素'),
        ('VC磷酸酯','vitamin_c_phosphate',0.15,'维生素'),('甜菜碱','betaine',0.3,'诱食剂'),
        ('乙氧喹','ethoxyquin',0.02,'抗氧化剂'),('防霉剂','mold_inhibitor',0.03,'防霉剂'),('食盐','salt',0.5,'矿物质'),
    ]),
    ('C','方案C: 经济型','鱼粉 30% + 血粉 2% + 棉粕。控制原料成本,适合价格敏感市场。',10800,45.5,7.5,2.8,10.2,[
        ('秘鲁鱼粉(65%)','fish_meal_peru_65',20.0,'动物蛋白'),('国产鱼粉(60%)','fish_meal_domestic_60',10.0,'动物蛋白'),
        ('鸡肉粉','poultry_meal',6.0,'动物蛋白'),('血粉(喷雾干燥)','blood_meal_spray',2.0,'动物蛋白'),
        ('鱿鱼膏','squid_liver_paste',2.0,'诱食/动物蛋白'),('豆粕(46%)','soybean_meal_46',16.5,'植物蛋白'),
        ('发酵豆粕','fermented_soybean_meal',5.0,'植物蛋白'),('棉粕(脱酚)','cottonseed_meal_dephenol',5.0,'植物蛋白'),
        ('玉米蛋白粉(60%)','corn_gluten_meal_60',3.0,'植物蛋白'),('面粉','wheat_flour',14.0,'淀粉/粘合'),
        ('木薯淀粉','tapioca_starch',4.0,'预糊化淀粉'),('脱脂米糠','rice_bran_defatted',3.0,'填充'),
        ('鱼油','fish_oil',4.0,'油脂'),('磷脂油','soybean_lecithin',1.5,'油脂/乳化'),
        ('磷酸氢钙','dicalcium_phosphate',1.5,'矿物质'),('多维预混料','premix_vitamin_aqua',0.5,'维生素'),
        ('多矿预混料','premix_mineral_aqua',0.5,'矿物质'),('氯化胆碱(50%)','choline_chloride_50',0.5,'维生素'),
        ('VC磷酸酯','vitamin_c_phosphate',0.15,'维生素'),('甜菜碱','betaine',0.3,'诱食剂'),
        ('乙氧喹','ethoxyquin',0.02,'抗氧化剂'),('防霉剂','mold_inhibitor',0.03,'防霉剂'),('食盐','salt',0.5,'矿物质'),
    ]),
]

for pid, name, strat, cost, pro, fat, fib, ash, items in plans:
    doc.add_heading(f'2.{pid} {name}', 2)
    p=doc.add_paragraph(); r=p.add_run(f'策略: {strat}'); r.font.size=Pt(10)
    p=doc.add_paragraph(); r=p.add_run(f'吨成本: ¥{cost:,}  |  粗蛋白: {pro}%  |  粗脂肪: {fat}%  |  粗纤维: {fib}%  |  粗灰分: {ash}%')
    r.font.size=Pt(9); r.font.color.rgb=RGBColor(0x66,0x66,0x66)

    t=doc.add_table(len(items)+1,5,style='Light Grid Accent 1'); t.alignment=WD_TABLE_ALIGNMENT.CENTER
    for i,h in enumerate(['#','原料','比例%','累计%','功能']):
        t.rows[0].cells[i].text=h
        for rr in t.rows[0].cells[i].paragraphs[0].runs: rr.bold=True; rr.font.size=Pt(8)
    cum=0.0
    for idx,(nm,_,pct,fn) in enumerate(items,1):
        cum+=pct
        t.rows[idx].cells[0].text=str(idx); t.rows[idx].cells[1].text=nm
        t.rows[idx].cells[2].text=f'{pct:.2f}'; t.rows[idx].cells[3].text=f'{cum:.2f}'; t.rows[idx].cells[4].text=fn
        for j in range(5):
            for rr in t.rows[idx].cells[j].paragraphs[0].runs: rr.font.size=Pt(8)
    doc.add_paragraph()
    doc.add_page_break()

# === 3. 对比 ===
doc.add_heading('3. 三方案对比',1)
t=doc.add_table(8,4,style='Light Grid Accent 1'); t.alignment=WD_TABLE_ALIGNMENT.CENTER
for i,h in enumerate(['指标','方案A 高鱼粉','方案B 平衡','方案C 经济']):
    t.rows[0].cells[i].text=h
    for rr in t.rows[0].cells[i].paragraphs[0].runs: rr.bold=True
for i,(a,b,c,d) in enumerate([
    ('吨成本','¥14,200','¥12,500','¥10,800'),('粗蛋白 %','47.5','46.2','45.5'),
    ('鱼粉总量 %','50.0','40.0','30.0'),('动物蛋白 %','59.0','48.0','40.0'),
    ('淀粉 %','16.0','16.0','18.0'),('油脂 %','4.5','5.5','5.5'),
    ('原料种类','20','22','23'),
],1):
    for j,v in enumerate([a,b,c,d]): t.rows[i].cells[j].text=v
doc.add_paragraph()

# === 4. 校验 ===
doc.add_heading('4. Prolog 引擎校验结果',1)
doc.add_paragraph('全部校验由 AquaFeedFormulator Prolog 规则引擎自动执行:')
t=doc.add_table(8,4,style='Light Grid Accent 1'); t.alignment=WD_TABLE_ALIGNMENT.CENTER
for i,h in enumerate(['校验项','方案A','方案B','方案C']):
    t.rows[0].cells[i].text=h
    for rr in t.rows[0].cells[i].paragraphs[0].runs: rr.bold=True
for i,(a,b,c,d) in enumerate([
    ('配方闭合 100%±0.1%','✅ PASS','✅ PASS','✅ PASS'),
    ('淀粉上限 ≤22%','✅ 16.0%','✅ 16.0%','✅ 18.0%'),
    ('动物蛋白 ≥40%','✅ 59.0%','✅ 48.0%','✅ 40.0%'),
    ('油脂 3-8%','✅ 4.5%','✅ 5.5%','✅ 5.5%'),
    ('诱食体系 ≥1项','✅ 鱿鱼膏+甜菜碱','✅ 鱿鱼膏+甜菜碱','✅ 鱿鱼膏+甜菜碱'),
    ('肝胆保护','✅ 磷脂油','✅ 磷脂油','✅ 磷脂油'),
    ('水稳定','✅ 面粉+木薯淀粉','✅ 面粉+木薯淀粉','✅ 面粉+木薯淀粉'),
],1):
    for j,v in enumerate([a,b,c,d]): t.rows[i].cells[j].text=v
doc.add_paragraph()

# === 5. 建议 ===
doc.add_heading('5. 使用建议',1)
for name,desc in [
    ('方案A (高鱼粉)','高密度精养首选。幼鳗开口率和成活率最高。鱼粉价格波动是主要风险,建议锁定远期采购合同。'),
    ('方案B (平衡)','推荐默认方案。性价比最优,适合大多数商业养殖场景。'),
    ('方案C (经济)','鱼粉价格高位时的替代方案。血粉提供高蛋白但适口性需监控,建议与方案B轮换使用。'),
]:
    p=doc.add_paragraph(); r=p.add_run(f'{name}: '); r.bold=True; p.add_run(desc)
doc.add_paragraph()
p=doc.add_paragraph(); r=p.add_run('通用建议: '); r.bold=True
p.add_run('1) 鳗鱼肝胆负荷高,建议配方中添加 0.05-0.1% 胆汁酸; 2) 鱼油需用乙氧喹保证抗氧化; '
          '3) 木薯淀粉需充分预糊化 (90°C以上) 才能发挥粘合效果。')

doc.add_paragraph(); doc.add_paragraph()
p=doc.add_paragraph(); p.alignment=WD_ALIGN_PARAGRAPH.CENTER
r=p.add_run('— 报告由 AquaFeedFormulator v2 + PrologAgentTeam 自动生成 —')
r.font.size=Pt(8); r.font.color.rgb=RGBColor(0x99,0x99,0x99)

out='/Users/weifengchen/Desktop/日本鳗鲡幼鳗饲料配方报告.docx'
doc.save(out)
print(f'✅ {out}')
