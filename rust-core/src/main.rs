// AquaFeedFormulator Rust CLI — P0.5 工程闭环（终审整改版）
//
// 命令:
//   aqua solve --species japanese_eel --stage adult --project production
//
// 调用链:
//   1. Rust 注入 project_state fact → Prolog
//   2. Rust → scryer-prolog can_execute(Project, solve(Species, Stage))
//   3. Rust → scryer-prolog solve_formulation(Species, Stage)
//   4. Rust → scryer-prolog deliverable(Recipe, Species, Stage, Decision)
//   5. Rust → 输出 validation_result.json / delivery_decision.json / execution_log.json
//
// 核心原则: Rust 管状态，Prolog 管判断。每次调用 Prolog 时注入当前 state fact。

use clap::{Parser, Subcommand};
use chrono::Utc;
use serde::{Deserialize, Serialize};
use std::fs;
use std::process::Command;
use std::path::PathBuf;

#[derive(Parser)]
#[command(name = "aqua")]
#[command(about = "AquaFeedFormulator CLI — LLM+Prolog+Rust 水产饲料研发 SOP Agent")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// 配方求解 (完整工程闭环)
    Solve {
        #[arg(long)]
        species: String,
        #[arg(long)]
        stage: String,
        #[arg(long, default_value = "production")]
        project: String,
    },
    /// 运行反例测试
    Test {},
    /// 交付门禁验证
    Gate {
        #[arg(long)]
        project: String,
    },
}

