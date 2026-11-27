# Containerized NGINX Deployment and Monitoring with DevOps Automation

[![CI/CD Pipeline](https://github.com/OmoloyeNaeema/devops-intern-final/actions/workflows/ci.yml/badge.svg)](https://github.com/OmoloyeNaeema/devops-intern-final/actions/workflows/ci.yml)

An end-to-end DevOps project demonstrating containerisation, automated CI/CD, application deployment using HashiCorp Nomad, service discovery with Consul, and log monitoring using Grafana Loki, Promtail and Grafana.

## 1. Project Overview

This project deploys a containerised NGINX web application and automates its build, testing and publishing process using GitHub Actions.

The application is deployed locally using HashiCorp Nomad, with Consul performing HTTP health checks. Loki, Promtail and Grafana provide centralised log collection and visualisation.

## 2. Technologies Used

- Linux (Ubuntu 24.04 on WSL2)
- Git and GitHub
- Docker and Docker Compose
- NGINX
- Bash and ShellCheck
- GitHub Actions
- GitHub Container Registry (GHCR)
- HashiCorp Nomad
- HashiCorp Consul
- Grafana Loki
- Promtail
- Grafana

## 3. Project Structure


devops-intern-final/
├── .github/
│   └── workflows/
│       └── ci.yml
├── app/
│   ├── Dockerfile
│   ├── index.html
│   └── nginx.conf
├── docs/
│   └── screenshots/
├── monitoring/
│   ├── docker-compose.yaml
│   ├── loki-config.yaml
│   ├── promtail-config.yaml
│   └── loki_setup.md
├── nomad/
│   └── nginx-app.nomad.hcl
├── scripts/
│   ├── healthcheck.sh
│   └── sysinfo.sh
├── .gitignore
└── README.md


## 4. Architecture


                 Developer
                     |
                     v
                GitHub Repo
                     |
                     v
               GitHub Actions
              /      |       \
          Lint     Build     Test
                     |
                     v
                   GHCR
                     |
                     v
              HashiCorp Nomad
                     |
                     v
                NGINX App
                     |
               Consul Health
                  Checks

NGINX Allocation Logs
          |
          v
       Promtail
          |
          v
         Loki
          |
          v
       Grafana


## 5. Application Details

The application is served by NGINX on port `8080`.

Features:
- Custom HTML landing page.
- Assessment author and date displayed.
- Build identifier injected during Docker image creation.
- `/healthz` endpoint returning HTTP 200.
- Non-root NGINX container execution.
- Docker health check.

### Build the Docker Image

```bash
docker build --build-arg BUILD_SHA=local-test -t devops-intern-final:v1 ./app
```

### Run the Application

```bash
docker run -d --name devops-nginx -p 8080:8080 devops-intern-final:v1
```

Open:

`http://localhost:8080`

### Test the Health Endpoint

```bash
curl -i http://localhost:8080/healthz
```

Expected response:


HTTP/1.1 200 OK
healthy


## 6. Shell Scripts

Two Bash scripts are included.

### System Information

```bash
chmod +x scripts/sysinfo.sh
./scripts/sysinfo.sh
```

Displays:
- Current user and effective UID.
- Hostname and kernel information.
- Current UTC date.
- Disk usage.
- Memory usage.
- Docker daemon status.

### Application Health Check

```bash
chmod +x scripts/healthcheck.sh
./scripts/healthcheck.sh
```

The script checks whether the application responds with HTTP 200.

It also accepts a custom URL:

```bash
./scripts/healthcheck.sh http://localhost:8080
```

A successful check displays:


SUCCESS: Application is healthy (HTTP 200)


## 7. CI/CD Pipeline

GitHub Actions automates the application workflow.

The pipeline includes:

1. Shell script linting using ShellCheck.
2. Docker image build.
3. Application health testing.
4. Publishing the Docker image to GitHub Container Registry.

The workflow runs on pushes to `main` and the CI feature branch, and on pull requests targeting `main`.

Publishing is restricted to pushes to `main`.

Published image:

`ghcr.io/omoloyenaeema/devops-intern-final:latest`

The pipeline also publishes an image tagged with the Git commit SHA.

View the workflow:

[GitHub Actions](https://github.com/OmoloyeNaeema/devops-intern-final/actions)

## 8. Nomad Deployment and Consul

The application is deployed using the Docker driver in HashiCorp Nomad.

The job specification is:

`nomad/nginx-app.nomad.hcl`

Deployment requirements include:
- One application allocation.
- 100 MHz CPU.
- 64 MB memory.
- Dynamic HTTP port mapped to container port 8080.
- Consul HTTP health check on `/healthz`.
- Restart and rescheduling policies.
- Deployment update and automatic rollback settings.

### Validate the Job

```bash
nomad job validate nomad/nginx-app.nomad.hcl
```

### Plan the Deployment

```bash
nomad job plan -var="image_tag=latest" nomad/nginx-app.nomad.hcl
```

### Deploy the Application

```bash
nomad job run -var="image_tag=latest" nomad/nginx-app.nomad.hcl
```

### Check Job Status

```bash
nomad job status nginx-app
```

### Check Consul Health

```bash
curl http://localhost:8500/v1/health/checks/nginx-app
```

The Consul HTTP health check was verified with a passing status and an HTTP 200 response from the application health endpoint.

## 9. Monitoring with Loki, Promtail and Grafana

The monitoring stack collects NGINX allocation logs from Nomad and makes them available in Grafana.

### Start the Monitoring Stack

```bash
docker compose -f monitoring/docker-compose.yaml up -d
```

### Services

| Service | Port | Purpose |
|---|---:|---|
| Loki | 3100 | Log storage |
| Promtail | 9080 (internal) | Log collection |
| Grafana | 3000 | Log visualisation |

### Verify Loki

```bash
curl http://localhost:3100/ready
```

Expected response:


ready


### Configure Grafana

1. Open `http://localhost:3000`.
2. Configure Loki as a data source.
3. Use `http://loki:3100` as the Loki URL.
4. Save and test the data source.
5. Open Explore and select Loki.

### LogQL Queries

Display application logs:

   logql
{job="nomad-nginx", service="nginx-app"}


Filter HTTP 200 responses:

   logql
{job="nomad-nginx", service="nginx-app"} |= " 200 "


Filter HTTP 404 responses:

   logql
{job="nomad-nginx", service="nginx-app"} |= " 404 "


### Monitoring Verification

The monitoring pipeline was tested using requests to the Nomad-deployed application.

Successful request:

```bash
curl -i http://127.0.0.1:27571/
```

Unsuccessful request:

```bash
curl -i http://127.0.0.1:27571/this-page-does-not-exist
```

Both requests appeared in Grafana Explore.

Observed results:
- 11 log entries displayed.
- 1.05 kB total bytes processed.
- HTTP 200 request recorded.
- HTTP 404 request recorded.
- Common labels included `job=nomad-nginx` and `service=nginx-app`.

More details are available in [monitoring/loki_setup.md](monitoring/loki_setup.md).

## 10. Screenshots

Grafana Explore verification screenshots:

- `docs/screenshots/grafana-explore.png`
- `docs/screenshots/grafana-explore2.png`

These screenshots show the LogQL query and collected NGINX application logs.

## 11. Troubleshooting

### Issue 1: Nomad Agent Port Conflict

**Problem:** Nomad could not start because another Nomad agent was already using the development port.

**Resolution:** Identified and stopped the previous Nomad agent process before restarting Nomad with an explicit data directory.

### Issue 2: Nomad Reschedule Validation

**Problem:** The reschedule policy had conflicting settings for retry attempts and unlimited rescheduling.

**Resolution:** Set `unlimited = false` alongside the configured retry attempts.

### Issue 3: Consul Health Check CLI

**Problem:** The attempted `consul health checks nginx-app` command was unsupported by the installed Consul CLI.

**Resolution:** Used the Consul HTTP API endpoint instead:

```bash
curl http://localhost:8500/v1/health/checks/nginx-app
```

## 12. Known Limitations

- Nomad and Consul are running in development mode for local testing.
- The monitoring stack is configured for local development.
- Promtail currently collects NGINX standard output logs from Nomad allocation directories.
- Loki authentication is disabled in this development configuration.
- The Nomad and Consul agents must remain running for the local deployment to operate.

This setup is intended for demonstration and learning, not production deployment without additional security and high-availability configuration.

## 13. Quick Start

The following commands assume Docker is running and the required Nomad and Consul development agents have been started.

From the project root:

```bash
docker build --build-arg BUILD_SHA=local -t devops-intern-final:v1 ./app
docker run -d --name devops-nginx -p 8080:8080 devops-intern-final:v1
./scripts/healthcheck.sh
nomad job validate nomad/nginx-app.nomad.hcl
nomad job run -var="image_tag=latest" nomad/nginx-app.nomad.hcl
nomad job status nginx-app
docker compose -f monitoring/docker-compose.yaml up -d
curl http://localhost:3100/ready
```

Open `http://localhost:3000` to explore application logs in Grafana.

## 14. Repository

GitHub Repository:

https://github.com/OmoloyeNaeema/devops-intern-final

**Release target:** `v1.0.0`