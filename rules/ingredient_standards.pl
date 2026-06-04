%%==============================================================================
%% AquaFeedFormulator — 原料质量标准知识库
%% 来源: 《水产动物饲料配方与配制技术》(张家国)
%% 数据: 中国饲料用原料国家标准 (GB/T)
%% 注意: scryer-prolog v0.10 无需 discontiguous 声明即可正常加载。
%%==============================================================================

% scryer-prolog v0.10 不提供 member/2，自定义实现

%%------------------------------------------------------------------------------
%% 植物蛋白原料 — 国家标准等级
%%------------------------------------------------------------------------------

% 饲料用大豆饼 (GB/T 标准)
my_member(X, [X|_]).
my_member(X, [_|T]) :- my_member(X, T).

% === check_all_specs ===

check_all_specs([], _).
check_all_specs([ingredient_nutrient(Nut, min, Min)|Rest], Measured) :-
    my_member(nutrient(Nut, Value), Measured),
    Value >= Min,
    check_all_specs(Rest, Measured).
check_all_specs([ingredient_nutrient(Nut, max, Max)|Rest], Measured) :-
    my_member(nutrient(Nut, Value), Measured),
    Value =< Max,
    check_all_specs(Rest, Measured).


% === ingredient_attribute ===

ingredient_attribute('棉籽饼', '粗蛋白典型值', '去壳较彻底(残油3-5%): ≥40%; 带壳榨油: 27-33%').
ingredient_attribute('棉籽饼', '蛋白质消化率', '一般≥80%; 草鱼消化率83%').
ingredient_attribute('棉籽饼', '限制氨基酸', '赖氨酸').
ingredient_attribute('棉籽饼', '优势氨基酸', '精氨酸, 苯丙氨酸').
ingredient_attribute('棉籽饼', '抗营养因子', '游离棉酚').
ingredient_attribute('花生饼', '粗蛋白典型值', '第一种(有香味): ~45%; 第二种(无香味): 48-50%; 带壳: 26-28%').
ingredient_attribute('花生饼', '品质鉴别', '压榨法产品优于浸出粕; 第一种有花生米香味').
ingredient_attribute('花生饼', '限制氨基酸', '赖氨酸, 蛋氨酸').
ingredient_attribute('花生饼', '风险', '易感染黄曲霉毒素').


% === ingredient_grade ===

