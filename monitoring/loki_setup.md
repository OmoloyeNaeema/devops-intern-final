# Loki, Promtail and Grafana Monitoring Setup

## 1. Overview

This project uses Grafana Loki, Promtail and Grafana to collect, store and visualize NGINX application logs.

- **Loki:** Stores and makes application logs searchable.
- **Promtail:** Collects NGINX logs from Nomad allocation log files and forwards them to Loki.
- **Grafana:** Provides an interface for querying and viewing logs.

## 2. Architecture

NGINX Application (Nomad)
          |
          v
  Nomad Allocation Logs
          |
          v
       Promtail
          |
          v
         Loki
          |
          v
       Grafana
```

## 3. Start the Monitoring Stack

From the project root, run:

```bash
docker compose -f monitoring/docker-compose.yaml up -d
```

Check that the containers are running:

```bash
docker ps
```

The monitoring stack contains:

- Loki on port `3100`
- Grafana on port `3000`
- Promtail collecting application logs

Check Loki readiness:

```bash
curl http://localhost:3100/ready
```

Observed response:


ready

## 4. Promtail Log Collection and Labels

Promtail scrapes NGINX standard output logs from Nomad allocation directories.

The host allocation directory is mounted into the Promtail container:


Host:      $HOME/nomad-dev-data/alloc
Container: /var/lib/nomad/alloc


The scrape configuration uses:


/var/lib/nomad/alloc/*/alloc/logs/nginx.stdout.*


The following labels are attached to the log stream:

| Label | Value |
|---|---|
| `job` | `nomad-nginx` |
| `container` | `nginx` |
| `service` | `nginx-app` |

These labels make it possible to identify and filter the NGINX application logs in Grafana.

## 5. Configure Grafana

1. Open `http://localhost:3000` in your browser.
2. Log in using the initial local credentials:
   - Username: `admin`
   - Password: `admin`
3. Change the password if prompted.
4. Navigate to **Connections → Data sources**.
5. Select **Add data source** and choose **Loki**.
6. Set the connection URL to:

```text
http://loki:3100
```

7. Click **Save & test**.

## 6. LogQL Queries

Open **Explore** in Grafana and select Loki.

### Display application logs

logql
{job="nomad-nginx", container="nginx", service="nginx-app"}

### Filter successful HTTP requests

```logql
{job="nomad-nginx", container="nginx", service="nginx-app"} |= " 200 "
```

### Filter unsuccessful HTTP requests

```logql
{job="nomad-nginx", container="nginx", service="nginx-app"} |= " 404 "
```

## 7. Verification Results

The monitoring pipeline was tested using requests to the Nomad-deployed NGINX application.

### Successful request

```bash
curl -i http://127.0.0.1:27571/
```

Observed result: `HTTP/1.1 200 OK`.

### Unsuccessful request

```bash
curl -i http://127.0.0.1:27571/this-page-does-not-exist
```

Observed result: `HTTP/1.1 404 Not Found`.

### Grafana Explore results

The first log ingestion check displayed:

- 11 log entries.
- 1.05 kB total bytes processed.
- HTTP 200 and HTTP 404 access log entries.

After adding the `container` label and recreating Promtail, a new query displayed:

- 2 fresh log entries.
- 219 bytes processed.
- One HTTP 200 request.
- One HTTP 404 request.
- All three expected labels: `job`, `container` and `service`.

The final query used:

```logql
{job="nomad-nginx", container="nginx", service="nginx-app"}
```

This verified that Promtail successfully collected the fresh NGINX logs and Loki made them available in Grafana.

## 8. Problems Encountered and Resolutions

### Problem 1: Loki readiness delay

**Problem:** The first Loki readiness check returned HTTP 503 because the ingester was still initializing.

**Resolution:** Waited for Loki to finish starting and checked readiness again. Loki subsequently returned `ready`.

### Problem 2: Promtail container restart failure

**Problem:** After updating the Promtail configuration, restarting the existing container failed with a Docker Desktop bind-mount error reporting `no such file or directory`.

**Resolution:** Confirmed that `monitoring/promtail-config.yaml` existed and recreated only the Promtail container using:

```bash
docker compose -f monitoring/docker-compose.yaml up -d --force-recreate promtail
```

Promtail then started successfully, loaded the updated configuration and began watching the Nomad allocation log directory.

### Problem 3: Verifying the container label

**Problem:** The original Promtail configuration did not include the required `container` label.

**Resolution:** Added `container: nginx` to the Promtail static labels, validated the Docker Compose configuration, recreated Promtail and ran a new Grafana Explore query. The updated query displayed the expected `container`, `job` and `service` labels.

## 9. Screenshots

Grafana Explore verification screenshots are stored in:

```text
docs/screenshots/grafana-explore.png
docs/screenshots/grafana-explore2.png
docs/screenshots/grafana-explore-labels.png
```

The screenshots provide evidence of the collected NGINX logs, HTTP status codes and final labels.

## 10. Notes and Limitations

- Promtail collects NGINX standard output logs from Nomad allocation directories.
- The monitoring stack is configured for local development and testing.
- Loki authentication is disabled in this local setup. Do not expose the monitoring ports publicly without appropriate security controls.
- The Nomad development agent and Consul development agent must remain running for the deployed application and its allocation logs to remain available.
- This setup is intended for demonstration and learning, not production deployment without additional security and high-availability configuration.