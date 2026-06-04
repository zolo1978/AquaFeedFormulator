%%==============================================================================
%% AquaFeedFormulator — 饲料配方示例知识库
%% 来源: 《水产饲料调制加工与配方集萃》(薛敏) 附录, p127-133
%% 生成日期: 2026-06-04
%% 注意: 因数据来自7个连续页面，同类谓词分布在不同页面段中。
%%       scryer-prolog v0.10 无需 discontiguous 声明即可正常加载。
%%==============================================================================

%%------------------------------------------------------------------------------
%% 草鱼 (Grass Carp) 配方 — 附录 p127-128
%%------------------------------------------------------------------------------

% 配方1: 草鱼幼鱼料 (含鱼粉+鸡肉粉型)

% === formula_ingredient/3 ===

formula_ingredient('草鱼幼鱼料A', '鱼粉', 10.0).
formula_ingredient('草鱼幼鱼料A', '鸡肉粉', 6.4).
formula_ingredient('草鱼幼鱼料A', '麦麸', 11.7).
formula_ingredient('草鱼幼鱼料A', '面粉', 10.0).
formula_ingredient('草鱼幼鱼料A', '棉粕', 20.0).
formula_ingredient('草鱼幼鱼料A', '菜粕', 15.0).
formula_ingredient('草鱼幼鱼料A', '豆粕', 20.0).
formula_ingredient('草鱼幼鱼料A', '豆油', 4.0).
formula_ingredient('草鱼幼鱼料A', '磷酸二氢钙', 1.8).
formula_ingredient('草鱼幼鱼料A', '预混料', 1.0).
formula_ingredient('草鱼幼鱼料A', '甜菜碱', 0.1).
formula_ingredient('草鱼幼鱼料A', 'DL-蛋氨酸', 0.05).

formula_ingredient('草鱼幼鱼料B', '鱼粉', 10.0).
formula_ingredient('草鱼幼鱼料B', '鸡肉粉', 6.0).
formula_ingredient('草鱼幼鱼料B', '米糠', 6.0).
formula_ingredient('草鱼幼鱼料B', '面粉', 10.0).
formula_ingredient('草鱼幼鱼料B', '菜粕双低', 48.1).
formula_ingredient('草鱼幼鱼料B', '豆粕', 13.0).
formula_ingredient('草鱼幼鱼料B', '豆油', 4.0).
formula_ingredient('草鱼幼鱼料B', '磷酸二氢钙', 1.8).
formula_ingredient('草鱼幼鱼料B', '预混料', 1.0).
formula_ingredient('草鱼幼鱼料B', '甜菜碱', 0.1).

formula_ingredient('草鱼养成料A', '鱼粉', 7.0).
formula_ingredient('草鱼养成料A', '麦麸', 9.2).
formula_ingredient('草鱼养成料A', '面粉', 9.4).
formula_ingredient('草鱼养成料A', '米糠', 10.0).
formula_ingredient('草鱼养成料A', '棉粕', 14.0).
formula_ingredient('草鱼养成料A', '菜粕', 14.0).
formula_ingredient('草鱼养成料A', '豆粕', 28.0).
formula_ingredient('草鱼养成料A', '豆油', 3.5).
formula_ingredient('草鱼养成料A', '磷酸二氢钙', 1.8).
formula_ingredient('草鱼养成料A', '膨润土', 2.0).
formula_ingredient('草鱼养成料A', '预混料', 1.0).
formula_ingredient('草鱼养成料A', '甜菜碱', 0.1).
formula_ingredient('草鱼养成料A', 'DL-蛋氨酸', 0.05).

formula_ingredient('草鱼养成料B', '鱼粉', 3.0).
formula_ingredient('草鱼养成料B', '鸡肉粉', 1.5).
formula_ingredient('草鱼养成料B', '麦麸', 10.0).
formula_ingredient('草鱼养成料B', '面粉', 14.0).
formula_ingredient('草鱼养成料B', '米糠', 10.0).
formula_ingredient('草鱼养成料B', '棉粕', 22.0).
formula_ingredient('草鱼养成料B', '菜粕', 21.4).
formula_ingredient('草鱼养成料B', '豆粕', 8.0).
formula_ingredient('草鱼养成料B', '豆油', 3.0).
formula_ingredient('草鱼养成料B', '磷酸二氢钙', 1.8).
formula_ingredient('草鱼养成料B', '膨润土', 4.15).
formula_ingredient('草鱼养成料B', '预混料', 1.0).
formula_ingredient('草鱼养成料B', '甜菜碱', 0.1).
formula_ingredient('草鱼养成料B', 'DL-蛋氨酸', 0.05).

