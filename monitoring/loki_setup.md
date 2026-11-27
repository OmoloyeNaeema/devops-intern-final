# Loki, Promtail and Grafana Monitoring Setup

## 1. Overview

This project uses Grafana Loki, Promtail and Grafana to collect, store and visualize NGINX application logs.

- **Loki:** Stores and makes application logs searchable.
- **Promtail:** Collects NGINX logs from Nomad allocation log files and forwards them to Loki.
- **Grafana:** Provides a dashboard for querying and viewing logs.

## 2. Architecture

```text
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

```Bash
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

Expected response:

```text
ready
```

## 4. Configure Grafana

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

## 5. Query Application Logs

Open **Explore** in Grafana and select Loki.

Use the following LogQL query to display application logs:

```logql
{job="nomad-nginx", service="nginx-app"}
```

To filter successful HTTP requests:

```logql
{job="nomad-nginx", service="nginx-app"} |= " 200 "
```

To filter unsuccessful HTTP requests:

```logql
{job="nomad-nginx", service="nginx-app"} |= " 404 "
```

## 6. Verification Results

The monitoring pipeline was tested using requests to the Nomad-deployed NGINX application.

Successful request:

```bash
curl -i http://127.0.0.1:27571/
```

The application returned HTTP `200 OK`.

Unsuccessful request:

```bash
curl -i http://127.0.0.1:27571/this-page-does-not-exist
```

The application returned HTTP `404 Not Found`.

Both requests appeared in Grafana Explore.

**Observed Grafana results:**

- Total log entries displayed: 11
- Total bytes processed: 1.05 kB
- Successful request: HTTP 200
- Unsuccessful request: HTTP 404
- Common labels: `job=nomad-nginx`, `service=nginx-app`

## 7. Screenshots

Grafana Explore verification screenshots are available in:

```text
docs/screenshots/grafana-explore.png
docs/screenshots/grafana-explore2.png
```

## 8. Notes and Limitations

- Promtail collects NGINX standard output logs from Nomad allocation directories.
- The monitoring stack is configured for local development and testing.
- Loki authentication is disabled in this local setup. Do not expose the monitoring ports publicly without appropriate security controls.
- The Nomad development agent and Consul development agent must remain running for the deployed application and its allocation logs to remain available.
