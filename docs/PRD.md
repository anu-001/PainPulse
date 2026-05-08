# ProblemPulse – Product Requirements Document (PRD)

## Metadata

- **Product name:** ProblemPulse
- **Document type:** Product Requirements Document (PRD)
- **Owner:** <Your Name>
- **Version:** v1.0
- **Status:** Draft – V1 Internal Tool
- **Last updated:** <YYYY‑MM‑DD>

---

## 1. Overview & Problem Statement

Indie SaaS founders, consultants, and internal innovation teams often browse Reddit manually to find “someone should build X”‑style complaints and tool gaps. This is noisy, time‑consuming, and impossible to track systematically.

**ProblemPulse** is an internal platform that continuously ingests Reddit posts/comments, detects recurring pain points, groups them into canonical opportunity themes, and ranks those opportunities using transparent, configurable scoring. It exposes results through dashboards (and later a lightweight UI) so users can quickly shortlist ideas worth validating.

V1 is designed as a **single‑VPS, Docker‑Compose‑based, open‑source data stack** with Airflow, PostgreSQL, dbt, Superset, and a Python ingestion service.

---

## 2. Objectives & Success Metrics

### 2.1 Objectives

1. Provide a **repeatable mechanism** to discover and track opportunity themes from Reddit.
2. Present **canonicalized opportunities**, not just raw posts, with clear ranking and trends.
3. Achieve **operational reliability** suitable for weekly or monthly use by product decision‑makers.

### 2.2 Success Metrics (for V1)

- **Discovery output:** For a given niche, at least 10–30 distinct opportunity themes identified per month.
- **Time saved:** Subjective reduction of time spent manually scanning Reddit for ideas (self‑reported by users).
- **Pipeline reliability:** ≥ 95% successful runs per month for core DAGs (ingestion + modeling/scoring), excluding planned downtime.
- **Adoption:** Regular use by at least one founder/consultant/PM, evidenced by monthly reviews of the dashboards.

---

## 3. Scope & Out‑of‑Scope

### 3.1 In Scope (V1)

- Ingestion of Reddit posts (and optionally top‑level comments) from configured subreddits and search terms.
- Layered storage and modeling (Bronze → Silver → Gold) in PostgreSQL.
- Enrichment of posts with basic features: question detection, pattern matches, engagement metrics, lexicon‑based sentiment.
- Matching/filtering of “pain posts” based on patterns and thresholds.
- Canonicalization/grouping of similar pain posts into **canonical opportunities**.
- Configurable scoring and ranking of opportunities.
- Superset dashboards for:
  - Top opportunities by score.
  - Trends over time.
  - Drill‑down from opportunities to example posts.
- Minimal alerting via Airflow (email/Slack) for failures and gross anomalies.
- Backfill and reprocessing based on immutable raw data.

### 3.2 Out of Scope (V1)

- External, multi‑tenant SaaS offering.
- Full competition analysis / “competition score” based on external product data (deferred).
- Heavy ML/LLM pipelines, vector DBs, or real‑time streaming infra (Kafka, Pub/Sub).
- Custom FastAPI/Next.js UI (beyond Superset dashboards).
- Kubernetes or distributed cluster orchestration.

---

## 4. Target Users & Personas

### 4.1 Indie SaaS Founder

- Builds B2B/B2C micro‑SaaS products.
- Needs: A pipeline of realistic, recurring problems with evidence (raw quotes) to inform what to build next.

### 4.2 Consultant / Automation Agency Owner

- Delivers process automations or internal tools for clients.
- Needs: Signals of painful manual workflows in their domain (e.g., marketing ops, data ops) that can be turned into services or products.

### 4.3 Internal Product / Innovation Lead

- Works inside a company looking for new internal tools or product extensions.
- Needs: Evidence‑backed themes aligned with their domain to justify experiments or proof‑of‑concepts.

---

## 5. User Scenarios

1. **Monthly opportunity scan**
   - User selects niche (subreddits/tags) and timeframe.
   - Views a ranked list of opportunity themes with scores and key metrics.
   - Shortlists a few opportunities for further research.

2. **Deep dive into an opportunity**
   - User clicks a canonical opportunity.
   - Sees a human‑readable description, trend chart, and several representative Reddit posts.
   - Clicks through to original Reddit threads to read context.

3. **Adjust scoring & patterns**
   - User changes relative weights of frequency, engagement, and pain intensity in the scoring config.
   - User adds/edits text patterns (e.g., different “I wish there was” variations).
   - Re‑runs scoring and inspects how rankings change.

4. **Add a new niche**
   - User adds a new subreddit or keyword query in configuration.
   - Next scheduled run pulls that data, and new opportunities appear on dashboards.

---

## 6. Functional Requirements

Functional requirements are V1‑scoped, prioritized using Must/Should/May.

### 6.1 Ingestion & Storage (Bronze)

- **FR‑001 (MUST):** The system SHALL ingest posts from configured subreddits and queries using Reddit’s API on a scheduled basis (e.g., daily).
- **FR‑002 (MUST):** The system SHALL store raw responses in `reddit_raw_posts` (and optionally `reddit_raw_comments`) preserving original fields and timestamps.
- **FR‑003 (MUST):** The ingestion process SHALL be idempotent for a given time window (no duplicate rows for the same Reddit IDs).
- **FR‑004 (SHOULD):** The system SHOULD support backfill runs for historical ranges (e.g., “re‑ingest last 7 days”).

### 6.2 Validation & Data Quality