formula_ingredient('草鱼养成料C', '鱼粉', 5.0).
formula_ingredient('草鱼养成料C', '面粉', 20.0).
formula_ingredient('草鱼养成料C', '米糠', 18.0).
formula_ingredient('草鱼养成料C', '棉粕', 16.5).
formula_ingredient('草鱼养成料C', '菜粕', 16.5).
formula_ingredient('草鱼养成料C', '豆粕', 15.4).
formula_ingredient('草鱼养成料C', '豆油', 1.5).
formula_ingredient('草鱼养成料C', '磷酸二氢钙', 2.0).
formula_ingredient('草鱼养成料C', '膨润土', 4.0).
formula_ingredient('草鱼养成料C', '预混料', 1.0).
formula_ingredient('草鱼养成料C', '甜菜碱', 0.1).
formula_ingredient('草鱼养成料C', 'DL-蛋氨酸', 0.05).

formula_ingredient('鲤鲫鱼小鱼料', '进口鱼粉', 16.0).
formula_ingredient('鲤鲫鱼小鱼料', '鸡肉粉', 12.0).
formula_ingredient('鲤鲫鱼小鱼料', '大豆粕', 13.63).
formula_ingredient('鲤鲫鱼小鱼料', '棉籽粕', 12.0).
formula_ingredient('鲤鲫鱼小鱼料', '菜籽粕', 11.83).
formula_ingredient('鲤鲫鱼小鱼料', '全脂米糠', 8.0).
formula_ingredient('鲤鲫鱼小鱼料', '次粉', 20.0).
formula_ingredient('鲤鲫鱼小鱼料', '磷酸二氢钙', 2.2).
formula_ingredient('鲤鲫鱼小鱼料', '植物油', 3.0).
formula_ingredient('鲤鲫鱼小鱼料', '胆碱50', 0.3).
formula_ingredient('鲤鲫鱼小鱼料', 'VC90', 0.04).
formula_ingredient('鲤鲫鱼小鱼料', '预混料', 1.0).

formula_ingredient('鲤鲫鱼成鱼料', '进口鱼粉', 12.0).
formula_ingredient('鲤鲫鱼成鱼料', '鸡肉粉', 10.0).
formula_ingredient('鲤鲫鱼成鱼料', '大豆粕', 12.0).
formula_ingredient('鲤鲫鱼成鱼料', '棉籽粕', 12.0).
formula_ingredient('鲤鲫鱼成鱼料', '菜籽粕', 17.99).
formula_ingredient('鲤鲫鱼成鱼料', '全脂米糠', 8.64).
formula_ingredient('鲤鲫鱼成鱼料', '次粉', 20.0).
formula_ingredient('鲤鲫鱼成鱼料', '磷酸二氢钙', 2.07).
formula_ingredient('鲤鲫鱼成鱼料', '植物油', 3.0).
formula_ingredient('鲤鲫鱼成鱼料', '胆碱50', 0.3).
formula_ingredient('鲤鲫鱼成鱼料', 'VC90', 0.04).
formula_ingredient('鲤鲫鱼成鱼料', '膨润土', 0.96).
formula_ingredient('鲤鲫鱼成鱼料', '预混料', 1.0).

formula_ingredient('鲤草鱼混养前期料', '进口鱼粉', 8.0).
formula_ingredient('鲤草鱼混养前期料', '鸡肉粉', 10.0).
formula_ingredient('鲤草鱼混养前期料', '大豆粕', 12.0).
formula_ingredient('鲤草鱼混养前期料', '棉籽粕', 10.0).
formula_ingredient('鲤草鱼混养前期料', '菜籽粕', 24.6).
formula_ingredient('鲤草鱼混养前期料', '全脂米糠', 9.1).
formula_ingredient('鲤草鱼混养前期料', '次粉', 20.0).
formula_ingredient('鲤草鱼混养前期料', '磷酸二氢钙', 2.0).
formula_ingredient('鲤草鱼混养前期料', '植物油', 2.0).
formula_ingredient('鲤草鱼混养前期料', '胆碱50', 0.3).
formula_ingredient('鲤草鱼混养前期料', 'VC90', 0.04).
formula_ingredient('鲤草鱼混养前期料', '预混料', 1.0).

formula_ingredient('鲤草鱼混养后期料', '进口鱼粉', 4.0).
formula_ingredient('鲤草鱼混养后期料', '鸡肉粉', 8.0).
formula_ingredient('鲤草鱼混养后期料', '大豆粕', 12.0).
formula_ingredient('鲤草鱼混养后期料', '棉籽粕', 9.67).
formula_ingredient('鲤草鱼混养后期料', '菜籽粕', 29.45).
formula_ingredient('鲤草鱼混养后期料', '全脂米糠', 9.05).
formula_ingredient('鲤草鱼混养后期料', '次粉', 20.0).
formula_ingredient('鲤草鱼混养后期料', '磷酸二氢钙', 1.9).
formula_ingredient('鲤草鱼混养后期料', '植物油', 2.0).
formula_ingredient('鲤草鱼混养后期料', '胆碱50', 0.3).
formula_ingredient('鲤草鱼混养后期料', 'VC90', 0.04).
formula_ingredient('鲤草鱼混养后期料', '膨润土', 2.59).
formula_ingredient('鲤草鱼混养后期料', '预混料', 1.0).

