# Dockerfile
FROM public.ecr.aws/amazonlinux/amazonlinux:2023

# OSパッケージ
RUN dnf -y update && dnf -y install python3 python3-pip && dnf clean all

# Python依存（boto3 だけでOK）
RUN pip3 install --no-cache-dir boto3

# アプリ配置
WORKDIR /app
COPY aggregate_accesslog.py /app/

# 実行
ENTRYPOINT ["python3", "/app/aggregate_accesslog.py"]

#2026-03-20 push to ECR
