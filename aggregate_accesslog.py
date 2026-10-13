# アクセスログ集計バッチ（S3上のアクセスログを集計し、集計結果をS3に出力する）
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import boto3
import csv
import io
from datetime import datetime

s3 = boto3.client("s3")

TS_FORMATS = [
  "%Y-%m-%d %H:%M:%S",  # 例: 2025-09-18 00:00:00
  "%Y-%m-%d %H:%M",     # 例: 2025-09-18 00:00
  "%Y/%m/%d %H:%M:%S",  # 例: 2025/9/18 0:00:00
  "%Y/%m/%d %H:%M",     # 例: 2025/9/18 0:00
]

def parse_ts(s: str):
  s = s.strip()
  for fmt in TS_FORMATS:
      try:
          return datetime.strptime(s, fmt)
      except ValueError:
          continue
  raise ValueError(f"unsupported timestamp format: {s}")

def aggregate(bucket: str, prefix: str):
  min_time = None
  max_time = None
  total = 0
  ok_200 = 0
  ng_other = 0
  skipped = 0

  kwargs = {"Bucket": bucket, "Prefix": prefix}
  while True:
      resp = s3.list_objects_v2(**kwargs)
      for obj in resp.get("Contents", []):
          key = obj["Key"]
          if obj.get("Size", 0) == 0:
              continue
          body = s3.get_object(Bucket=bucket, Key=key)["Body"].read().decode("utf-8-sig", errors="ignore")

          reader = csv.reader(io.StringIO(body))
          header = next(reader, None)
          if not header or not header[0].strip().lower().startswith("timestamp"):
              reader = csv.reader(io.StringIO(body))

          for row in reader:
              if not row or len(row) < 3:
                  skipped += 1
                  continue
              ts_str, _, status_str = row[0], row[1], row[2]
              try:
                  ts = parse_ts(ts_str)
                  status = int(str(status_str).strip())
              except Exception:
                  skipped += 1
                  continue

              total += 1
              if status == 200:
                  ok_200 += 1
              else:
                  ng_other += 1

              if min_time is None or ts < min_time:
                  min_time = ts
              if max_time is None or ts > max_time:
                  max_time = ts

      if resp.get("IsTruncated"):
          kwargs["ContinuationToken"] = resp["NextContinuationToken"]
      else:
          break

  return {
      "period_start": min_time.strftime("%Y-%m-%d %H:%M:%S") if min_time else "",
      "period_end":   max_time.strftime("%Y-%m-%d %H:%M:%S") if max_time else "",
      "total": total,
      "status_200": ok_200,
      "status_other": ng_other,
      "skipped_rows": skipped,
  }

def upload_result(bucket: str, key: str, result: dict):
  output = io.StringIO()
  writer = csv.writer(output, lineterminator="\n")
  writer.writerow(["metric","value"])
  for k, v in result.items():
      writer.writerow([k, v])
  s3.put_object(
      Bucket=bucket,
      Key=key,
      Body=output.getvalue().encode("utf-8"),
      ContentType="text/csv; charset=utf-8"
  )

def main():
  parser = argparse.ArgumentParser(description="access log aggregator")
  parser.add_argument("--input-bucket", required=True)
  parser.add_argument("--input-prefix", required=True)
  parser.add_argument("--output-bucket", required=True)
  parser.add_argument("--output-key", required=True, help="例: reports/summary.csv")
  args = parser.parse_args()

  result = aggregate(args.input_bucket, args.input_prefix)
  upload_result(args.output_bucket, args.output_key, result)
  print("[OK] 集計完了:", result)

if __name__ == "__main__":
  main()

#2026-03-20 push to ECR