formula_ingredient('淡水鱼鱼苗料', '进口鱼粉', 5.0).
formula_ingredient('淡水鱼鱼苗料', '鸡肉粉', 6.0).
formula_ingredient('淡水鱼鱼苗料', '大豆粕', 17.61).
formula_ingredient('淡水鱼鱼苗料', '棉籽粕', 14.0).
formula_ingredient('淡水鱼鱼苗料', '菜籽粕', 24.55).
formula_ingredient('淡水鱼鱼苗料', '全脂米糠', 10.0).
formula_ingredient('淡水鱼鱼苗料', '次粉', 18.0).
formula_ingredient('淡水鱼鱼苗料', '磷酸二氢钙', 2.0).
formula_ingredient('淡水鱼鱼苗料', '植物油', 1.5).
formula_ingredient('淡水鱼鱼苗料', '胆碱50', 0.3).
formula_ingredient('淡水鱼鱼苗料', 'VC90', 0.04).
formula_ingredient('淡水鱼鱼苗料', '预混料', 1.0).

formula_ingredient('淡水鱼幼鱼料A', '国产鱼粉', 4.0).
formula_ingredient('淡水鱼幼鱼料A', '鸡肉粉', 5.0).
formula_ingredient('淡水鱼幼鱼料A', '大豆粕', 20.0).
formula_ingredient('淡水鱼幼鱼料A', '棉籽粕', 10.0).
formula_ingredient('淡水鱼幼鱼料A', '菜籽粕', 27.7).
formula_ingredient('淡水鱼幼鱼料A', '全脂米糠', 11.7).
formula_ingredient('淡水鱼幼鱼料A', '次粉', 16.0).
formula_ingredient('淡水鱼幼鱼料A', '磷酸二氢钙', 2.2).
formula_ingredient('淡水鱼幼鱼料A', '植物油', 2.0).
formula_ingredient('淡水鱼幼鱼料A', '胆碱50', 0.3).
formula_ingredient('淡水鱼幼鱼料A', '大蒜素25', 0.03).
formula_ingredient('淡水鱼幼鱼料A', 'VC酯35', 0.1).
formula_ingredient('淡水鱼幼鱼料A', '预混料', 1.0).

formula_ingredient('鲂鱼苗种料', '国产鱼粉', 6.0).
formula_ingredient('鲂鱼苗种料', '鸡肉粉', 4.0).
formula_ingredient('鲂鱼苗种料', '大豆粕', 20.0).
formula_ingredient('鲂鱼苗种料', '棉籽粕', 10.0).
formula_ingredient('鲂鱼苗种料', '菜籽粕', 26.2).
formula_ingredient('鲂鱼苗种料', '全脂米糠', 11.2).
formula_ingredient('鲂鱼苗种料', '次粉', 16.0).
formula_ingredient('鲂鱼苗种料', '磷酸二氢钙', 2.2).
formula_ingredient('鲂鱼苗种料', '植物油', 2.0).
formula_ingredient('鲂鱼苗种料', '胆碱50', 0.3).
formula_ingredient('鲂鱼苗种料', '大蒜素25', 0.03).
formula_ingredient('鲂鱼苗种料', 'VC酯35', 0.1).
formula_ingredient('鲂鱼苗种料', '膨润土', 1.0).
formula_ingredient('鲂鱼苗种料', '预混料', 1.0).

formula_ingredient('鲂鱼养成料', '国产鱼粉', 4.0).
formula_ingredient('鲂鱼养成料', '鸡肉粉', 6.0).
formula_ingredient('鲂鱼养成料', '大豆粕', 20.0).
formula_ingredient('鲂鱼养成料', '棉籽粕', 10.0).
formula_ingredient('鲂鱼养成料', '菜籽粕', 17.5).
formula_ingredient('鲂鱼养成料', '全脂米糠', 19.4).
formula_ingredient('鲂鱼养成料', '次粉', 16.0).
formula_ingredient('鲂鱼养成料', '磷酸二氢钙', 2.0).
formula_ingredient('鲂鱼养成料', '植物油', 2.0).
formula_ingredient('鲂鱼养成料', '胆碱50', 0.3).
formula_ingredient('鲂鱼养成料', '大蒜素25', 0.03).
formula_ingredient('鲂鱼养成料', 'VC酯35', 0.06).
formula_ingredient('鲂鱼养成料', '膨润土', 1.8).
formula_ingredient('鲂鱼养成料', '预混料', 1.0).

formula_ingredient('鳊鱼鱼苗料', '进口鱼粉', 4.0).
formula_ingredient('鳊鱼鱼苗料', '鸡肉粉', 6.0).
formula_ingredient('鳊鱼鱼苗料', '大豆粕', 14.0).
formula_ingredient('鳊鱼鱼苗料', '棉籽粕', 14.0).
formula_ingredient('鳊鱼鱼苗料', '菜籽粕', 23.7).
formula_ingredient('鳊鱼鱼苗料', '全脂米糠', 12.2).
formula_ingredient('鳊鱼鱼苗料', '次粉', 20.0).
formula_ingredient('鳊鱼鱼苗料', '磷酸二氢钙', 1.9).
formula_ingredient('鳊鱼鱼苗料', '植物油', 1.5).
formula_ingredient('鳊鱼鱼苗料', '胆碱50', 0.3).
formula_ingredient('鳊鱼鱼苗料', 'VC90', 0.04).
formula_ingredient('鳊鱼鱼苗料', '膨润土', 1.4).
formula_ingredient('鳊鱼鱼苗料', '预混料', 1.0).

