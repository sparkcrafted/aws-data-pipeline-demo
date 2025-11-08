# AWS Data Pipeline Demo

![AWS](https://img.shields.io/badge/AWS-Data%20Engineering-orange)
![Infrastructure as Code](https://img.shields.io/badge/IaC-Terraform%2FCDK-blue)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

### End-to-end AWS data lake pipeline demonstrating batch, streaming, and database replication

This repository provides a **reference architecture** for building a modern data-engineering pipeline on AWS.  
It ingests **batch**, **streaming**, and **relational** data sources into an S3-based data lake, applies automated transformations,  
and exposes curated datasets for analytics through AWS Glue, Lake Formation, and Athena.

---

## 🧭 Architecture Overview
**Core components**

| Layer | AWS Services | Description |
|-------|---------------|-------------|
| Ingestion | S3, AWS DMS, Kinesis Firehose | CSV upload triggers, database replication, and real-time streaming ingestion |
| Transformation | Lambda, AWS Glue | CSV → Parquet conversion, schema normalization, partitioning |
| Storage & Governance | S3, Lake Formation | Multi-zone lake design (Landing → Clean → Curated) with RBAC and tagging |
| Query & Consumption | Athena | Ad-hoc analysis, validation, and reporting |

<p align="center">
  <img src="docs/10-architecture-overview.png" alt="AWS Data Pipeline Architecture" width="700">
</p>

---

## 🚀 Quick Start (Public Twin)
1. **Clone the repo**
   ```bash
   git clone https://github.com/sparkcrafted/aws-data-pipeline-demo.git
   cd aws-data-pipeline-demo
