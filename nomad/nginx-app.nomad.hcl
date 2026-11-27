
variable "image_tag" {
  type    = string
  default = "latest"
}

job "nginx-app" {
  datacenters = ["dc1"]
  type        = "service"

  update {
    max_parallel      = 1
    min_healthy_time  = "10s"
    healthy_deadline  = "2m"
    auto_revert       = true
  }

  group "nginx" {
    count = 1

    network {
      port "http" {
        to = 8080
      }
    }

    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    reschedule {
      attempts = 3
      interval = "1h"
      delay    = "30s"
      unlimited = false
    }

    task "nginx" {
      driver = "docker"
      shutdown_delay = "5s"

      config {
        image = "ghcr.io/omoloyenaeema/devops-intern-final:${var.image_tag}"
        ports = ["http"]
      }

      resources {
        cpu    = 100
        memory = 64
      }

      service {
        name     = "nginx-app"
        provider = "consul"
        port     = "http"


        check {
          type     = "http"
          path     = "/healthz"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