formula_ingredient('鳊鱼养成料', '进口鱼粉', 2.0).
formula_ingredient('鳊鱼养成料', '鸡肉粉', 6.0).
formula_ingredient('鳊鱼养成料', '大豆粕', 12.0).
formula_ingredient('鳊鱼养成料', '棉籽粕', 10.0).
formula_ingredient('鳊鱼养成料', '菜籽粕', 27.6).
formula_ingredient('鳊鱼养成料', '全脂米糠', 15.54).
formula_ingredient('鳊鱼养成料', '次粉', 20.0).
formula_ingredient('鳊鱼养成料', '磷酸二氢钙', 1.8).
formula_ingredient('鳊鱼养成料', '植物油', 1.0).
formula_ingredient('鳊鱼养成料', '胆碱50', 0.3).
formula_ingredient('鳊鱼养成料', 'VC90', 0.04).
formula_ingredient('鳊鱼养成料', '膨润土', 2.77).
formula_ingredient('鳊鱼养成料', '预混料', 1.0).

formula_ingredient('白仔鳗料', '白鱼粉', 40.0).
formula_ingredient('白仔鳗料', '智利鱼粉', 17.0).
formula_ingredient('白仔鳗料', '鸡肉粉', 6.0).
formula_ingredient('白仔鳗料', '大豆浓缩蛋白', 6.0).
formula_ingredient('白仔鳗料', '酵母抽提物', 3.5).
formula_ingredient('白仔鳗料', '木薯变性淀粉', 23.1).
formula_ingredient('白仔鳗料', '磷酸二氢钙', 1.8).
formula_ingredient('白仔鳗料', '腐殖酸钠', 0.3).
formula_ingredient('白仔鳗料', '食盐', 0.5).
formula_ingredient('白仔鳗料', '卵磷脂', 0.2).
formula_ingredient('白仔鳗料', '氯化胆碱60', 0.6).
formula_ingredient('白仔鳗料', '预混料', 1.0).

formula_ingredient('黑仔鳗料', '白鱼粉', 35.0).
formula_ingredient('黑仔鳗料', '智利鱼粉', 20.0).
formula_ingredient('黑仔鳗料', '鸡肉粉', 8.0).
formula_ingredient('黑仔鳗料', '大豆浓缩蛋白', 6.0).
formula_ingredient('黑仔鳗料', '酵母抽提物', 3.5).
formula_ingredient('黑仔鳗料', '木薯变性淀粉', 23.2).
formula_ingredient('黑仔鳗料', '磷酸二氢钙', 1.8).
formula_ingredient('黑仔鳗料', '腐殖酸钠', 0.3).
formula_ingredient('黑仔鳗料', '食盐', 0.6).
formula_ingredient('黑仔鳗料', '氯化胆碱60', 0.6).
formula_ingredient('黑仔鳗料', '预混料', 1.0).

formula_ingredient('幼鳗料', '白鱼粉', 28.0).
formula_ingredient('幼鳗料', '智利鱼粉', 25.0).
formula_ingredient('幼鳗料', '鸡肉粉', 8.0).
formula_ingredient('幼鳗料', '大豆浓缩蛋白', 6.0).
formula_ingredient('幼鳗料', '酵母抽提物', 5.0).
formula_ingredient('幼鳗料', '木薯变性淀粉', 23.7).
formula_ingredient('幼鳗料', '磷酸二氢钙', 1.8).
formula_ingredient('幼鳗料', '腐殖酸钠', 0.3).
formula_ingredient('幼鳗料', '食盐', 0.6).
formula_ingredient('幼鳗料', '氯化胆碱60', 0.6).
formula_ingredient('幼鳗料', '预混料', 1.0).

formula_ingredient('养成鳗料', '白鱼粉', 25.0).
formula_ingredient('养成鳗料', '智利鱼粉', 26.0).
formula_ingredient('养成鳗料', '鸡肉粉', 8.0).
formula_ingredient('养成鳗料', '大豆浓缩蛋白', 6.0).
formula_ingredient('养成鳗料', '酵母抽提物', 6.0).
formula_ingredient('养成鳗料', '木薯变性淀粉', 24.7).
formula_ingredient('养成鳗料', '磷酸二氢钙', 1.8).
formula_ingredient('养成鳗料', '腐殖酸钠', 0.3).
formula_ingredient('养成鳗料', '食盐', 0.6).
formula_ingredient('养成鳗料', '氯化胆碱60', 0.6).
formula_ingredient('养成鳗料', '预混料', 1.0).

