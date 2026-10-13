# aws-batch-fargate-terraform

English | [日本語](README.ja.md)

Terraform code for a serverless batch that aggregates access logs placed in S3 with AWS Batch (Fargate) and writes the result to another S3 bucket.

It is a Terraform version of the architecture that is built by hand in the management console in the Qiita hands-on article "[【30日でAWSをマスターするハンズオン問題集】Day12：AWS Batch（Fargate）でサーバレスなアクセスログの集計バッチを作成してみよう](https://qiita.com/pommny_dev/items/1391c80159be9149bc8a)" (in Japanese).

> [!NOTE]
> This code was actually deployed to AWS and confirmed to work. For publication, environment-specific values such as the AWS account ID, IAM role name, and S3 bucket names have been masked and replaced with variables or GitHub Secrets. It has not been redeployed in its masked form, so set the values for your own environment and review the output of `terraform plan` before using it.

## Architecture

![Architecture diagram](diagram.drawio.svg)

The processing flow is as follows.

1. GitHub Actions builds the Docker image of the aggregation script and pushes it to ECR
2. An access log (CSV) is uploaded to the source S3 bucket
3. The S3 event notification (`s3:ObjectCreated:Put`) invokes Lambda
4. Lambda submits a job to AWS Batch
5. The Batch (Fargate) job aggregates the log
6. The result (CSV) is written to the result S3 bucket

Lambda sits in between because an S3 event notification cannot start a Batch job directly.

## Directory structure

```
.
├── main.tf                    # Calls each module
├── provider.tf                # AWS provider settings
├── backend.tf                 # Bucket for tfstate and S3 backend settings
├── variables.tf               # Variable definitions (bucket names, values for names and tags)
├── terraform.tfvars.example   # Template for the variable file
├── modules/
│   ├── network/               # VPC, private subnets, VPC endpoints (S3 / ECR), security groups
│   ├── iam/                   # Batch execution role, Batch task role, Lambda execution role
│   ├── s3/                    # Source and result buckets, event notification
│   ├── ecr/                   # ECR repository
│   ├── lambda/                # Lambda function that submits the Batch job
│   └── batch/                 # Compute environment, job queue, job definition
├── Dockerfile                 # Container image of the aggregation batch
├── aggregate_accesslog.py     # Aggregation script
├── accesslog_20240321.csv     # Sample log for testing
├── diagram.drawio             # Source of the architecture diagram (draw.io)
└── .github/workflows/         # CI (terraform plan, push to ECR, automatic PR creation)
```

## Prerequisites

- Terraform 1.14.x (CI uses 1.14.6)
- AWS provider 6.21.0
- The region is fixed to `ap-northeast-1`
- AWS credentials are configured
- To use GitHub Actions, create an OIDC identity provider for GitHub and an IAM role separately (they are not created by the Terraform code in this repository)

## Usage

### 1. Prepare the variable file

```sh
cp terraform.tfvars.example terraform.tfvars
```

Change the bucket names in `terraform.tfvars` to ones for your environment. S3 bucket names must be globally unique. `terraform.tfvars` is listed in `.gitignore`.

| Variable | Description |
|---|---|
| `source_bucket_name` | Name of the bucket where access logs are placed |
| `result_bucket_name` | Name of the bucket where results are written |
| `tfstate_bucket_name` | Name of the bucket that stores tfstate |

The following variables are optional. They are used in resource names and tags.

| Variable | Default | Description |
|---|---|---|
| `environment` | `dev` | Environment name. Used as a prefix of resource names and in the `Name` / `Environment` tags |
| `vpc_name` | `fargate-batch-vpc` | VPC name. Used in the `Name` tag of network resources |
| `ecr_repo_name` | `fargate-batch-repo` | ECR repository name. If you change it, also change `ECR_REPOSITORY` in `ecr_push.yaml` |
| `github_repo` | `hot377/aws-batch-fargate-terraform` | GitHub repository name in `owner/repo` format |

### 2. Create the resources

```sh
terraform init
terraform plan
terraform apply
```

To manage tfstate in S3, create the tfstate bucket with the first `apply`, then uncomment the block at the top of `backend.tf`, change `bucket` to your bucket name, and run `terraform init` again.

### 3. Push the container image

When `Dockerfile` or `*.py` is changed and pushed to the `main` branch, GitHub Actions (`ecr_push.yaml`) builds the image and pushes it to ECR.

### 4. Verify

Upload an access log to the source bucket.

```sh
aws s3 cp accesslog_20240321.csv s3://<source_bucket_name>/
```

When the Batch job finishes, `YYYYMMDD/summary_YYYYMMDD.csv` is written to the result bucket.

## Input and output format

### Input

- File name: `accesslog_YYYYMMDD.csv`
- Columns: `timestamp,ip,status` (only the first and third columns are used)
- A row whose first column starts with `timestamp` is skipped as a header

```csv
timestamp,ip,status
2026-03-21 00:01:23,192.168.1.1,200
2026-03-21 00:03:47,10.0.0.5,404
```

### Output

| metric | Description |
|---|---|
| `period_start` | Earliest timestamp in the log |
| `period_end` | Latest timestamp in the log |
| `total` | Number of rows aggregated |
| `status_200` | Number of rows with status code 200 |
| `status_other` | Number of rows with a status code other than 200 |
| `skipped_rows` | Number of rows skipped because of an invalid format |

## GitHub Actions

| Workflow | Trigger | Description |
|---|---|---|
| `plan.yml` | Pull request to `main` | Runs `terraform fmt` / `init` / `validate` / `plan` and comments the result on the PR |
| `ecr_push.yaml` | Push to `main` (when `Dockerfile` or `*.py` changes) | Builds the image and pushes it to ECR |
| `auto-pr.yml` | Push to `develop` | Automatically creates a pull request to `main` |

Register the following secrets in the repository to use them.

| Secret | Description |
|---|---|
| `AWS_ROLE_ARN` | ARN of the IAM role that GitHub Actions assumes via OIDC |
| `SOURCE_BUCKET_NAME` | Value of `source_bucket_name` |
| `RESULT_BUCKET_NAME` | Value of `result_bucket_name` |
| `TFSTATE_BUCKET_NAME` | Value of `tfstate_bucket_name` |
| `MY_PAT` | Personal access token used for automatic PR creation |

## Cleanup

```sh
terraform destroy
```

Deletion fails if objects remain in the source or result bucket, or if images remain in the ECR repository, so empty them first.

## License

The Terraform code, GitHub Actions workflows, documentation, and architecture diagram in this repository are licensed under the [MIT License](LICENSE).

The application code (`aggregate_accesslog.py`, `Dockerfile`, and `modules/lambda/src/function.py`) is based on the code published in the Qiita article listed below and is not covered by the MIT License of this repository. Refer to the original article for its terms.

## Reference

- [【30日でAWSをマスターするハンズオン問題集】Day12：AWS Batch（Fargate）でサーバレスなアクセスログの集計バッチを作成してみよう](https://qiita.com/pommny_dev/items/1391c80159be9149bc8a) (in Japanese)
