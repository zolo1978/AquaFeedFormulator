#!/bin/bash
# ============================================================
# validate.sh — AquaFeedFormulator 统一校验入口
# 用法: ./validate.sh [配方文件]          # 校验指定配方
#       ./validate.sh --smoke             # 仅冒烟测试
#       ./validate.sh --all               # 全量校验
# ============================================================

set -e
SCYPER="/Users/weifengchen/.cargo/bin/scryer-prolog"
RULES="rules/ingredient_db.pl rules/species_nutrition.pl rules/formula_closure_validator.pl rules/functional_additive_checker.pl rules/cross_species_consistency.pl rules/nutrition_calculator.pl"
REPORT_FILE=""

green()  { printf '\033[32m%s\033[0m\n' "$*"; }
red()    { printf '\033[31m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }

run_smoke() {
    green "=== 1/3 物种一致性冒烟 ==="
    $SCYPER $RULES -g "run_smoke" -g halt 2>&1 | grep -v "^%" | grep -v "Warning"
    echo
}

run_closure() {
    local recipe_file=$1
    local test_pred=${2:-"validate_all"}
    green "=== 2/3 闭合+品类校验 ($recipe_file) ==="
    $SCYPER $RULES "$recipe_file" \
        -g "$test_pred, write('ALL_CHECKS_DONE'), nl" -g halt 2>&1 \
        | grep -v "^%" | grep -v "Warning"
    echo
}

run_nutrition() {
    local recipe_file=$1
    local test_pred=${2:-"validate_nutrition_all"}
    green "=== 3/3 营养值校验 ($recipe_file) ==="
    $SCYPER $RULES "$recipe_file" \
        -g "$test_pred, write('NUTRITION_CHECKS_DONE'), nl" -g halt 2>&1 \
        | grep -v "^%" | grep -v "Warning"
    echo
}

case "${1:-}" in
    --smoke)
        run_smoke
        green "冒烟测试完成"
        ;;
    --all)
        run_smoke
        # 全量校验所有配方
        for f in rules/shrimp_recipes.pl rules/eel_recipes.pl; do
            if [ -f "$f" ]; then
                run_closure "$f"
                run_nutrition "$f"
            fi
        done
        green "全量校验完成"
        ;;
    *)
        # 默认: smoke + 指定配方校验
        run_smoke
        if [ -n "$1" ]; then
            run_closure "$1"
            run_nutrition "$1"
        fi
        green "校验完成"
        ;;
esac
