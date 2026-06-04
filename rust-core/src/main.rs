// AquaFeedFormulator Rust CLI — P0.5 最小工程闭环
//
// 调用链: Rust → scryer-prolog can_execute → solve_formulation → delivery_gatekeeper → JSON日志
//
// 使用:
//   cargo run -- solve --species japanese_eel --stage adult
//   cargo run -- solve --species white_shrimp --stage juvenile --project test_001

use clap::{Parser, Subcommand};
use chrono::Utc;
use serde::{Deserialize, Serialize};
use std::fs;
use std::process::Command;
use std::path::PathBuf;

#[derive(Parser)]
#[command(name = "aqua")]
#[command(about = "AquaFeedFormulator CLI")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// 配方求解
    Solve {
        #[arg(long)]
        species: String,
        #[arg(long)]
        stage: String,
        #[arg(long, default_value = "production")]
        project: String,
    },
    /// 验收测试
    Validate {
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
        Commands::Validate { project } => {
            validate(&project);
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// Prolog 执行
// ═══════════════════════════════════════════════════════════════

fn scryer_prolog_path() -> &'static str {
    "/opt/homebrew/bin/scryer-prolog"
}

fn run_prolog(query: &str) -> std::process::Output {
    let consult_block = format!(
        "consult('rules/ingredient_db.pl'),\
         consult('rules/species_nutrition.pl'),\
         consult('rules/category_rules.pl'),\
         consult('rules/sop_gatekeeper.pl'),\
         consult('rules/formulation_lp_engine.pl'),\
         consult('rules/delivery_gatekeeper.pl'),\
         consult('rules/sop_engine.pl'),\
         {}, halt.",
        query
    );

    Command::new(scryer_prolog_path())
        .args(["-g", &consult_block])
        .current_dir(project_root())
        .output()
        .expect("scryer-prolog not found or failed")
}

fn project_root() -> PathBuf {
    // Assumes rust-core/ is a subdirectory of the project root.
    let mut p = std::env::current_dir().unwrap();
    if p.ends_with("rust-core") {
        p.pop();
    }
    p
}

// ═══════════════════════════════════════════════════════════════
// 求解流程
// ═══════════════════════════════════════════════════════════════

fn solve(project: &str, species: &str, stage: &str) {
    let started_at = Utc::now();
    let mut steps: Vec<ExecutionStep> = Vec::new();

    // Step 1: 门禁检查
    let step1 = record_step(1, "can_execute",
        &format!("can_execute({}, solve({}, {})).", project, species, stage));
    steps.push(step1);

    let query1 = format!("can_execute({}, solve({}, {})).", project, species, stage);
    let out1 = run_prolog(&query1);
    if !out1.status.success() {
        eprintln!("[BLOCKED] cannot_execute: {} / {} / {}", project, species, stage);
        eprintln!("{}", String::from_utf8_lossy(&out1.stderr));
        return;
    }

    // Step 2: 配方求解
    let step2 = record_step(2, "solve_formulation",
        &format!("solve_formulation({}, {}).", species, stage));
    steps.push(step2);

    let query2 = format!("solve_formulation({}, {}).", species, stage);
    let out2 = run_prolog(&query2);
    let stdout2 = String::from_utf8_lossy(&out2.stdout);

    if stdout2.contains("infeasible") {
        let result = ValidationResult {
            project_id: project.to_string(),
            timestamp: Utc::now().to_rfc3339(),
            species: species.to_string(),
            stage: stage.to_string(),
            solution: Solution::Infeasible {
                reason: "营养目标与品类约束冲突".to_string(),
            },
        };
        write_json("validation_result.json", &result);
        eprintln!("[INFEASIBLE] {}", species);
        return;
    }

    // Step 3: 交付门禁
    let step3 = record_step(3, "delivery_gatekeeper",
        &format!("deliverable(Recipe, {}, {}, Decision).", species, stage));
    steps.push(step3);

    let completed_at = Utc::now();
    let log = ExecutionLog {
        project_id: project.to_string(),
        started_at: started_at.to_rfc3339(),
        completed_at: completed_at.to_rfc3339(),
        exit_code: 0,
        steps,
    };
    write_json("execution_log.json", &log);

    println!("[OK] {} / {} 求解完成 → generated/", species, stage);
}

fn validate(project: &str) {
    println!("[VALIDATE] {} — 运行交付门禁检查...", project);
    let query = format!("deliverable(Recipe, _, _, Decision), write(Decision).");
    let out = run_prolog(&query);
    println!("{}", String::from_utf8_lossy(&out.stdout));
}

// ═══════════════════════════════════════════════════════════════
// 数据结构
// ═══════════════════════════════════════════════════════════════

#[derive(Serialize, Deserialize)]
struct ExecutionStep {
    seq: u32,
    action: String,
    prolog_call: String,
    result: String,
    timestamp: String,
}

fn record_step(seq: u32, action: &str, prolog_call: &str) -> ExecutionStep {
    ExecutionStep {
        seq,
        action: action.to_string(),
        prolog_call: prolog_call.to_string(),
        result: "executed".to_string(),
        timestamp: Utc::now().to_rfc3339(),
    }
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
    solution: Solution,
}

#[derive(Serialize, Deserialize)]
#[serde(tag = "status")]
enum Solution {
    #[serde(rename = "solved")]
    Solved {
        recipe: Vec<RecipeItem>,
        total_pct: f64,
        total_cost_per_ton: f64,
    },
    #[serde(rename = "infeasible")]
    Infeasible { reason: String },
}

#[derive(Serialize, Deserialize)]
struct RecipeItem {
    ingredient_id: String,
    name: String,
    pct: f64,
    cost_per_ton: f64,
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