ingredient_grade('大豆饼', 1, [
    ingredient_nutrient('粗蛋白', min, 41.0),
    ingredient_nutrient('粗脂肪', max, 8.0),
    ingredient_nutrient('粗纤维', max, 5.0),
    ingredient_nutrient('粗灰分', max, 6.0)
]).
ingredient_grade('大豆饼', 2, [
    ingredient_nutrient('粗蛋白', min, 39.0),
    ingredient_nutrient('粗脂肪', max, 8.0),
    ingredient_nutrient('粗纤维', max, 6.0),
    ingredient_nutrient('粗灰分', max, 7.0)
]).
ingredient_grade('大豆饼', 3, [
    ingredient_nutrient('粗蛋白', min, 37.0),
    ingredient_nutrient('粗脂肪', max, 8.0),
    ingredient_nutrient('粗纤维', max, 7.0),
    ingredient_nutrient('粗灰分', max, 8.0)
]).
ingredient_grade('大豆粕', 1, [
    ingredient_nutrient('粗蛋白', min, 44.0),
    ingredient_nutrient('粗纤维', max, 5.0),
    ingredient_nutrient('粗灰分', max, 6.0)
]).
ingredient_grade('大豆粕', 2, [
    ingredient_nutrient('粗蛋白', min, 42.0),
    ingredient_nutrient('粗纤维', max, 6.0),
    ingredient_nutrient('粗灰分', max, 7.0)
]).
ingredient_grade('大豆粕', 3, [
    ingredient_nutrient('粗蛋白', min, 40.0),
    ingredient_nutrient('粗纤维', max, 7.0),
    ingredient_nutrient('粗灰分', max, 8.0)
]).
ingredient_grade('菜籽饼', 1, [
    ingredient_nutrient('粗蛋白', min, 37.0),
    ingredient_nutrient('粗脂肪', max, 10.0),
    ingredient_nutrient('粗纤维', max, 14.0),
    ingredient_nutrient('粗灰分', max, 12.0)
]).
ingredient_grade('菜籽饼', 2, [
    ingredient_nutrient('粗蛋白', min, 34.0),
    ingredient_nutrient('粗脂肪', max, 10.0),
    ingredient_nutrient('粗纤维', max, 14.0),
    ingredient_nutrient('粗灰分', max, 12.0)
]).
ingredient_grade('菜籽饼', 3, [
    ingredient_nutrient('粗蛋白', min, 30.0),
    ingredient_nutrient('粗脂肪', max, 10.0),
    ingredient_nutrient('粗纤维', max, 14.0),
    ingredient_nutrient('粗灰分', max, 12.0)
]).
ingredient_grade('菜籽粕', 1, [
    ingredient_nutrient('粗蛋白', min, 40.0),
    ingredient_nutrient('粗纤维', max, 14.0),
    ingredient_nutrient('粗灰分', max, 8.0)
]).
ingredient_grade('菜籽粕', 2, [
    ingredient_nutrient('粗蛋白', min, 37.0),
    ingredient_nutrient('粗纤维', max, 14.0),
    ingredient_nutrient('粗灰分', max, 8.0)
]).
ingredient_grade('菜籽粕', 3, [
    ingredient_nutrient('粗蛋白', min, 33.0),
    ingredient_nutrient('粗纤维', max, 14.0),
    ingredient_nutrient('粗灰分', max, 8.0)
]).
ingredient_grade('向日葵仁饼', 1, [
    ingredient_nutrient('粗蛋白', min, 36.0),
    ingredient_nutrient('粗纤维', max, 15.0),
    ingredient_nutrient('粗灰分', max, 9.0)
]).
ingredient_grade('向日葵仁饼', 2, [
    ingredient_nutrient('粗蛋白', min, 30.0),
    ingredient_nutrient('粗纤维', max, 21.0),
    ingredient_nutrient('粗灰分', max, 9.0)
]).
ingredient_grade('向日葵仁饼', 3, [
    ingredient_nutrient('粗蛋白', min, 23.0),
    ingredient_nutrient('粗纤维', max, 27.0),
    ingredient_nutrient('粗灰分', max, 9.0)
]).
ingredient_grade('向日葵仁粕', 1, [
    ingredient_nutrient('粗蛋白', min, 38.0),
    ingredient_nutrient('粗纤维', max, 16.0),
    ingredient_nutrient('粗灰分', max, 10.0)
]).
ingredient_grade('向日葵仁粕', 2, [
    ingredient_nutrient('粗蛋白', min, 32.0),
    ingredient_nutrient('粗纤维', max, 22.0),
    ingredient_nutrient('粗灰分', max, 10.0)
]).
ingredient_grade('向日葵仁粕', 3, [
    ingredient_nutrient('粗蛋白', min, 24.0),
    ingredient_nutrient('粗纤维', max, 28.0),
    ingredient_nutrient('粗灰分', max, 10.0)
]).
ingredient_grade('肉粉', 1, [
    ingredient_nutrient('粗蛋白', min, 64.0),
    ingredient_nutrient('粗脂肪', max, 12.0),
    ingredient_nutrient('粗灰分', max, 12.0)
]).
ingredient_grade('肉粉', 2, [
    ingredient_nutrient('粗蛋白', min, 54.0),
    ingredient_nutrient('粗脂肪', max, 18.0),
    ingredient_nutrient('粗灰分', max, 14.0)
]).
ingredient_grade('肉粉', 3, [
    ingredient_nutrient('粗蛋白', min, 45.0),
    ingredient_nutrient('粗脂肪', max, 20.0),
    ingredient_nutrient('粗灰分', max, 20.0)
]).
ingredient_grade('肉骨粉', 1, [
    ingredient_nutrient('粗蛋白', min, 50.0),
    ingredient_nutrient('粗脂肪', max, 9.0),
    ingredient_nutrient('粗灰分', max, 23.0)
]).
ingredient_grade('肉骨粉', 2, [
    ingredient_nutrient('粗蛋白', min, 42.0),
    ingredient_nutrient('粗脂肪', max, 16.0),
    ingredient_nutrient('粗灰分', max, 30.0)
]).
ingredient_grade('肉骨粉', 3, [
    ingredient_nutrient('粗蛋白', min, 30.0),
    ingredient_nutrient('粗脂肪', max, 18.0),
    ingredient_nutrient('粗灰分', max, 40.0)
]).