- **FR‑005 (MUST):** The system SHALL enforce basic schema and constraints (non‑null IDs, types) via database schema and dbt tests.
- **FR‑006 (MUST):** The system SHALL route malformed rows into an error table (`reddit_ingest_errors`) rather than failing silently.
- **FR‑007 (SHOULD):** The system SHOULD track simple daily row counts and alert if they fall below a defined threshold.

### 6.3 Modeling & Enrichment (Silver)

- **FR‑008 (MUST):** The system SHALL produce staging tables (`stg_reddit_posts`, `stg_reddit_comments`) that normalize types and clean text (e.g., remove deleted/removed posts).
- **FR‑009 (MUST):** The system SHALL compute enrichment fields per post, including:
  - `is_question` (heuristic based on punctuation/phrases).
  - `matches_pain_pattern` (based on configurable regex/keywords).
  - `engagement_score` (formula over upvotes/comments/subreddit weight).
- **FR‑010 (SHOULD):** The system SHOULD compute `sentiment_score` using a lightweight lexicon‑based library (not LLM) to approximate pain intensity.

### 6.4 Pain‑Post Selection

- **FR‑011 (MUST):** The system SHALL produce `matched_pain_posts` as a subset of staging posts that satisfy:
  - `matches_pain_pattern = true`,
  - language and quality filters,
  - minimum engagement thresholds.
- **FR‑012 (SHOULD):** The system SHOULD support configuration of thresholds in a `pattern_config` table.

### 6.5 Canonicalization & Opportunity Grouping

- **FR‑013 (MUST):** The system SHALL group similar pain posts into canonical opportunities in `canonical_opportunities`.
- **FR‑014 (MUST):** Each `matched_pain_posts` row SHALL reference an `opportunity_id`.
- **FR‑015 (MUST):** Canonicalization SHALL use lightweight clustering (TF‑IDF + similarity thresholds, or similar text heuristics), not require external vector DBs or LLMs for V1.
- **FR‑016 (SHOULD):** Canonical opportunities SHOULD include:
  - `canonical_title`,
  - `representative_post_id`,
  - `first_seen_at`, `last_seen_at`,
  - `topic_keywords` or tags.

### 6.6 Scoring & Ranking (Gold)

- **FR‑017 (MUST):** The system SHALL compute `opportunity_score` as a function of:
  - frequency of posts over a recent window,
  - engagement metrics,
  - pain intensity (sentiment + frustration phrases).
- **FR‑018 (MUST):** The scoring function SHALL be parameterized by a `scoring_config` table capturing weights and thresholds.
- **FR‑019 (MUST):** The system SHALL store `config_version` / `scoring_version` on each `opportunity_rankings` row.
- **FR‑020 (MUST):** The system SHALL expose `opportunity_rankings` with per‑opportunity metrics (frequency, engagement, pain intensity, last_seen_at, score, tier).
- **FR‑021 (MAY):** Future versions MAY add competition‑related features; V1 does not include “competition score” in ranking.

### 6.7 Analytics UI & Workflows

- **FR‑022 (MUST):** Superset SHALL expose at least:
  - a “Top Opportunities” dashboard (sortable by score, filters by niche/time),
  - a “Trend Over Time” chart for a selected opportunity.
- **FR‑023 (MUST):** Users SHALL be able to click an opportunity and see:
  - summary metrics,
  - a list of representative posts with titles/snippets,
  - links back to the original Reddit threads.
- **FR‑024 (SHOULD):** Users SHOULD be able to export opportunity lists (CSV) from Superset.
- **FR‑025 (MAY):** Support a simple annotation/bookmark field per opportunity (e.g., “Shortlisted”, “Validated”) stored in an `opportunity_notes` table.

### 6.8 Operations & Alerting

- **FR‑026 (MUST):** Airflow SHALL orchestrate ingestion, modeling, canonicalization, and scoring as DAGs.
- **FR‑027 (MUST):** DAG failures SHALL trigger email and/or Slack alerts.
- **FR‑028 (SHOULD):** The system SHOULD compute basic daily health checks (row counts, freshness) and visualize them via a simple Superset “Ops” dashboard.

---

## 7. Non‑Functional Requirements

- **Reliability:**
  - ≥ 95% success rate on scheduled runs for ingestion + modeling/scoring.
  - Fail fast on schema or quality violations; prevent bad data from contaminating Gold.

- **Performance:**
  - Daily ingestion + processing for the chosen subreddits completes within 1–2 hours on a single VPS.
  - Superset queries for normal time windows (< 90 days) return in ≤ 3–5 seconds under typical load.

- **Scalability (V1):**
  - Optimized for one VPS; vertical scaling and moderate dataset growth, not multi‑region scale.

- **Security:**
  - Secrets are not stored in Git; access to Airflow/Superset is authenticated and not open to the public internet by default.

- **Cost:**
  - Infrastructure limited to a single VPS‑class instance and a PostgreSQL instance, plus free/open‑source tools.

---

## 8. Dependencies & Constraints

- Reddit API availability and policies.
- Docker, Docker Compose.
- Airflow, PostgreSQL, dbt Core, Superset.
- Python libraries for Reddit API client, text processing, and simple sentiment.

---

## 9. Risks & Open Questions

- Reddit may change API pricing or rate limits.
- Subreddit moderation changes may affect visibility of certain types of posts.
- Canonicalization quality heavily depends on text heuristics; requires tuning with real data.

---

## 10. Milestones (High‑Level)

1. Infra + basic ingestion running on VPS.
2. Clean staging + enrichment + pain‑post selection.
3. Canonicalization and basic opportunity scoring.
4. Superset dashboards and drill‑down.
5. Alerting, backfill, and documentation.