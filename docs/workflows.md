# ⚙️ GitHub Workflows Summary

> 자동 생성된 워크플로우 요약. 이름, 파일명, 트리거 포함.

### ✅ codecov.yml
- **name**: Trigger Codecov
- **triggers**:
  - push: [main]
  - pull_request: [main]

### ✅ flutter_changelog.yml
- **name**: Flutter Changelog
- **triggers**:
  - push: [dev]
  - pull_request: [dev]
  - workflow_dispatch

### ✅ flutter_ci.yml
- **name**: Flutter CI
- **triggers**:
  - push: [main,]
  - pull_request: [main,]
  - workflow_dispatch

### ✅ flutter_module_summary.yml
- **name**: Flutter Module Summary
- **triggers**:
  - push: [dev]
  - workflow_dispatch

### ✅ flutter_readme_badge1.yml
- **name**: Flutter README Badge
- **triggers**:
  - push: []
  - workflow_dispatch

### ✅ flutter_readme_badge2.yml
- **name**: Flutter README Badge
- **triggers**:
  - push: []
  - workflow_dispatch

### ✅ flutter_readme_badge3.yml
- **name**: Flutter README Badge
- **triggers**:
  - push: []
  - workflow_dispatch

### ✅ flutter_snapshot.yml
- **name**: Flutter Project Snapshot
- **triggers**:
  - push: [dev]
  - workflow_dispatch

### ✅ flutter_summarize.yml
- **name**: Flutter Summarize lib/ Structure
- **triggers**:
  - push: [dev]
  - workflow_dispatch

### ✅ gpt_context.yml
- **name**: GPT Context Snapshot
- **triggers**:
  - workflow_dispatch
  - push: [main]

