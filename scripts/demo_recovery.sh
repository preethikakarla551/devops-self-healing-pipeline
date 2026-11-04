#!/usr/bin/env bash
set -Eeuo pipefail

container="${1:-web_app}"
url="${APP_HEALTH_URL:-http://127.0.0.1:5000/health}"
timeout_seconds="${RECOVERY_TIMEOUT_SECONDS:-45}"

if ! docker inspect "$container" >/dev/null 2>&1; then
  echo "Container '$container' is not present. Start the stack with: docker compose up -d --build" >&2
  exit 1
fi

initial_status="$(docker inspect --format '{{.State.Status}}' "$container")"
if [[ "$initial_status" != "running" ]]; then
  echo "Container '$container' must be running (current status: $initial_status)." >&2
  exit 1
fi

echo "Waiting for the health endpoint to become ready: $url"
ready_deadline=$((SECONDS + timeout_seconds))
until curl --fail --silent "$url" >/dev/null 2>&1; do
  if (( SECONDS >= ready_deadline )); then
    echo "Health endpoint did not become healthy within ${timeout_seconds}s: $url" >&2
    exit 1
  fi
  sleep 1
done

# Docker only applies a restart policy after the container has been up for 10 seconds.
echo "Allowing 10 seconds for Docker's restart policy to become active."
sleep 10

if ! curl --fail --silent --show-error "$url" >/dev/null; then
  echo "Health endpoint became unhealthy before the demonstration: $url" >&2
  exit 1
fi

initial_status="$(docker inspect --format '{{.State.Status}}' "$container")"
if [[ "$initial_status" != "running" ]]; then
  echo "Container '$container' stopped before the demonstration (current status: $initial_status)." >&2
  exit 1
fi
initial_restarts="$(docker inspect --format '{{.RestartCount}}' "$container")"

echo "BEFORE: status=$initial_status restart_count=$initial_restarts health=HTTP 200"
echo "Injecting a process failure by terminating PID 1 in '$container'."
docker exec "$container" sh -c 'kill -TERM 1' >/dev/null 2>&1 || true

deadline=$((SECONDS + timeout_seconds))
while (( SECONDS < deadline )); do
  current_status="$(docker inspect --format '{{.State.Status}}' "$container" 2>/dev/null || true)"
  current_restarts="$(docker inspect --format '{{.RestartCount}}' "$container" 2>/dev/null || echo 0)"
  if [[ "$current_status" == "running" ]] && (( current_restarts > initial_restarts )); then
    if curl --fail --silent --show-error "$url" >/dev/null 2>&1; then
      echo "AFTER:  status=$current_status restart_count=$current_restarts health=HTTP 200"
      echo "PASS: Docker restarted the exited application container and the health endpoint recovered."
      exit 0
    fi
  fi
  sleep 1
done

echo "FAIL: '$container' did not restart and return HTTP 200 within ${timeout_seconds}s." >&2
docker inspect --format 'status={{.State.Status}} restart_count={{.RestartCount}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}not-configured{{end}}' "$container" >&2 || true
docker logs --tail 50 "$container" >&2 || true
exit 1
