# Decision Log

This document captures the reasoning behind key technical decisions in this project.

## 1. Prometheus over InfluxDB / Datadog

**Decision:** Use Prometheus as the time-series database.

**Why:**
- Prometheus is the CNCF standard for cloud-native monitoring
- Pull-based model works well for infrastructure where we control the targets
- PromQL is the industry-standard query language — learning it has direct career value
- It's free and self-hosted, which matters on a free-tier OCI instance
- InfluxDB push-based model adds complexity; Datadog costs money

## 2. 15-Second Scrape Interval

**Decision:** Set `scrape_interval: 15s` instead of the default 1 minute.

**Why:**
- 15s gives good granularity for spotting CPU/memory spikes without overwhelming storage
- On a free-tier ARM instance with limited disk, 15s is a reasonable balance
- With 15-day retention and 3 scrape targets, storage stays well under 1 GB
- Going lower (5s) would increase storage and wasn't needed for this use case

## 3. Alertmanager over Grafana-native Alerting

**Decision:** Use Prometheus Alertmanager for the alerting pipeline.

**Why:**
- Alert rules live as code in `alert_rules.yml` — fully version-controlled
- Alertmanager handles deduplication, grouping, and silencing natively
- Separates concerns: Prometheus evaluates rules, Alertmanager routes notifications
- This is how production monitoring stacks work — learning the real pattern

## 4. cAdvisor for Container Metrics

**Decision:** Add cAdvisor alongside Node Exporter.

**Why:**
- Node Exporter monitors the host (CPU, memory, disk, network)
- cAdvisor monitors the containers running on that host
- Together they give complete observability — "is the host healthy?" + "are the containers healthy?"
- cAdvisor exposes container-level CPU, memory, and network — useful for per-service dashboards

## 5. Grafana Provisioning over Manual UI Setup

**Decision:** Use file-based provisioning for datasources and dashboards.

**Why:**
- Running `docker compose up -d` on a fresh machine gives you a fully working Grafana — no manual clicks
- Configuration is version-controlled and reproducible
- This is how teams manage Grafana in production — Infrastructure as Code
- Manual UI setup is fine for exploration but doesn't belong in a portfolio project

## 6. Binding to 127.0.0.1 Instead of 0.0.0.0

**Decision:** All services bind to localhost only.

**Why:**
- These are internal services — there's no reason to expose them to the internet directly
- A reverse proxy (Nginx/Caddy) should handle external access with TLS
- This prevents accidental exposure if cloud security groups are misconfigured
- Only Grafana needs external access, and that goes through the reverse proxy

## 7. Pinned Image Versions

**Decision:** Pin exact versions (e.g., `prom/prometheus:v2.51.0`) instead of `:latest`.

**Why:**
- `:latest` is not reproducible — a deploy today and tomorrow might use different versions
- Pinned versions mean the stack behaves identically on any machine, any time
- Upgrades become intentional, not accidental
- This is a basic DevOps best practice that interviewers look for

## 8. 15-Day Retention

**Decision:** Set `--storage.tsdb.retention.time=15d` for Prometheus.

**Why:**
- OCI free-tier gives limited storage (50 GB boot volume)
- 15 days is enough to spot trends and investigate recent incidents
- For longer-term storage, you'd integrate with Thanos or Grafana Mimir — out of scope here
