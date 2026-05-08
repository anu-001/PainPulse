# PainPulse
PainPulse is an internal data platform that continuously scans Reddit for recurring user complaints and “I wish there was a tool for…” posts, cleans and models that data, and surfaces ranked SaaS opportunity signals through dashboards and a lightweight UI.

Internal Reddit-based opportunity intelligence platform.

- Ingests Reddit posts.
- Detects and groups recurring pain points into canonical opportunity themes.
- Scores and ranks opportunities.
- Exposes them via dashboards (Superset).

This repo is structured for production-quality, test-driven development with:
- Docker Compose
- Airflow
- PostgreSQL
- dbt
- Superset
- Python ingestion services
