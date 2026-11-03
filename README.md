# 🚀 Self-Healing Microservices & Observability Pipeline

[![AWS EC2](https://img.shields.io/badge/AWS-EC2-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/ec2/)
[![Docker](https://img.shields.io/badge/Docker-Containerized-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Prometheus](https://img.shields.io/badge/Prometheus-Telemetry-E6522C?logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-Visualization-F46800?logo=grafana&logoColor=white)](https://grafana.com/)
[![Python](https://img.shields.io/badge/Python-3.x-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

An enterprise-grade, 4-container microservice telemetry and self-healing infrastructure deployed on AWS EC2. This pipeline features automated health monitoring, lightweight Python container health checks, cAdvisor resource metrics ingestion, and live Grafana visualization dashboards.

---

## 🏗 Architecture Overview

```text
                      +------------------------------------+
                      |           AWS EC2 Host             |
                      |  (Ubuntu / Docker Compose Engine)  |
                      +------------------------------------+
                                         |
     +-----------------+-----------------+-----------------+-----------------+
     |                 |                                   |                 |
     v                 v                                   v v
+----------+    +--------------+                    +------------+    +------------+
| Web App  |    |   cAdvisor   |                    | Prometheus |    |  Grafana   |
| (Flask)  |<---| (Container   |                    | (Telemetry |--->| (Dashboard |
| Port 5000|    |   Metrics)   |                    |   Engine)  |    |    UI)     |
+----------+    |  Port 8080   |                    | Port 9090  |    | Port 3000  |
     ^          +--------------+                    +------------+    +------------+
     |                 |                                   ^
     +-----------------+-----------------------------------+
                             Scrape Targets Interval (5s)
