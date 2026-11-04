from time import perf_counter

from flask import Flask, Response, g, jsonify, request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

app = Flask(__name__)

HTTP_REQUESTS = Counter(
    "flask_http_requests_total",
    "Total HTTP requests handled by the Flask application.",
    ("method", "endpoint", "status"),
)
HTTP_REQUEST_DURATION = Histogram(
    "flask_http_request_duration_seconds",
    "HTTP request duration in seconds.",
    ("method", "endpoint"),
)


@app.before_request
def start_request_timer():
    g.request_started_at = perf_counter()


@app.after_request
def record_request_metrics(response):
    if request.endpoint != "metrics":
        endpoint = request.endpoint or "unmatched"
        HTTP_REQUESTS.labels(request.method, endpoint, str(response.status_code)).inc()
        HTTP_REQUEST_DURATION.labels(request.method, endpoint).observe(
            perf_counter() - g.request_started_at
        )
    return response

@app.route("/")
def home():
    return jsonify({
        "status": "healthy",
        "service": "DevOps Microservice Portal",
        "version": "1.0.0"
    }), 200

@app.route("/health")
def health():
    return jsonify({"status": "UP"}), 200


@app.route("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
