import os
import yaml

workflow_dir = ".github/workflows"

for filename in sorted(os.listdir(workflow_dir)):
    if filename.endswith(".yml") or filename.endswith(".yaml"):
        path = os.path.join(workflow_dir, filename)
        with open(path, "r") as file:
            content = yaml.safe_load(file)
            print(f"### 🛠️ {filename}")
            print(f"- **Name**: {content.get('name', 'Unnamed')}")
            print(f"- **Jobs**: {', '.join(content.get('jobs', {}).keys())}")
            print("- **Steps**:")
            for job in content.get('jobs', {}).values():
                for step in job.get('steps', []):
                    print(f"  - {step.get('name', 'Unnamed Step')}")
            print()