fn main() {
    let cli = Cli::parse();
    match cli.command {
        Commands::Solve { species, stage, project } => {
            solve(&project, &species, &stage);
        }
        Commands::Test {} => {
            run_counterexample_tests();
        }
        Commands::Gate { project } => {
            run_delivery_gate(&project);
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// Prolog 执行引擎
// ═══════════════════════════════════════════════════════════════

fn scryer_prolog_path() -> &'static str {
    "/opt/homebrew/bin/scryer-prolog"
}

fn project_root() -> PathBuf {
    let mut p = std::env::current_dir().unwrap();
    if p.ends_with("rust-core") {
        p.pop();
    }
    p
}

/// 执行 Prolog 查询，自动 assemble consult block。
/// state_facts: Rust 注入的动态 fact（如 project_state/2）。
fn run_prolog(query: &str, state_facts: &[&str]) -> std::process::Output {
    let facts_block = state_facts.join(",\n");
    let consult_block = if facts_block.is_empty() {
        format!(
            "consult('rules/ingredient_db.pl'),\
             consult('rules/species_nutrition.pl'),\
             consult('rules/category_rules.pl'),\
             consult('rules/sop_gatekeeper.pl'),\
             consult('rules/formulation_lp_engine.pl'),\
             consult('rules/delivery_gatekeeper.pl'),\
             consult('rules/sop_engine.pl'),\
             {}, halt.",
            query
        )
    } else {
        format!(
            "assertz(({})),\
             consult('rules/ingredient_db.pl'),\
             consult('rules/species_nutrition.pl'),\
             consult('rules/category_rules.pl'),\
             consult('rules/sop_gatekeeper.pl'),\
             consult('rules/formulation_lp_engine.pl'),\
             consult('rules/delivery_gatekeeper.pl'),\
             consult('rules/sop_engine.pl'),\
             {}, halt.",
            facts_block, query
        )
    };

    Command::new(scryer_prolog_path())
        .args(["-g", &consult_block])
        .current_dir(project_root())
        .output()
        .expect("scryer-prolog not found or failed")
}

/// 运行 Prolog 查询并返回成功与否 + stdout
fn run_prolog_bool(query: &str, state_facts: &[&str]) -> (bool, String) {
    let out = run_prolog(query, state_facts);
    let stdout = String::from_utf8_lossy(&out.stdout).to_string();
    let stderr = String::from_utf8_lossy(&out.stderr).to_string();
    (out.status.success(), format!("{}{}", stdout, stderr))
}

// ═══════════════════════════════════════════════════════════════
// 求解流程 (完整闭环)
// ═══════════════════════════════════════════════════════════════

fn solve(project: &str, species: &str, stage: &str) {
    let started_at = Utc::now();
    let mut steps: Vec<ExecutionStep> = Vec::new();
    let state_facts = vec![format!("project_state({}, solving)", project).as_str()];

    println!("=== AquaFeedFormulator ===");
    println!("项目: {} | 物种: {} | 阶段: {}", project, species, stage);
    println!();

    // ── Step 1: can_execute 门禁 ──────────────────────────
    println!("[1/3] can_execute 门禁检查...");
    let q1 = format!("can_execute({}, solve({}, {})).", project, species, stage);
    let (ok1, out1) = run_prolog_bool(&q1, &state_facts);

    steps.push(ExecutionStep {
        seq: 1,
        action: "can_execute".into(),
        prolog_call: q1,
        result: if ok1 { "allow".into() } else { "block".into() },
        timestamp: Utc::now().to_rfc3339(),
    });

    if !ok1 {
        eprintln!("[BLOCKED] can_execute 拒绝执行");
        eprintln!("{}", out1);
        write_execution_log(project, &steps, &started_at, 1);
        return;
    }
    println!("  ✅ can_execute: allow");

    // ── Step 2: LP 求解 ───────────────────────────────────
    println!("[2/3] LP 配方求解...");
    let q2 = format!("solve_formulation({}, {}).", species, stage);
    let (ok2, out2) = run_prolog_bool(&q2, &state_facts);

    steps.push(ExecutionStep {
        seq: 2,
        action: "solve_formulation".into(),
        prolog_call: q2,
        result: if ok2 && !out2.contains("infeasible") { "solved".into() } else { "infeasible".into() },
        timestamp: Utc::now().to_rfc3339(),
    });

    if !ok2 || out2.contains("infeasible") {
        let result = ValidationResult {
            project_id: project.to_string(),
            timestamp: Utc::now().to_rfc3339(),
            species: species.to_string(),
            stage: stage.to_string(),
            solution: SolutionResult::Infeasible {
                reason: "营养目标与品类约束冲突".into(),
            },
        };
        write_json("validation_result.json", &result);
        eprintln!("[INFEASIBLE] 约束冲突，无法求解");
        write_execution_log(project, &steps, &started_at, 2);
        return;
    }
    println!("  ✅ LP 求解完成");

    // ── Step 3: delivery_gatekeeper ───────────────────────
    println!("[3/3] 交付门禁...");
    let q3 = format!(
        "findall(D, deliverable(_, {}, {}, D), Decisions), write(Decisions).",
        species, stage
    );
    let (ok3, out3) = run_prolog_bool(&q3, &state_facts);

    let deliverable = ok3 && out3.contains("passed");
    steps.push(ExecutionStep {
        seq: 3,
        action: "delivery_gatekeeper".into(),
        prolog_call: q3,
        result: if deliverable { "passed".into() } else { "failed".into() },
        timestamp: Utc::now().to_rfc3339(),
    });

    // ── 输出 JSON ─────────────────────────────────────────

    let completed_at = Utc::now();

    // validation_result.json
    let validation = ValidationResult {
        project_id: project.to_string(),
        timestamp: completed_at.to_rfc3339(),
        species: species.to_string(),
        stage: stage.to_string(),
        solution: SolutionResult::Solved {
            status: "solved".into(),
        },
    };
    write_json("validation_result.json", &validation);

    // delivery_decision.json
    let decision = DeliveryDecision {
        project_id: project.to_string(),
        timestamp: completed_at.to_rfc3339(),
        species: species.to_string(),
        stage: stage.to_string(),
        deliverable,
        checks: DeliveryChecks {
            closure: if deliverable { "pass" } else { "fail" }.into(),
            nutrition: if deliverable { "pass" } else { "fail" }.into(),
            category: if deliverable { "pass" } else { "fail" }.into(),
            cost_range: if deliverable { "pass" } else { "fail" }.into(),
            compliance: "skip".into(),
            rule_approved: "skip".into(),
            counterexample: "skip".into(),
        },
        failures: if deliverable { vec![] } else { vec!["delivery_gatekeeper failed".into()] },
        warnings: vec![
            "当前 LP 解为大宗原料成本最小可行解".into(),
            "氨基酸平衡未建模".into(),
            "未经过养殖试验验证".into(),
        ],
        report_disclaimer: "当前结果为模型约束下的可行方案，非养殖试验验证配方。不可表述为「降本X%」等商业承诺。".into(),
    };
    write_json("delivery_decision.json", &decision);

    // execution_log.json
    write_execution_log(project, &steps, &started_at, 0);

    println!();
    println!("═══════════════════════════════════════");
    if deliverable {
        println!("  交付判定: ✅ 通过");
    } else {
        println!("  交付判定: ❌ 未通过");
    }
    println!("  输出文件:");
    println!("    generated/validation_result.json");
    println!("    generated/delivery_decision.json");
    println!("    generated/execution_log.json");
    println!("═══════════════════════════════════════");
}

fn write_execution_log(project: &str, steps: &[ExecutionStep], started_at: &chrono::DateTime<Utc>, exit_code: i32) {
    let log = ExecutionLog {
        project_id: project.to_string(),
        started_at: started_at.to_rfc3339(),
        completed_at: Utc::now().to_rfc3339(),
        exit_code,
        steps: steps.to_vec(),
    };
    write_json("execution_log.json", &log);
}

// ═══════════════════════════════════════════════════════════════
// 子命令: test / gate
// ═══════════════════════════════════════════════════════════════

fn run_counterexample_tests() {
    println!("=== 反例测试 ===");
    let q = "consult('rules/counterexample_tests.pl'), test_all_counterexamples.";
    let out = run_prolog(q, &[]);
    println!("{}", String::from_utf8_lossy(&out.stdout));
    if !out.status.success() {
        eprintln!("{}", String::from_utf8_lossy(&out.stderr));
    }
}

fn run_delivery_gate(project: &str) {
    println!("=== 交付门禁: {} ===", project);
    let state_facts = vec![format!("project_state({}, gated)", project).as_str()];
    let q = format!("can_execute({}, deliver).", project);
    let (ok, out) = run_prolog_bool(&q, &state_facts);
    if ok {
        println!("✅ deliver 允许");
    } else {
        println!("❌ deliver 被阻断");
    }
    println!("{}", out);
}

// ═══════════════════════════════════════════════════════════════
// 数据结构
// ═══════════════════════════════════════════════════════════════

#[derive(Serialize, Deserialize, Clone)]
struct ExecutionStep {
    seq: u32,
    action: String,
    prolog_call: String,
    result: String,
    timestamp: String,
}

#[derive(Serialize, Deserialize)]
struct ExecutionLog {
    project_id: String,
    started_at: String,
    completed_at: String,
    exit_code: i32,
    steps: Vec<ExecutionStep>,
}

#[derive(Serialize, Deserialize)]
struct ValidationResult {
    project_id: String,
    timestamp: String,
    species: String,
    stage: String,
    solution: SolutionResult,
}

#[derive(Serialize, Deserialize)]
#[serde(tag = "status")]
enum SolutionResult {
    #[serde(rename = "solved")]
    Solved { status: String },
    #[serde(rename = "infeasible")]
    Infeasible { reason: String },
}

#[derive(Serialize, Deserialize)]
struct DeliveryDecision {
    project_id: String,
    timestamp: String,
    species: String,
    stage: String,
    deliverable: bool,
    checks: DeliveryChecks,
    failures: Vec<String>,
    warnings: Vec<String>,
    report_disclaimer: String,
}

#[derive(Serialize, Deserialize)]
struct DeliveryChecks {
    closure: String,
    nutrition: String,
    category: String,
    cost_range: String,
    compliance: String,
    rule_approved: String,
    counterexample: String,
}

// ═══════════════════════════════════════════════════════════════
// 工具函数
// ═══════════════════════════════════════════════════════════════

fn write_json<T: Serialize>(filename: &str, data: &T) {
    let generated = project_root().join("generated");
    fs::create_dir_all(&generated).ok();
    let path = generated.join(filename);
    let json = serde_json::to_string_pretty(data).unwrap();
    fs::write(&path, json).unwrap();
    println!("  → {}", path.display());
}