formula_ingredient('鲈鱼苗料', '进口鱼粉', 20.0).
formula_ingredient('鲈鱼苗料', '国产鱼粉', 14.0).
formula_ingredient('鲈鱼苗料', '乌贼膏', 2.5).
formula_ingredient('鲈鱼苗料', '豆粕', 14.0).
formula_ingredient('鲈鱼苗料', '酵母提取物', 3.0).
formula_ingredient('鲈鱼苗料', '膨化大豆', 6.0).
formula_ingredient('鲈鱼苗料', '花生麸', 9.2).
formula_ingredient('鲈鱼苗料', '大豆卵磷脂', 1.0).
formula_ingredient('鲈鱼苗料', '鱼油', 3.5).
formula_ingredient('鲈鱼苗料', '面粉', 24.0).
formula_ingredient('鲈鱼苗料', '磷酸二氢钙', 1.0).
formula_ingredient('鲈鱼苗料', '胆碱50', 0.3).
formula_ingredient('鲈鱼苗料', 'VC酯35', 0.05).
formula_ingredient('鲈鱼苗料', '食盐', 0.4).
formula_ingredient('鲈鱼苗料', '防霉剂和抗氧化剂', 0.05).
formula_ingredient('鲈鱼苗料', '预混料', 1.0).

formula_ingredient('幼鲈料', '进口鱼粉', 18.0).
formula_ingredient('幼鲈料', '国产鱼粉', 12.0).
formula_ingredient('幼鲈料', '乌贼膏', 2.5).
formula_ingredient('幼鲈料', '豆粕', 16.0).
formula_ingredient('幼鲈料', '酵母提取物', 3.0).
formula_ingredient('幼鲈料', '膨化大豆', 6.0).
formula_ingredient('幼鲈料', '花生麸', 9.2).
formula_ingredient('幼鲈料', '大豆卵磷脂', 1.0).
formula_ingredient('幼鲈料', '鱼油', 3.5).
formula_ingredient('幼鲈料', '面粉', 24.0).
formula_ingredient('幼鲈料', '磷酸二氢钙', 1.0).
formula_ingredient('幼鲈料', '胆碱50', 0.3).
formula_ingredient('幼鲈料', 'VC酯35', 0.05).
formula_ingredient('幼鲈料', '食盐', 0.4).
formula_ingredient('幼鲈料', '防霉剂和抗氧化剂', 0.05).
formula_ingredient('幼鲈料', '次粉', 2.0).
formula_ingredient('幼鲈料', '预混料', 1.0).

formula_ingredient('成鲈料', '进口鱼粉', 18.0).
formula_ingredient('成鲈料', '国产鱼粉', 12.0).
formula_ingredient('成鲈料', '乌贼膏', 2.5).
formula_ingredient('成鲈料', '豆粕', 16.0).
formula_ingredient('成鲈料', '酵母提取物', 3.0).
formula_ingredient('成鲈料', '膨化大豆', 6.0).
formula_ingredient('成鲈料', '花生麸', 9.2).
formula_ingredient('成鲈料', '大豆卵磷脂', 1.0).
formula_ingredient('成鲈料', '鱼油', 3.5).
formula_ingredient('成鲈料', '面粉', 24.0).
formula_ingredient('成鲈料', '磷酸二氢钙', 1.0).
formula_ingredient('成鲈料', '胆碱50', 0.3).
formula_ingredient('成鲈料', 'VC酯35', 0.05).
formula_ingredient('成鲈料', '食盐', 0.4).
formula_ingredient('成鲈料', '防霉剂和抗氧化剂', 0.05).
formula_ingredient('成鲈料', '次粉', 2.0).
formula_ingredient('成鲈料', '预混料', 1.0).



% === formula_nutrition/3 ===

formula_nutrition('草鱼幼鱼料A', '粗蛋白', 37.5).
formula_nutrition('草鱼幼鱼料A', '粗脂肪', 7.6).
formula_nutrition('草鱼幼鱼料A', '赖氨酸', 2.4).
formula_nutrition('草鱼幼鱼料A', '蛋氨酸', 0.7).
formula_nutrition('草鱼幼鱼料A', '有效磷', 0.7).
formula_nutrition('草鱼幼鱼料A', '总能', 15.46).

formula_nutrition('草鱼幼鱼料B', '粗蛋白', 38.0).
formula_nutrition('草鱼幼鱼料B', '粗脂肪', 7.1).
formula_nutrition('草鱼幼鱼料B', '赖氨酸', 2.54).
formula_nutrition('草鱼幼鱼料B', '蛋氨酸', 0.83).
formula_nutrition('草鱼幼鱼料B', '有效磷', 0.7).
formula_nutrition('草鱼幼鱼料B', '总能', 15.36).

formula_nutrition('草鱼养成料A', '粗蛋白', 35.7).
formula_nutrition('草鱼养成料A', '粗脂肪', 8.2).
formula_nutrition('草鱼养成料A', '赖氨酸', 2.24).
formula_nutrition('草鱼养成料A', '蛋氨酸', 0.74).
formula_nutrition('草鱼养成料A', '有效磷', 0.7).
formula_nutrition('草鱼养成料A', '总能', 15.58).