% === ingredient_meets_grade ===

ingredient_meets_grade(Name, Grade, Measured) :-
    ingredient_grade(Name, Grade, Specs),
    check_all_specs(Specs, Measured).



% === ingredient_meta ===

ingredient_meta('大豆饼', '干物质基础', 87.0).
ingredient_meta('大豆饼', '标准', 'GB/T').

% 饲料用大豆粕 (GB/T 标准)
ingredient_meta('大豆粕', '干物质基础', 87.0).
ingredient_meta('大豆粕', '标准', 'GB/T').

% 饲料用棉籽饼(粕)
ingredient_meta('棉籽饼', '来源', '张家国_B1_p25').

% 饲料用菜籽饼 (GB/T 标准)
ingredient_meta('菜籽饼', '干物质基础', 88.0).
ingredient_meta('菜籽饼', '标准', 'GB/T').

% 饲料用菜籽粕 (GB/T 标准)
ingredient_meta('菜籽粕', '干物质基础', 88.0).
ingredient_meta('菜籽粕', '标准', 'GB/T').

% 花生饼
ingredient_meta('花生饼', '来源', '张家国_B1_p28').

% 饲料用向日葵仁饼 (GB/T 标准)
ingredient_meta('向日葵仁饼', '干物质基础', 88.0).
ingredient_meta('向日葵仁饼', '标准', 'GB/T').

% 饲料用向日葵仁粕 (GB/T 标准)
ingredient_meta('向日葵仁粕', '干物质基础', 88.0).
ingredient_meta('向日葵仁粕', '标准', 'GB/T').

%%------------------------------------------------------------------------------
%% 动物蛋白原料 — 国家标准等级
%%------------------------------------------------------------------------------

% 肉粉 (GB/T 标准)
ingredient_meta('肉粉', '注意', '原料质量不稳定，营养成分差异较大').
ingredient_meta('肉粉', '来源', '张家国_B1_p34').

% 肉骨粉 (GB/T 标准)
ingredient_meta('肉骨粉', '注意', '原料质量不稳定，营养成分差异较大').
ingredient_meta('肉骨粉', '来源', '张家国_B1_p34').

%%==============================================================================
%% 原料查询接口
%%==============================================================================

% 获取某原料某等级的质量标准
% ingredient_spec(+原料名, +等级, -规格列表)


% === ingredient_min_protein ===

ingredient_min_protein(Name, Grade, Protein) :-
    ingredient_grade(Name, Grade, Specs),
    my_member(ingredient_nutrient('粗蛋白', min, Protein), Specs).

% 检查原料是否符合某等级
% ingredient_meets_grade(+原料名, +等级, +实测营养列表)


% === ingredient_spec ===

ingredient_spec(Name, Grade, Specs) :-
    ingredient_grade(Name, Grade, Specs).

% 获取原料的最低蛋白要求
% ingredient_min_protein(+原料名, +等级, -蛋白%)

