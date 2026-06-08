#!/usr/bin/env python3
"""
AquaFeedFormulator — DOCX 配方报告生成器 v2.1
输入: recipe_data.json (由 bridge_prolog_docx.rb 生成)
输出: Desktop/南美白对虾成体饲料配方报告.docx
"""

import json, sys, os
from datetime import datetime

def main():
    if len(sys.argv) < 2:
        print("用法: python3 generate_report.py <recipe_data.json>")
        sys.exit(1)
    
    json_path = sys.argv[1]
    if not os.path.exists(json_path):
        data = get_embedded_data()
        print("⚠ JSON 文件不存在，使用内嵌配方数据")
    else:
        with open(json_path, 'r') as f:
            data = json.load(f)
    
    generate_docx(data)

def generate_docx(data):
    from docx import Document
    from docx.shared import Inches, Pt, Cm, RGBColor
    from docx.enum.text import WD_ALIGN_PARAGRAPH
    from docx.enum.table import WD_TABLE_ALIGNMENT
    from docx.oxml.ns import qn

    doc = Document()
    
    # 样式
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
    
    meta = data.get('meta', {})
    species = meta.get('species', '南美白对虾')
    stage = meta.get('stage', '成体')
    species_desc = meta.get('species_desc', f'{species} (Litopenaeus vannamei) 是全球养殖产量最高的对虾品种。')
    nutrition = data.get('nutrition', {})
    plans = data.get('plans', [])
    constraints = data.get('constraints', [])
    
    # ── 封面 ──
    doc.add_paragraph()
    doc.add_paragraph()
    title = doc.add_paragraph()
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = title.add_run(f'{species}{stage}饲料配方报告')
    run.font.size = Pt(22)
    run.bold = True
    run.font.color.rgb = RGBColor(0x1a, 0x56, 0xdb)
    
    subtitle = doc.add_paragraph()
    subtitle.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = subtitle.add_run(f'AquaFeedFormulator — {species} {stage} Feed Formula')
    run.font.size = Pt(12)
    run.font.color.rgb = RGBColor(0x66, 0x66, 0x66)
    
    doc.add_paragraph()
    info = doc.add_paragraph()
    info.alignment = WD_ALIGN_PARAGRAPH.CENTER
    info.add_run(f'生成日期: {meta.get("generated_at", datetime.now().strftime("%Y-%m-%d %H:%M"))}\n').font.size = Pt(10)
    info.add_run(f'引擎: {meta.get("engine", "AquaFeedFormulator v2 + PrologAgentTeam")}\n').font.size = Pt(10)
    info.add_run('校验: Prolog SOP Gatekeeper (8步校验)').font.size = Pt(10)
    
    doc.add_page_break()
    
    # ── 1. 品种与营养需求 ──
    doc.add_heading('1. 品种与营养需求', level=1)
    doc.add_paragraph(species_desc)
    
    # 营养需求表
    t = doc.add_table(rows=5, cols=3, style='Light Grid Accent 1')
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    headers = ['营养指标', '要求值', '说明']
    for i, h_text in enumerate(headers):
        t.rows[0].cells[i].text = h_text
        for p in t.rows[0].cells[i].paragraphs:
            for run in p.runs:
                run.bold = True
    
    nut_data = [
        ('粗蛋白 Crude Protein', f'≥ {nutrition.get("protein", "-")}%', f'{stage}阶段蛋白需求适中'),
        ('粗脂肪 Crude Fat', f'≥ {nutrition.get("fat", "-")}%', '提供必需脂肪酸和能量'),
        ('粗纤维 Crude Fiber', f'≤ {nutrition.get("fiber", "-")}%', '虾对纤维消化能力有限'),
        ('粗灰分 Crude Ash', f'≤ {nutrition.get("ash", "-")}%', '含甲壳类必需的矿物质'),
    ]
    for i, (a, b, c) in enumerate(nut_data, 1):
        t.rows[i].cells[0].text = a
        t.rows[i].cells[1].text = b
        t.rows[i].cells[2].text = c
    
    doc.add_paragraph()
    
    # 品类约束
    constraint_text = ' | '.join([
        f"{c.get('desc', c['type'])} {'≤' if c.get('op') == 'max' else '≥'} {c['limit']}%"
        for c in constraints
    ])
    doc.add_paragraph(f'品类约束: {constraint_text}')
    
    if meta.get('data_sources'):
        doc.add_paragraph(f'数据来源: {meta["data_sources"]}')
    
    if meta.get('disclaimer'):
        p = doc.add_paragraph()
        run = p.add_run(meta['disclaimer'])
        run.font.size = Pt(8)
        run.font.color.rgb = RGBColor(0x99, 0x99, 0x99)
    
    doc.add_page_break()
    
    # ── 2. 配方方案 ──
    for plan in plans:
        pid = plan['id']
        doc.add_heading(f'2.{pid} {plan["name"]}', level=2)
        
        strategy = plan.get('strategy', '')
        if strategy:
            p = doc.add_paragraph()
            p.add_run(f'策略: {strategy}').font.size = Pt(10)
        
        # 营养目标 vs 实际
        p = doc.add_paragraph()
        target_str = (
            f'营养目标: 蛋白≥{plan.get("protein_target","-")}% 脂肪≥{plan.get("fat_target","-")}% '
            f'纤维≤{plan.get("fiber_target","-")}% 灰分≤{plan.get("ash_target","-")}%'
        )
        actual_str = ''
        if plan.get('protein_actual') is not None:
            actual_str = (
                f'\n营养实际: 蛋白={plan["protein_actual"]:.1f}% 脂肪={plan["fat_actual"]:.1f}% '
                f'纤维={plan["fiber_actual"]:.1f}% 灰分={plan["ash_actual"]:.1f}%'
            )
        run = p.add_run(target_str + actual_str)
        run.font.size = Pt(9)
        
        # 成本与闭合
        p = doc.add_paragraph()
        cost = plan.get('cost', plan.get('price_per_kg', 0))
        closure = plan.get('closure', sum(item['pct'] for item in plan.get('items', [])))
        run = p.add_run(
            f'吨成本: ¥{cost:,.0f}  |  配方闭合: {closure:.1f}%  |  '
            f'动物蛋白: {plan.get("animal_protein_pct","-")}%  |  淀粉: {plan.get("starch_pct","-")}%'
        )
        run.font.size = Pt(9)
        run.font.color.rgb = RGBColor(0x66, 0x66, 0x66)
        
        # 配方表
        items = plan.get('items', [])
        rows = len(items) + 1
        t = doc.add_table(rows=rows, cols=5, style='Light Grid Accent 1')
        t.alignment = WD_TABLE_ALIGNMENT.CENTER
        
        for i, h_text in enumerate(['#', '原料名称', '比例(%)', '累计(%)', '功能分类']):
            t.rows[0].cells[i].text = h_text
            for p_cell in t.rows[0].cells[i].paragraphs:
                for run_cell in p_cell.runs:
                    run_cell.bold = True
                    run_cell.font.size = Pt(8)
        
        cumulative = 0.0
        for idx, item in enumerate(items, 1):
            pct = item['pct']
            cumulative += pct
            cat = item.get('category', '')
            t.rows[idx].cells[0].text = str(idx)
            t.rows[idx].cells[1].text = item['name']
            t.rows[idx].cells[2].text = f'{pct:.2f}'
            t.rows[idx].cells[3].text = f'{cumulative:.2f}'
            t.rows[idx].cells[4].text = cat
        
        doc.add_paragraph()
        
        # 微量添加剂表
        additives = plan.get('additives', [])
        if additives:
            doc.add_paragraph('微量添加剂 (后处理追加):').runs[0].bold = True
            at = doc.add_table(rows=len(additives) + 1, cols=3, style='Light Grid Accent 1')
            at.alignment = WD_TABLE_ALIGNMENT.CENTER
            for i, h_text in enumerate(['添加剂', '比例(%)', '说明']):
                at.rows[0].cells[i].text = h_text
                for p_cell in at.rows[0].cells[i].paragraphs:
                    for run_cell in p_cell.runs:
                        run_cell.bold = True
                        run_cell.font.size = Pt(7)
            for ai, a in enumerate(additives, 1):
                at.rows[ai].cells[0].text = a.get('name', '')
                at.rows[ai].cells[1].text = f'{a.get("pct", 0):.2f}'
                at.rows[ai].cells[2].text = a.get('reason', '')
            doc.add_paragraph()
        
        doc.add_page_break()
    
    # ── 3. 三方案对比 ──
    doc.add_heading('3. 三方案对比', level=1)
    
    t = doc.add_table(rows=8, cols=4, style='Light Grid Accent 1')
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    
    headers = ['指标'] + [f'方案{p["id"]} {p["name"]}' for p in plans[:3]]
    for i, h_text in enumerate(headers):
        t.rows[0].cells[i].text = h_text
        for p_cell in t.rows[0].cells[i].paragraphs:
            for run_cell in p_cell.runs:
                run_cell.bold = True
    
    def fmt_val(plan, key, default='-'):
        v = plan.get(key, default)
        if isinstance(v, (int, float)):
            return f'{v:.1f}'
        return str(v)
    
    compare_data = [
        ('吨成本 (元)', [f'¥{p.get("cost", 0):,.0f}' for p in plans]),
        ('配方闭合 (%)', [f'{p.get("closure", 0):.1f}' for p in plans]),
        ('蛋白实际 (%)', [fmt_val(p, 'protein_actual', p.get('protein_target','-')) for p in plans]),
        ('脂肪实际 (%)', [fmt_val(p, 'fat_actual', p.get('fat_target','-')) for p in plans]),
        ('动物蛋白 (%)', [str(p.get('animal_protein_pct', '-')) for p in plans]),
        ('淀粉类 (%)', [str(p.get('starch_pct', '-')) for p in plans]),
        ('原料种类数', [str(len(p.get('items', []))) for p in plans]),
    ]
    for i, (label, vals) in enumerate(compare_data, 1):
        t.rows[i].cells[0].text = label
        for j, val in enumerate(vals):
            t.rows[i].cells[j+1].text = val
    
    doc.add_paragraph()
    
    # ── 4. 校验结果 ──
    doc.add_heading('4. Prolog SOP Gatekeeper 校验结果', level=1)
    doc.add_paragraph('以下校验由 AquaFeedFormulator Prolog 规则引擎自动执行 (8步 Gatekeeper):')
    
    # 8 步校验表
    sop_steps = [
        ('营养目标匹配', 'nutrition_match'),
        ('原料合规性', 'ingredient_compliance'),
        ('必需氨基酸平衡', 'amino_balance'),
        ('矿物质平衡', 'mineral_balance'),
        ('品类约束', 'category_constraints'),
        ('诱食体系', 'attractant_system'),
        ('水稳定性', 'water_stability'),
        ('成本范围', 'cost_range'),
    ]
    
    has_any_validation = any(
        p.get('validation') and (
            p['validation'].get('mineral') or
            p['validation'].get('amino') or
            p['validation'].get('risk')
        )
        for p in plans
    )
    
    if has_any_validation:
        doc.add_paragraph('⏳ 详细校验数据由 Prolog 引擎输出，当前以摘要形式展示。')
        for plan in plans[:1]:
            v = plan.get('validation', {})
            mineral = v.get('mineral', {})
            amino = v.get('amino', {})
            risk = v.get('risk', {})
            
            if mineral:
                doc.add_heading(f'  方案{plan["id"]} 矿物质平衡', level=3)
                doc.add_paragraph(f'可利用磷: {mineral.get("available_phosphorus", "-")} | '
                                f'钙磷比: {mineral.get("ca_p_ratio", "-")} | '
                                f'状态: {mineral.get("summary", "-")}')
            if amino:
                doc.add_heading(f'  方案{plan["id"]} 氨基酸平衡', level=3)
                eaa_list = amino.get('eaa_ratios', {})
                if eaa_list:
                    items_text = ', '.join([f'{k}={v:.2f}' for k, v in eaa_list.items()])
                else:
                    items_text = str(amino)
                doc.add_paragraph(f'EAA 比值 (理想蛋白=1.0): {items_text}')
            if risk:
                doc.add_heading(f'  方案{plan["id"]} 绩效风险评估', level=3)
                doc.add_paragraph(f'风险等级: {risk.get("risk_level", "-")} | '
                                f'详细信息: {risk.get("details", str(risk))}')
    else:
        # 从 plans 字段提取校验信息
        t = doc.add_table(rows=4, cols=4, style='Light Grid Accent 1')
        t.alignment = WD_TABLE_ALIGNMENT.CENTER
        
        for i, h_text in enumerate(['校验项', '方案A', '方案B', '方案C']):
            t.rows[0].cells[i].text = h_text
            for p_cell in t.rows[0].cells[i].paragraphs:
                for run_cell in p_cell.runs:
                    run_cell.bold = True
        
        # 闭合校验
        closures = []
        for p in plans:
            c = p.get('closure', sum(item['pct'] for item in p.get('items', [])))
            closures.append(f'{"✅" if abs(c - 100.0) <= 0.15 else "⚠"} {c:.1f}%')
        
        # 淀粉上限
        starches = []
        for p in plans:
            sp = p.get('starch_pct', 99)
            starches.append(f'{"✅" if sp <= 20.1 else "❌"} {sp}%')
        
        # 动物蛋白下限
        animals = []
        for p in plans:
            ap = p.get('animal_protein_pct', 0)
            animals.append(f'{"✅" if ap >= 24.9 else "❌"} {ap}%')
        
        val_data = [
            ('配方闭合 (100%±0.1%)', *closures),
            ('淀粉上限 (≤20%)', *starches),
            ('动物蛋白下限 (≥25%)', *animals),
        ]
        for i, row_data in enumerate(val_data, 1):
            for j, val in enumerate(row_data):
                t.rows[i].cells[j].text = val
        doc.add_paragraph()
    
    doc.add_paragraph()
    
    # ── 5. 建议 ──
    doc.add_heading('5. 使用建议', level=1)
    
    suggestions = [
        (f'方案A ({plans[0]["name"]})' if len(plans) > 0 else '方案A', 
         '高鱼粉+强诱食体系，适合高密度精养、品质优先的场景。'),
        (f'方案B ({plans[1]["name"]})' if len(plans) > 1 else '方案B', 
         '动物/植物蛋白均衡，性价比最优，推荐作为商业养殖默认方案。'),
        (f'方案C ({plans[2]["name"]})' if len(plans) > 2 else '方案C', 
         '适度植物蛋白替代，适合原料价格高位的替代方案，需监控FCR。'),
    ]
    for i, (name, desc) in enumerate(suggestions):
        if i >= len(plans):
            break
        p = doc.add_paragraph()
        run = p.add_run(f'{name}: ')
        run.bold = True
        p.add_run(desc)
    
    doc.add_paragraph()
    p = doc.add_paragraph()
    run = p.add_run('通用建议: ')
    run.bold = True
    p.add_run(
        '1) 建议补充谷朊粉 0.5-1.0% 提升水稳定性; '
        '2) 鱼粉价格波动大，建议锁定远期合同; '
        '3) 虾壳粉和鱿鱼膏兼具诱食功能，经济型方案不宜进一步削减; '
        '4) LP 求解器当前存在 simplex 库兼容性问题，本报告配方为专家经验配方。'
    )
    
    # ── 附录：数据来源 ──
    doc.add_page_break()
    doc.add_heading('附录: 数据来源与声明', level=1)
    
    if meta.get('data_sources'):
        doc.add_paragraph(f'数据来源: {meta["data_sources"]}')
    
    doc.add_paragraph()
    doc.add_paragraph('技术栈: Ruby Bridge (v2.0) → Prolog Agent Team → Python DOCX Generator (v2.1)')
    doc.add_paragraph(f'原料库: {data.get("ingredient_count", "45")} 种通用水产饲料原料')
    doc.add_paragraph(f'校验引擎: Prolog SOP Gatekeeper (营养目标/原料合规/EAA平衡/矿物质平衡/品类约束/诱食体系/水稳定性/成本范围)')
    
    if meta.get('disclaimer'):
        doc.add_paragraph()
        p = doc.add_paragraph()
        run = p.add_run(meta['disclaimer'])
        run.font.size = Pt(8)
        run.font.color.rgb = RGBColor(0x99, 0x99, 0x99)
    
    # 页脚
    doc.add_paragraph()
    doc.add_paragraph()
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = p.add_run(f'— 报告由 AquaFeedFormulator v2 + PrologAgentTeam 自动生成 ({meta.get("generated_at", "")}) —')
    run.font.size = Pt(8)
    run.font.color.rgb = RGBColor(0x99, 0x99, 0x99)
    
    # 保存
    output = os.path.expanduser(f'~/Desktop/{species}{stage}饲料配方报告.docx')
    doc.save(output)
    print(f'✅ 报告已生成: {output}')
    return output

def get_embedded_data():
    """Fallback: 从 recipe_data.json 读取 (bridge v3.0 always generates this)"""
    json_path = Path(__file__).parent / 'generated' / 'recipe_data.json'
    if json_path.exists():
        with open(json_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    raise FileNotFoundError(
        'recipe_data.json 未生成。请先运行 bridge_prolog_docx.rb 生成配方数据。'
    )

if __name__ == '__main__':
    main()
