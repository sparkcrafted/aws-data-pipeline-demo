# AWS Data Pipeline Demo

![AWS](https://img.shields.io/badge/AWS-Data%20Engineering-orange)
![Infrastructure as Code](https://img.shields.io/badge/IaC-Terraform%2FCDK-blue)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

### End-to-end AWS data lake pipeline demonstrating batch, streaming, and database replication

This repository implements a **fully serverless, production-pattern AWS data lake pipeline** built with Terraform, AWS Lambda, Glue, and Athena.  
It automates ingestion, transformation, validation, and curation of data, providing a complete reference for modern cloud data engineering.

---

## 🧭 Architecture Overview

| Layer | AWS Services | Description |
|-------|---------------|-------------|
| **Ingestion** | S3, AWS DMS, Kinesis Firehose | Handles batch CSV uploads, database replication, and real-time streaming events |
| **Transformation** | AWS Lambda, AWS Glue | Converts CSV → Parquet, normalizes schema, validates data, and routes errors |
| **Storage & Governance** | S3, Lake Formation | Three-zone architecture (Landing → Clean → Curated) with encryption and versioning |
| **Reliability & Quality** | CloudWatch, SQS (DLQ) | Dead-Letter Queue captures failures, CloudWatch alarms monitor Lambda errors |
| **Query & Consumption** | Athena, Glue Catalog | Provides SQL access to curated data for analytics and reporting |
| **Visualization** | QuickSight, Python, Power BI | Enables dashboards and ad-hoc insights from Athena datasets |

<p align="center">
  <img src="docs/10-architecture-overview.png" alt="AWS Data Pipeline Architecture" width="720">
</p>

---

## 🧩 Project Phases

| Phase | Description | Status |
|:--:|:--|:--:|
| 1 | **Infrastructure Provisioning:** S3 zones, IAM roles, encryption, versioning | ✅ |
| 2 | **Transformation Pipeline:** Lambda CSV-to-Parquet conversion triggered by S3 events | ✅ |
| 3 | **Quality & Reliability:** Validation logic, DLQ, CloudWatch alarm integration | ✅ |
| 4 | **Curation & Query:** Glue crawler + Athena CTAS queries for curated zone | ✅ |
| 5 | **Visualization & Insights:** QuickSight dashboards / Python analytics | ✅ |

---

## ⚙️ Infrastructure Deployment (Terraform)

All resources are provisioned via Infrastructure-as-Code for reproducibility.

```bash
cd infra
terraform init
terraform plan
terraform apply
