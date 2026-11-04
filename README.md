# Self-Healing Flask Service with Docker Compose

A small Flask service deployed with Docker Compose on an Ubuntu host such as AWS EC2, with Prometheus, Grafana, and cAdvisor alongside it.

## What recovery this project demonstrates

The `web_app` service has Docker's `restart: always` policy and an HTTP health check for `/health`. When the Gunicorn process exits, Docker restarts the container. The health check then confirms that the application responds again.

The included recovery demonstration deliberately terminates the container's main process, waits for Docker to restart it, and verifies both an increased restart count and a healthy HTTP response. This demonstrates recovery from a process exit. A failed health check by itself marks the container unhealthy; Docker Compose's restart policy does not restart a process just because it is unhealthy.

## Run the stack

Requirements: Docker Engine and the Docker Compose plugin.

```bash
git clone https://github.com/preethikakarla551/devops-self-healing-pipeline.git
cd devops-self-healing-pipeline
docker compose up -d --build
docker compose ps
```

The Flask service is available at `http://localhost:5000/`; its health endpoint is `http://localhost:5000/health`. Prometheus, Grafana, and cAdvisor are published on ports 9090, 3000, and 8080 in the current Compose file. Restrict access to monitoring interfaces when deploying on a public host.

## Prove recovery

Run this from the repository root on the Docker host:

```bash
bash scripts/demo_recovery.sh
```

The script checks that the service is healthy before injecting the failure. It then terminates the container's main process and waits up to 45 seconds for a restart and a successful health request. A successful run prints evidence in this form:

```text
BEFORE: status=running restart_count=0 health=HTTP 200
Injecting a process failure by terminating PID 1 in 'web_app'.
AFTER:  status=running restart_count=1 health=HTTP 200
PASS: Docker restarted the exited application container and the health endpoint recovered.
```

The restart count shown in your run may differ. The script exits nonzero and prints container status and recent logs if recovery does not happen within the timeout.

You can also inspect the evidence manually:

```bash
docker inspect --format 'status={{.State.Status}} restart_count={{.RestartCount}} health={{.State.Health.Status}}' web_app
curl --fail http://localhost:5000/health
docker logs --tail 50 web_app
```

## Architecture

- `app/`: Flask application served by Gunicorn.
- `docker-compose.yml`: application, Prometheus, Grafana, and cAdvisor services. The Flask service uses a Docker health check and restart policy.
- `monitoring/prometheus.yml`: Prometheus scrape targets.
- `scripts/demo_recovery.sh`: repeatable process-failure and recovery demonstration.

## Recovery limits

This project demonstrates recovery when the application process exits. It does not automatically remediate a bad deployment, repair application bugs, or restart a process that stays alive while returning errors. The health check reports endpoint status; it does not trigger a restart on its own. The demonstration intentionally interrupts the app and causes a brief outage while Docker restarts it.

## Cleanup

```bash
docker compose down
```

## Portfolio evidence

After running the recovery demonstration on your own Docker host, capture its terminal output and include it in the repository (for example, as a screenshot in a `docs/` folder). Only claim a verified recovery in a resume or interview after you have observed a successful run.