formula_nutrition('草鱼养成料B', '粗蛋白', 32.31).
formula_nutrition('草鱼养成料B', '粗脂肪', 6.9).
formula_nutrition('草鱼养成料B', '赖氨酸', 2.1).
formula_nutrition('草鱼养成料B', '蛋氨酸', 0.66).
formula_nutrition('草鱼养成料B', '有效磷', 0.7).
formula_nutrition('草鱼养成料B', '总能', 15.32).

formula_nutrition('草鱼养成料C', '粗蛋白', 32.3).
formula_nutrition('草鱼养成料C', '粗脂肪', 6.85).
formula_nutrition('草鱼养成料C', '赖氨酸', 2.1).
formula_nutrition('草鱼养成料C', '蛋氨酸', 0.65).
formula_nutrition('草鱼养成料C', '有效磷', 0.7).
formula_nutrition('草鱼养成料C', '总能', 15.31).

formula_nutrition('鲤鲫鱼小鱼料', '粗蛋白', 35.0).
formula_nutrition('鲤鲫鱼小鱼料', '粗脂肪', 8.1).
formula_nutrition('鲤鲫鱼小鱼料', '有效磷', 0.68).
formula_nutrition('鲤鲫鱼小鱼料', '赖氨酸', 2.01).
formula_nutrition('鲤鲫鱼小鱼料', '蛋氨酸', 0.63).

formula_nutrition('鲤鲫鱼成鱼料', '粗蛋白', 33.0).
formula_nutrition('鲤鲫鱼成鱼料', '粗脂肪', 7.63).
formula_nutrition('鲤鲫鱼成鱼料', '有效磷', 0.65).
formula_nutrition('鲤鲫鱼成鱼料', '赖氨酸', 1.84).
formula_nutrition('鲤鲫鱼成鱼料', '蛋氨酸', 0.57).

formula_nutrition('鲤草鱼混养前期料', '粗蛋白', 32.0).
formula_nutrition('鲤草鱼混养前期料', '粗脂肪', 6.39).
formula_nutrition('鲤草鱼混养前期料', '有效磷', 0.63).
formula_nutrition('鲤草鱼混养前期料', '赖氨酸', 1.73).
formula_nutrition('鲤草鱼混养前期料', '蛋氨酸', 0.56).

formula_nutrition('鲤草鱼混养后期料', '粗蛋白', 30.0).
formula_nutrition('鲤草鱼混养后期料', '粗脂肪', 5.81).
formula_nutrition('鲤草鱼混养后期料', '有效磷', 0.61).
formula_nutrition('鲤草鱼混养后期料', '赖氨酸', 1.56).
formula_nutrition('鲤草鱼混养后期料', '蛋氨酸', 0.51).

formula_nutrition('淡水鱼鱼苗料', '粗蛋白', 32.0).
formula_nutrition('淡水鱼鱼苗料', '粗脂肪', 5.3).
formula_nutrition('淡水鱼鱼苗料', '有效磷', 0.64).
formula_nutrition('淡水鱼鱼苗料', '赖氨酸', 1.69).
formula_nutrition('淡水鱼鱼苗料', '蛋氨酸', 0.51).

formula_nutrition('淡水鱼幼鱼料A', '粗蛋白', 32.03).
formula_nutrition('淡水鱼幼鱼料A', '粗脂肪', 5.81).
formula_nutrition('淡水鱼幼鱼料A', '有效磷', 0.67).
formula_nutrition('淡水鱼幼鱼料A', '赖氨酸', 1.69).
formula_nutrition('淡水鱼幼鱼料A', '蛋氨酸', 0.52).

formula_nutrition('鲂鱼苗种料', '粗蛋白', 32.01).
formula_nutrition('鲂鱼苗种料', '粗脂肪', 5.84).
formula_nutrition('鲂鱼苗种料', '有效磷', 0.68).
formula_nutrition('鲂鱼苗种料', '赖氨酸', 1.71).
formula_nutrition('鲂鱼苗种料', '蛋氨酸', 0.53).

formula_nutrition('鲂鱼养成料', '粗蛋白', 30.01).
formula_nutrition('鲂鱼养成料', '粗脂肪', 6.99).
formula_nutrition('鲂鱼养成料', '有效磷', 0.61).
formula_nutrition('鲂鱼养成料', '赖氨酸', 1.6).
formula_nutrition('鲂鱼养成料', '蛋氨酸', 0.49).

formula_nutrition('鳊鱼鱼苗料', '粗蛋白', 30.0).
formula_nutrition('鳊鱼鱼苗料', '粗脂肪', 5.55).
formula_nutrition('鳊鱼鱼苗料', '有效磷', 0.61).
formula_nutrition('鳊鱼鱼苗料', '赖氨酸', 1.56).
formula_nutrition('鳊鱼鱼苗料', '蛋氨酸', 0.5).

formula_nutrition('鳊鱼养成料', '粗蛋白', 28.0).
formula_nutrition('鳊鱼养成料', '粗脂肪', 5.39).
formula_nutrition('鳊鱼养成料', '有效磷', 0.58).
formula_nutrition('鳊鱼养成料', '赖氨酸', 1.43).
formula_nutrition('鳊鱼养成料', '蛋氨酸', 0.47).

