# NYC Taxi Data Platform (Governance + CI/CD)

This repo contains hands-on labs for building a governed data pipeline on AWS using:
- S3 (raw + curated zones/trips)
- Glue (ETL)
- Step Functions (orchestration with governance checkpoints)
- Athena SQL workflow (modular transforms + quality checks + tests)
- IAM policies and governance configs (YAML/JSON)
- GitHub Actions CI/CD for Terraform and governance-as-code

## Repo Structure
- `infra/` Terraform (S3, Lambda, RDS)
- `sql/` modular SQL transforms, quality checks, tests
- `governance/` quality rules (YAML), access policies (JSON), metadata schemas
- `docs/` documentation and runbooks

## How to run (high level)
1. Deploy infra (Terraform)
2. Upload data to S3
3. Create Athena tables (Glue Data Catalog)
4. Run Glue job to execute SQL workflow
5. Run Step Functions pipeline (freshness + quality + approvals + audit logs)

