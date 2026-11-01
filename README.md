# Cloud Infrastructure Observability & Incident Response

A containerized monitoring pipeline deployed on an Oracle Cloud Infrastructure (OCI) ARM64 Ubuntu 24.04 compute instance.

## Architecture

- **Host Platform:** Oracle Cloud Infrastructure (OCI) Always-Free Ampere A1 (Ubuntu 24.04 LTS, ARM64)
- **Telemetry Collector:** Prometheus Node Exporter scraping kernel metrics from `/proc` and `/sys`
- **Time-Series Database:** Prometheus (Port 9090) scraping targets at 15-second intervals
- **Visualization:** Grafana (Port 3000) using Dashboard 1860 (Node Exporter Full)
- **Incident Pipeline:** Grafana Alertmanager routing custom PromQL threshold breaches to Discord webhooks
- **Keep-Alive Engine:** Scheduled Linux cron executing stress-ng (25% CPU for 30 minutes every 3 hours) to prevent cloud instance reclamation

## Alerting Configuration

- **Metric Query:**
  100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100)
- **Threshold:** Triggers when CPU usage exceeds 80% continuously for 1 minute (Pending = 1m).
- **Validation:** Confirmed via synthetic stress tests (stress-ng), generating automated [FIRING] and [RESOLVED] notification cards in Discord.

## Deployment

```bash
git clone [https://github.com/](https://github.com/)<your-username>/<repo-name>.git
cd <repo-name>
docker compose up -d
```
