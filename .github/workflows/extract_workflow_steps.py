import os
import yaml
import datetime
import subprocess

def get_current_time():
    return datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

def get_recent_commits(limit=10):
    try:
        output = subprocess.check_output(["git", "log", f"-{limit}", "--pretty=format:- %s (%h)"])
        return output.decode("utf-8")
    except Exception as e:
        return f"Error fetching git log: {e}"

def get_tree_structure():
    try:
        output = subprocess.check_output(
            ["tree", "-I", ".git|.venv|build|coverage|.dart_tool|.idea", "-L", "3"],
            stderr=subprocess.STDOUT
        )
        return output.decode("utf-8")
    except Exception as e:
        return f"Error running tree: {e}"

def parse_workflows():
    summary = ""
    path = ".github/workflows"
    for filename in sorted(os.listdir(path)):
        if filename.endswith(".yml") or filename.endswith(".yaml"):
            with open(os.path.join(path, filename), "r") as f:
                try:
                    content = yaml.safe_load(f)
                    summary += f"### 🛠️ {filename}\n"
                    summary += f"- **Name**: {content.get('name', 'Unnamed')}\n"
                    jobs = content.get("jobs", {})
                    summary += f"- **Jobs**: {', '.join(jobs.keys())}\n"
                    summary += "- **Steps**:\n"
                    for job in jobs.values():
                        for step in job.get("steps", []):
                            summary += f"  - {step.get('name', 'Unnamed Step')}\n"
                    summary += "\n"
                except Exception as e:
                    summary += f"- ❌ Error parsing {filename}: {e}\n\n"
    return summary

# Generate report
print(f"# 🧠 onbit_v2_triple 프로젝트 리포트\n")
print(f"> 자동 생성 시점: {get_current_time()}\n")

print("- 목적: 실시간 크립토 분석 + 자동화 트레이딩 시스템")
print("- 아키텍처: 4-Layer Clean Architecture (core/data/domain/presentation)")
print("- AI 협업 구조: GPT + Claude + Groq 기반 트리플 분석\n")
print("---\n")

print("## 🗂️ 프로젝트 디렉토리 구조\n")
print("```")
print(get_tree_structure())
print("```\n")

print("## 📅 최근 변경 사항 (CHANGELOG)\n")
print("### 🔄 Recent Commits\n")
print(get_recent_commits())

print("\n## 🔁 GitHub Workflows 요약\n")
print(parse_workflows())

print("## 🎯 주요 유즈케이스 / 우선순위 작업\n")
print("- [x] 소켓 기반 실시간 트레이드 데이터 수신")
print("- [x] Skeleton UI + trade_card 위젯 구성")
print("- [x] get_filtered_trades 유즈케이스 설계")
print("- [ ] Phase 2: Alert Controller 설계 + 백프레셔 처리\n")