formula_nutrition('白仔鳗料', '粗蛋白', 47.58).
formula_nutrition('白仔鳗料', '粗脂肪', 5.08).
formula_nutrition('白仔鳗料', '赖氨酸', 3.68).
formula_nutrition('白仔鳗料', '蛋氨酸', 1.12).
formula_nutrition('白仔鳗料', '有效磷', 0.9).
formula_nutrition('白仔鳗料', '总能', 14.96).

formula_nutrition('黑仔鳗料', '粗蛋白', 47.54).
formula_nutrition('黑仔鳗料', '粗脂肪', 5.14).
formula_nutrition('黑仔鳗料', '赖氨酸', 3.64).
formula_nutrition('黑仔鳗料', '蛋氨酸', 1.11).
formula_nutrition('黑仔鳗料', '有效磷', 0.9).

formula_nutrition('幼鳗料', '粗蛋白', 46.88).
formula_nutrition('幼鳗料', '粗脂肪', 4.98).
formula_nutrition('幼鳗料', '赖氨酸', 3.57).
formula_nutrition('幼鳗料', '蛋氨酸', 1.09).
formula_nutrition('幼鳗料', '有效磷', 0.9).

formula_nutrition('养成鳗料', '粗蛋白', 46.88).
formula_nutrition('养成鳗料', '粗脂肪', 4.98).
formula_nutrition('养成鳗料', '赖氨酸', 3.57).
formula_nutrition('养成鳗料', '蛋氨酸', 1.09).
formula_nutrition('养成鳗料', '有效磷', 0.9).



% === formula_meta/3 ===

formula_meta('草鱼幼鱼料A', '物种', '草鱼').
formula_meta('草鱼幼鱼料A', '阶段', '幼鱼').
formula_meta('草鱼幼鱼料A', '来源', '薛敏_附录_p127').

% 配方2: 草鱼幼鱼料 (双低菜粕型)
formula_meta('草鱼幼鱼料B', '物种', '草鱼').
formula_meta('草鱼幼鱼料B', '阶段', '幼鱼').
formula_meta('草鱼幼鱼料B', '来源', '薛敏_附录_p127').

% 配方3: 草鱼养成料A (高棉粕型)
formula_meta('草鱼养成料A', '物种', '草鱼').
formula_meta('草鱼养成料A', '阶段', '养成').
formula_meta('草鱼养成料A', '来源', '薛敏_附录_p127').

% 配方4: 草鱼养成料B (低鱼粉高棉粕型)
formula_meta('草鱼养成料B', '物种', '草鱼').
formula_meta('草鱼养成料B', '阶段', '养成').
formula_meta('草鱼养成料B', '来源', '薛敏_附录_p127').

% 配方5: 草鱼养成料C (无鱼粉型)
formula_meta('草鱼养成料C', '物种', '草鱼').
formula_meta('草鱼养成料C', '阶段', '养成').
formula_meta('草鱼养成料C', '来源', '薛敏_附录_p127').

%%------------------------------------------------------------------------------
%% 鲤鲫鱼/鲤草鱼混养配方 — 附录 p128
%%------------------------------------------------------------------------------

% 鲤鲫鱼小鱼料
formula_meta('鲤鲫鱼小鱼料', '物种', '鲤鲫鱼').
formula_meta('鲤鲫鱼小鱼料', '阶段', '小鱼').
formula_meta('鲤鲫鱼小鱼料', '来源', '薛敏_附录_p128').

% 鲤鲫鱼成鱼料
formula_meta('鲤鲫鱼成鱼料', '物种', '鲤鲫鱼').
formula_meta('鲤鲫鱼成鱼料', '阶段', '成鱼').
formula_meta('鲤鲫鱼成鱼料', '来源', '薛敏_附录_p128').

% 鲤草鱼混养料前期
formula_meta('鲤草鱼混养前期料', '物种', '鲤草鱼混养').
formula_meta('鲤草鱼混养前期料', '阶段', '前期').
formula_meta('鲤草鱼混养前期料', '来源', '薛敏_附录_p128').

% 鲤草鱼混养后期料
formula_meta('鲤草鱼混养后期料', '物种', '鲤草鱼混养').
formula_meta('鲤草鱼混养后期料', '阶段', '后期').
formula_meta('鲤草鱼混养后期料', '来源', '薛敏_附录_p128').

%%------------------------------------------------------------------------------
%% 淡水鱼通用配方 (罗非鱼/杂食性鱼类) — 附录 p129
%%------------------------------------------------------------------------------

% 淡水鱼鱼苗料
formula_meta('淡水鱼鱼苗料', '物种', '淡水鱼通用').
formula_meta('淡水鱼鱼苗料', '阶段', '鱼苗').
formula_meta('淡水鱼鱼苗料', '来源', '薛敏_附录_p129').

% 淡水鱼幼鱼料A
formula_meta('淡水鱼幼鱼料A', '物种', '淡水鱼通用').
formula_meta('淡水鱼幼鱼料A', '阶段', '幼鱼').
formula_meta('淡水鱼幼鱼料A', '来源', '薛敏_附录_p129').

