<div align="center">

# ⚡ Self-Healing Microservices & Observability Pipeline

[![AWS EC2](https://img.shields.io/badge/Infrastructure-AWS_EC2-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com/ec2/)
[![Docker Compose](https://img.shields.io/badge/Containers-Docker_Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Prometheus](https://img.shields.io/badge/Metrics-Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Observability-Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)](https://grafana.com/)
[![Python](https://img.shields.io/badge/Language-Python_3.x-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)

**A containerized Flask service with health monitoring, Prometheus metrics, and Grafana dashboards—deployed on an AWS EC2 host.**

[Architecture](#-architecture) •
[Services](#-services) •
[Run locally](#-run-locally) •
[Deploy on EC2](#-deploy-on-aws-ec2) •
[Observability](#-observability) •
[Security and cost](#-security-and-cost)

</div>

---

## 📌 Project overview

This project brings together a web service and an observability stack in a four-container Docker Compose deployment:

- **Flask + Gunicorn** serves the application.
- **cAdvisor** collects container resource metrics.
- **Prometheus** scrapes and stores metrics.
- **Grafana** queries Prometheus for dashboards and operational visibility.

The stack is designed to demonstrate container health checks, restart policies, and telemetry collection on an Ubuntu LTS EC2 instance. Recovery behavior depends on the health checks and restart policies configured in the Compose files.

## 🏗️ Architecture

~~~mermaid
flowchart LR
    User["Operator"] -->|Browser :3000| Grafana

    subgraph EC2["AWS EC2 · Ubuntu LTS"]
        subgraph Compose["Docker Compose network"]
            App["Flask + Gunicorn<br/>Web service · :5000"]
            Cadvisor["cAdvisor<br/>Container metrics · :8080"]
            Prometheus["Prometheus<br/>Time-series metrics · :9090"]
            Grafana["Grafana<br/>Dashboards · :3000"]
        end

        Cadvisor -->|Reads container runtime metrics| Docker["Docker host"]
        App -->|Application metrics endpoint<br/>as configured| Prometheus
        Cadvisor -->|Resource metrics| Prometheus
        Grafana -->|PromQL queries| Prometheus
    end
~~~

> Keep Prometheus and cAdvisor private to the host or Compose network. Publish only the ports operators and users actually need.

## 🧩 Services

| Service | Role | Container port |
|---|---|---:|
| Flask + Gunicorn | Serves the web application | 5000 |
| cAdvisor | Exposes container resource metrics | 8080 |
| Prometheus | Scrapes and stores time-series metrics | 9090 |
| Grafana | Displays dashboards and queries Prometheus | 3000 |

Actual host port mappings and metrics paths are defined by the Compose and Prometheus configuration in this repository.

## 🚀 Run locally

### Prerequisites

- Docker Desktop or Docker Engine with the Compose plugin
- The project source and its Docker Compose file

From the repository root—the directory containing the Compose file—validate the configuration and start the stack:

~~~bash
docker compose config
docker compose up --build -d
~~~

Check container status and follow logs:

~~~bash
docker compose ps
docker compose logs -f
~~~

If the Compose file publishes the ports listed above, open:

- Application: <http://localhost:5000>
- Prometheus: <http://localhost:9090>
- Grafana: <http://localhost:3000>
- cAdvisor: <http://localhost:8080>

Stop the stack when finished:

~~~bash
docker compose down
~~~

This stops and removes the containers and network created by Compose. Named volumes are retained unless you explicitly remove them.

## ☁️ Deploy on AWS EC2

1. Launch an Ubuntu LTS EC2 instance sized for the application and monitoring workload.
2. Use an EC2 security group that allows SSH only from your trusted IP address.
3. Install Docker Engine and the Docker Compose plugin using the current official Docker instructions for Ubuntu.
4. Clone or copy this repository onto the instance.
5. Review the Compose configuration, environment variables, port mappings, and persistent volumes.
6. Start the stack from the repository root:

   ~~~bash
   docker compose up --build -d
   ~~~

7. Verify service status with **docker compose ps**, then review logs with **docker compose logs -f**.

For remote access, allow only the required application port to its intended audience. Restrict Grafana to trusted operator IPs and keep Prometheus and cAdvisor inaccessible from the public internet.

## 📊 Observability

- **Prometheus** collects application and container metrics according to its scrape configuration.
- **cAdvisor** provides container-level CPU, memory, network, and filesystem telemetry.
- **Grafana** can query Prometheus to display trends and operational dashboards.
- **Health checks** report service health; restart policies define how exited containers are handled.

To verify telemetry, confirm that the configured scrape targets are reachable in Prometheus and that Grafana uses the correct Prometheus data source.

## 🔐 Security and cost

- Do not expose the Docker daemon or Docker socket to the public internet.
- Use a strong Grafana administrator password and store secrets outside source control.
- Restrict SSH and monitoring access with security group rules.
- Prefer an EC2 instance role for AWS access instead of long-lived access keys.
- EC2 compute, EBS storage, public IPv4 addresses, load balancers, and data transfer can incur charges. Stop or terminate the instance when it is no longer needed, and check for retained volumes and other resources.

## 🧰 Troubleshooting

**A container exits or restarts**

~~~bash
docker compose ps
docker compose logs <service-name>
~~~

Check the service logs, health-check configuration, and restart policy in the Compose file.

**Prometheus has no application metrics**

Check the application metrics endpoint and the target address in the Prometheus scrape configuration. From inside the Compose network, targets generally use the Compose service name and container port.

**Grafana shows no data**

Confirm that Prometheus is running, that scrape targets are healthy, and that Grafana's Prometheus data source points to the Prometheus service on the Compose network.

**A browser cannot reach a service on EC2**

Confirm that the service port is published by Compose, the EC2 security group permits the intended source, and the application is listening on the container interface.

## 💼 Resume-ready summary

> Built a Docker Compose observability stack on AWS EC2 with a Flask/Gunicorn service, cAdvisor, Prometheus, and Grafana; configured health checks, container restart behavior, and runtime metrics dashboards.

Only add claims such as high availability, zero downtime, alerting, or measured recovery times after validating them in the deployed environment.

