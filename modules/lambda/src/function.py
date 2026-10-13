import os
import json
import boto3
from datetime import datetime
from urllib.parse import unquote_plus

# クライアント初期化
batch = boto3.client("batch")

def lambda_handler(event, context):
    # 環境変数をハンドラ内で取得（確実性を期すため）
    JOB_QUEUE = os.environ.get("BATCH_JOB_QUEUE_ARN")
    JOB_DEF = os.environ.get("BATCH_JOB_DEFINITION_ARN")
    OUTPUT_BUCKET = os.environ.get("OUTPUT_BUCKET")
    
    results = []

    for rec in event.get("Records", []):
        try:
            bucket = rec["s3"]["bucket"]["name"]
            key = unquote_plus(rec["s3"]["object"]["key"])
            
            base_name = os.path.basename(key)
            date_str = base_name.replace("accesslog_", "").replace(".csv", "")
            output_key = f"{date_str}/summary_{date_str}.csv"
            job_name = f"job-{date_str}-{int(datetime.utcnow().timestamp())}"

            # ---------------------------------------------------------
            # 修正ポイント: 
            # 辞書形式で引数を構築し、不必要なキーが一切入らないようにする
            # ---------------------------------------------------------
            submit_params = {
                "jobName": job_name,
                "jobQueue": JOB_QUEUE,
                "jobDefinition": JOB_DEF,
                "containerOverrides": {
                    "command": [
                        "--input-bucket", bucket,
                        "--input-prefix", key,
                        "--output-bucket", OUTPUT_BUCKET,
                        "--output-key", output_key
                    ]
                }
            }

            # API呼び出し
            response = batch.submit_job(**submit_params)
            
            print(f"Success: {response['jobId']}")
            results.append(response['jobId'])

        except Exception as e:
            print(f"Critical Error: {str(e)}")

    return {"submitted": results}