%%------------------------------------------------------------------------------
%% 鲂鱼/鳊鱼配方 — 附录 p129-130
%%------------------------------------------------------------------------------

% 鲂鱼苗种料
formula_meta('鲂鱼苗种料', '物种', '鲂鱼').
formula_meta('鲂鱼苗种料', '阶段', '苗种').
formula_meta('鲂鱼苗种料', '来源', '薛敏_附录_p129').

% 鲂鱼养成料
formula_meta('鲂鱼养成料', '物种', '鲂鱼').
formula_meta('鲂鱼养成料', '阶段', '养成').
formula_meta('鲂鱼养成料', '来源', '薛敏_附录_p130').

% 鳊鱼鱼苗料
formula_meta('鳊鱼鱼苗料', '物种', '鳊鱼').
formula_meta('鳊鱼鱼苗料', '阶段', '鱼苗').
formula_meta('鳊鱼鱼苗料', '来源', '薛敏_附录_p130').

% 鳊鱼养成料
formula_meta('鳊鱼养成料', '物种', '鳊鱼').
formula_meta('鳊鱼养成料', '阶段', '养成').
formula_meta('鳊鱼养成料', '来源', '薛敏_附录_p130').

%%------------------------------------------------------------------------------
%% 鳗鱼配方 — 附录 p131-133
%%------------------------------------------------------------------------------

% 白仔鳗料
formula_meta('白仔鳗料', '物种', '鳗鱼').
formula_meta('白仔鳗料', '阶段', '白仔鳗_小于2g').
formula_meta('白仔鳗料', '来源', '薛敏_附录_p132').

% 黑仔鳗料
formula_meta('黑仔鳗料', '物种', '鳗鱼').
formula_meta('黑仔鳗料', '阶段', '黑仔鳗_2至10g').
formula_meta('黑仔鳗料', '来源', '薛敏_附录_p132').

% 幼鳗料
formula_meta('幼鳗料', '物种', '鳗鱼').
formula_meta('幼鳗料', '阶段', '幼鳗_10至50g').
formula_meta('幼鳗料', '来源', '薛敏_附录_p132').

% 养成鳗料
formula_meta('养成鳗料', '物种', '鳗鱼').
formula_meta('养成鳗料', '阶段', '养成_大于50g').
formula_meta('养成鳗料', '来源', '薛敏_附录_p132').

%%------------------------------------------------------------------------------
%% 鲈鱼配方 — 附录 p133
%%------------------------------------------------------------------------------

% 鲈鱼苗料
formula_meta('鲈鱼苗料', '物种', '鲈鱼').
formula_meta('鲈鱼苗料', '阶段', '鲈苗_小于50g').
formula_meta('鲈鱼苗料', '来源', '薛敏_附录_p133').

% 幼鲈料
formula_meta('幼鲈料', '物种', '鲈鱼').
formula_meta('幼鲈料', '阶段', '幼鲈_50至200g').
formula_meta('幼鲈料', '来源', '薛敏_附录_p133').

% 成鲈料
formula_meta('成鲈料', '物种', '鲈鱼').
formula_meta('成鲈料', '阶段', '养成_大于200g').
formula_meta('成鲈料', '来源', '薛敏_附录_p133').

%%==============================================================================
%% 配方分类汇总
%%==============================================================================

% 所有配方名称列表


% === formula_by_species/3 ===

formula_by_species('草鱼', ['草鱼幼鱼料A', '草鱼幼鱼料B', '草鱼养成料A', '草鱼养成料B', '草鱼养成料C']).
formula_by_species('鲤鲫鱼', ['鲤鲫鱼小鱼料', '鲤鲫鱼成鱼料']).
formula_by_species('鲤草鱼混养', ['鲤草鱼混养前期料', '鲤草鱼混养后期料']).
formula_by_species('淡水鱼通用', ['淡水鱼鱼苗料', '淡水鱼幼鱼料A']).
formula_by_species('鲂鱼', ['鲂鱼苗种料', '鲂鱼养成料']).
formula_by_species('鳊鱼', ['鳊鱼鱼苗料', '鳊鱼养成料']).
formula_by_species('鳗鱼', ['白仔鳗料', '黑仔鳗料', '幼鳗料', '养成鳗料']).
formula_by_species('鲈鱼', ['鲈鱼苗料', '幼鲈料', '成鲈料']).


% === formula_list/2 ===

formula_list(['草鱼幼鱼料A', '草鱼幼鱼料B', '草鱼养成料A', '草鱼养成料B', '草鱼养成料C',
              '鲤鲫鱼小鱼料', '鲤鲫鱼成鱼料', '鲤草鱼混养前期料', '鲤草鱼混养后期料',
              '淡水鱼鱼苗料', '淡水鱼幼鱼料A',
              '鲂鱼苗种料', '鲂鱼养成料', '鳊鱼鱼苗料', '鳊鱼养成料',
              '白仔鳗料', '黑仔鳗料', '幼鳗料', '养成鳗料',
              '鲈鱼苗料', '幼鲈料', '成鲈料']).

% 按物种查询配方

