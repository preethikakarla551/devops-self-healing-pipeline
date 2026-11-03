# Self-Healing DevOps CI/CD Pipeline for AWS EC2

![Build Status](https://img.shields.io/github/actions/workflow/status/preethikakarla551/devops-self-healing-pipeline/deploy.yml?branch=main&label=CI/CD%20Pipeline)
![AWS](https://img.shields.io/badge/AWS-EC2-orange?logo=amazon-aws)
![Docker](https://img.shields.io/badge/Docker-Compose-blue?logo=docker)
![Nginx](https://img.shields.io/badge/Nginx-Reverse%20Proxy-green?logo=nginx)
![Flask](https://img.shields.io/badge/Flask-Microservice-black?logo=flask)

An automated, fault-tolerant DevOps pipeline featuring continuous integration/continuous deployment (CI/CD) and automated self-healing capabilities for a Flask microservice deployed on AWS EC2.

---

## Architecture & System Design Flow

The project consists of three main operational phases: **CI/CD Deployment**, **Production Runtime Routing**, and **Automated Self-Healing**.

```mermaid
graph TD
    %% 1. Deployment Phase
    subgraph 1. CI/CD Deployment Trigger
        A[Developer Push to main] -->|Git Push| B[GitHub Repository]
        B -->|Triggers Workflow| C[GitHub Actions Runner]
        C -->|SSH Auth via EC2_SSH_KEY| D[AWS EC2 Instance 52.66.249.190]
    end

    %% 2. Execution & Ingress Phase
    subgraph 2. Production Runtime Environment
        D -->|Pulls Code & Rebuilds| E[Docker Compose]
        E -->|Runs Container| F[Flask Web App web_app :5000]
        G[Public User / Client] -->|HTTP Request Port 80| H[Nginx Reverse Proxy]
        H -->|Proxy Pass [http://127.0.0.1:5000](http://127.0.0.1:5000)| F
    end

    %% 3. Self-Healing Phase
    subgraph 3. Automated Self-Healing Mechanism
        I[Linux Crontab */2 * * * *] -->|Executes Every 2 Min| J[scripts/health_check.sh]
        J -->|Polls GET /health| F
        J -- HTTP 200 OK --> K[Log Healthy Status]
        J -- HTTP Error / Timeout --> L[Trigger docker restart web_app]
        L -->|Auto-Recovery| F
        L -->|Audit Record| M[Write to /var/log/app_health.log]
    end
