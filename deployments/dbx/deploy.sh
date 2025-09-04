#!/bin/bash
set -e


echo "Uploading notebook..."
databricks workspace import  /Workspace/Users/kavikg7@outlook.com/demo_etl-1.py --file deployments/dbx/demo-etl.py --language PYTHON --overwrite --debug
echo "Creating job..."
cat > job.json <<EOF
{
  "name": "demo-etl-job",
  "new_cluster": {
    "spark_version": "13.3.x-scala2.12",
    "node_type_id": "Standard_DS3_v2",
    "num_workers": 1
  },
  "notebook_task": {
    "notebook_path": "/Workspace/Users/kavikg7@outlook.com/demo_etl-1.py"
  }
}
EOF

job_id=$(databricks jobs create --json @job.json | jq -r .job_id)
echo "Job created with ID: $job_id"

echo "Running job..."
databricks jobs run-now "$job_id"

echo "Done!"