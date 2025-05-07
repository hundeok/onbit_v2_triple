### 🛠️ codecov.yml
- **Name**: Trigger Codecov
- **Jobs**: coverage
- **Steps**:
  - Checkout repository
  - Set up Flutter
  - Install dependencies
  - Run tests with coverage
  - Upload coverage to Codecov

### 🛠️ flutter_changelog.yml
- **Name**: Flutter Changelog
- **Jobs**: generate-changelog
- **Steps**:
  - Checkout code
  - Set Git config
  - Generate CHANGELOG.md
  - Commit changelog

### 🛠️ flutter_ci.yml
- **Name**: Flutter CI
- **Jobs**: build
- **Steps**:
  - Checkout repository
  - Set up Flutter
  - Install dependencies
  - Analyze code
  - Run tests with coverage
  - Upload coverage to Codecov

### 🛠️ flutter_module_summary.yml
- **Name**: Flutter Module Summary
- **Jobs**: generate-summary
- **Steps**:
  - Checkout code
  - Generate module summary
  - Git commit

### 🛠️ flutter_readme_badge3.yml
- **Name**: Flutter README Badge
- **Jobs**: update-readme
- **Steps**:
  - Checkout Repository
  - Append Badge to README
  - Commit and Push Changes

### 🛠️ flutter_snapshot.yml
- **Name**: Flutter Project Snapshot
- **Jobs**: generate-snapshot
- **Steps**:
  - Checkout code
  - Install tree
  - Generate project snapshot
  - Commit & Push Snapshot

### 🛠️ flutter_summarize.yml
- **Name**: Flutter Summarize lib/ Structure
- **Jobs**: summarize
- **Steps**:
  - Checkout code
  - Install tree
  - Generate lib/ module summary
  - Commit module summary

### 🛠️ gpt_context.yml
- **Name**: GPT Context Snapshot
- **Jobs**: generate-context
- **Steps**:
  - Checkout code
  - Ensure jq is available
  - Create GPT context files
  - Commit & Push GPT context

