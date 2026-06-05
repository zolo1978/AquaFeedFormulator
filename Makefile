# AquaFeedFormulator Makefile
# 用法:
#   make solve SPECIES=japanese_eel STAGE=adult    # 单物种求解
#   make solve-all                                 # 全部 5 种品类物种
#   make test                                      # 反例测试
#   make gate PROJECT=production                   # 交付门禁
#   make build                                     # 编译 release
#   make clean                                     # 清理
#   make price-monitor                             # 原料价格监控
#   make prolog-solve SPECIES=japanese_eel STAGE=adult  # 纯 Prolog（跳过 Rust）

.DEFAULT_GOAL := help

CARGO := cd rust-core && cargo
PROLOG := scryer-prolog
SPECIES ?= japanese_eel
STAGE ?= adult
PROJECT ?= production

# ── 主要目标 ────────────────────────────────────────────

.PHONY: help
help:
	@echo "AquaFeedFormulator — LLM+Prolog+Rust 水产饲料研发 SOP Agent"
	@echo ""
	@echo "用法:"
	@echo "  make solve SPECIES=<物种> STAGE=<阶段>   端到端求解 (默认: japanese_eel adult)"
	@echo "  make solve-all                           批量求解全部 5 种品类物种"
	@echo "  make test                                运行反例测试"
	@echo "  make gate                                交付门禁验证"
	@echo "  make build                               编译 Rust release 二进制"
	@echo "  make clean                               清理构建产物"
	@echo "  make price-monitor                       原料价格监控"
	@echo "  make prolog-solve SPECIES=<物种>         纯 Prolog 求解 (跳过 Rust)"
	@echo ""
	@echo "示例:"
	@echo "  make solve SPECIES=white_shrimp STAGE=adult"
	@echo "  make prolog-solve SPECIES=japanese_eel"
	@echo "  make solve-all"

.PHONY: solve
solve:
	@echo "=== 求解: $(SPECIES) $(STAGE) ==="
	$(CARGO) run -- solve --species $(SPECIES) --stage $(STAGE) --project $(PROJECT)

.PHONY: solve-all
solve-all:
	@for sp in japanese_eel white_shrimp common_carp largemouth_bass grass_carp; do \
		echo ""; \
		echo "═══════════════════════════════════"; \
		echo "  求解: $$sp adult"; \
		echo "═══════════════════════════════════"; \
		$(CARGO) run -- solve --species $$sp --stage adult --project production || true; \
	done
	@echo ""
	@echo "=== 全部 5 种求解完成 ==="
	@echo "结果: generated/"

.PHONY: test
test:
	@echo "=== 反例测试 ==="
	$(CARGO) run -- test

.PHONY: gate
gate:
	@echo "=== 交付门禁: $(PROJECT) ==="
	$(CARGO) run -- gate --project $(PROJECT)

.PHONY: build
build:
	$(CARGO) build --release
	@echo "二进制: rust-core/target/release/aqua"

.PHONY: clean
clean:
	$(CARGO) clean
	rm -rf generated/*
	@echo "清理完成"

# ── 纯 Prolog (跳过 Rust CLI) ──────────────────────────

.PHONY: prolog-solve
prolog-solve:
	@echo "=== Prolog 求解: $(SPECIES) $(STAGE) ==="
	$(PROLOG) -g "\
		consult('rules/ingredient_db.pl'),\
		consult('rules/species_nutrition.pl'),\
		consult('rules/category_rules.pl'),\
		consult('rules/sop_gatekeeper.pl'),\
		consult('rules/formulation_lp_engine.pl'),\
		consult('rules/delivery_gatekeeper.pl'),\
		consult('rules/sop_engine.pl'),\
		solve_formulation($(SPECIES), $(STAGE)),\
		halt."

# ── 价格监控 ────────────────────────────────────────────

.PHONY: price-monitor
price-monitor:
	@echo "=== 原料价格监控 ==="
	python3 scripts/price_monitor.py --json
	@echo "结果: generated/price_monitor/"

# ── DOCX 报告 (独立调用) ────────────────────────────────

.PHONY: report
report:
	@echo "=== 生成 DOCX 报告: $(SPECIES) $(STAGE) ==="
	@if [ "$(SPECIES)" = "japanese_eel" ]; then \
		python3 generate_eel_adult_report.py; \
	else \
		python3 generate_report.py generated/recipe_data.json; \
	fi
	@echo "报告: ~/Desktop/"
