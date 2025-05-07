import os
import yaml
from datetime import datetime
from subprocess import check_output

EXCLUDE_DIRS = {'.venv', 'build', 'coverage', '.dart_tool'}

def get_project_meta():
    return f"""# 🧠 onbit_v2_triple 프로젝트 리포트

> 자동 생성 시점: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

- 목적: 실시간 크립토 분석 + 자동화 트레이딩 시스템
- 아키텍처: 4-Layer Clean Architecture (core/data/domain/presentation)
- AI 협업 구조: GPT + Claude + Groq 기반 트리플 분석

---
"""

def get_directory_tree():
    try:
        output = check_output(["tree", "-I", "|".join(EXCLUDE_DIRS), "-L", "3"]).decode()
        return f"## 🗂️ 프로젝트 디렉토리 구조\n\n```\n{output}\n```\n"
    except Exception as e:
        return f"## 🗂️ 프로젝트 디렉토리 구조\n\n(tree 설치 필요)\n{e}\n"

def get_changelog():
    path = "docs/CHANGELOG.md"
    if os.path.exists(path):
        with open(path, "r") as f:
            lines = f.readlines()
        top_changes = "".join(lines[:40])  # 최근 변경 최대 40줄
        return f"## 📅 최근 변경 사항 (CHANGELOG)\n\n{top_changes}\n"
    return "## 📅 최근 변경 사항\n\n❌ CHANGELOG.md 없음\n"

def get_workflows_summary():
    summary = "## 🔁 GitHub Workflows 요약\n\n"
    workflow_dir = ".github/workflows"
    for filename in sorted(os.listdir(workflow_dir)):
        if filename.endswith(".yml") or filename.endswith(".yaml"):
            path = os.path.join(workflow_dir, filename)
            with open(path, "r") as file:
                content = yaml.safe_load(file)
                summary += f"### 🛠️ {filename}\n"
                summary += f"- **Name**: {content.get('name', 'Unnamed')}\n"
                summary += f"- **Jobs**: {', '.join(content.get('jobs', {}).keys())}\n"
                summary += "- **Steps**:\n"
                for job in content.get('jobs', {}).values():
                    for step in job.get('steps', []):
                        summary += f"  - {step.get('name', 'Unnamed Step')}\n"
                summary += "\n"
    return summary

def get_priority_tasks():
    return """## 🎯 주요 유즈케이스 / 우선순위 작업

- [x] 소켓 기반 실시간 트레이드 데이터 수신
- [x] Skeleton UI + trade_card 위젯 구성
- [x] get_filtered_trades 유즈케이스 설계
- [ ] Phase 2: Alert Controller 설계 + 백프레셔 처리
"""

def get_gpt_context():
    path = "gpt_context/context.md"
    if os.path.exists(path):
        with open(path, "r") as f:
            return f"## 🧠 GPT Context Snapshot\n\n{f.read()}"
    return "## 🧠 GPT Context Snapshot\n\n❌ context.md 없음\n"

def generate_report():
    sections = [
        get_project_meta(),
        get_directory_tree(),
        get_changelog(),
        get_workflows_summary(),
        get_priority_tasks(),
        get_gpt_context(),
    ]
    with open("docs/project_report.md", "w") as f:
        f.write("\n\n".join(sections))
    print("✅ docs/project_report.md 생성 완료")

if __name__ == "__main__":
    generate_report()
