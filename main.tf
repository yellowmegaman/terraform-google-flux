#%# RBAC not templated
resource "kubernetes_service_account" "flux" {
  metadata {
    name = "flux"
      labels = {
        ip = var.ingress_ip
      }
  }
  automount_service_account_token = "true"
}

resource "kubernetes_cluster_role" "flux" {
  metadata {
    name = "flux"
      labels = {
        ip = var.ingress_ip
      }
  }

  rule {
    #%# full access for now
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
  rule {
    non_resource_urls = ["*"]
    verbs             = ["*"]
  }
}

resource "kubernetes_cluster_role_binding" "flux" {
  metadata {
    name = "flux"
      labels = {
        ip = var.ingress_ip
      }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "flux"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "flux"
    namespace = "default"
  }
}

resource "kubernetes_secret" "flux-key" {
  metadata {
    name = "flux-key"
      labels = {
        ip = var.ingress_ip
      }
  }
  data = {
    "identity" = base64decode(var.flux_key)
  }
}

#%# flux deployment templated
resource "kubernetes_deployment" "flux" {
  metadata {
    name = "flux"
      labels = {
        ip = var.ingress_ip
      }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        name = "flux"
      }
    }
    strategy {
      type = "Recreate"
    }
    template {
      metadata {
        labels = {
          name = "flux"
        }
        annotations = {
          "prometheus.io.port" = "3031"
        }
      }
      spec {
        service_account_name = "flux"
        automount_service_account_token = "true"
        container {
          name  = "flux"
          image = "docker.io/weaveworks/flux:${var.flux_version}"
          args  = ["--memcached-service=", "--git-timeout=100s", "--ssh-keygen-dir=/var/fluxd/keygen", "--git-url=${var.repo}", "--git-branch=${var.cluster_name}", "--listen-metrics=:3031", "--git-poll-interval=${var.poll_interval}", "--sync-interval=${var.sync_interval}", "--sync-garbage-collection", "--git-path=${var.manifests_path}", "--git-ci-skip-message=[SKIP CI]", "--git-label=flux${var.cluster_name}", "--manifest-generation=true"]
          env {
            name = "ENVNAME"
            value = var.cluster_name
          }
          env {
            name = "LBIP"
            value = var.ingress_ip
          }
          env {
            name = "ENVDOMAIN"
            value = var.domain_name
          }
          volume_mount {
            name       = "git-key"
            mount_path = "/etc/fluxd/ssh"
            read_only  = true
          }
          volume_mount {
            name       = "git-keygen"
            mount_path = "/var/fluxd/keygen"
          }
          image_pull_policy = "IfNotPresent"
          resources {
            limits {
              cpu    = "100m"
              memory = "128Mi"
            }
            requests {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
          port {
            name = "main"
            container_port = "3030"
          }
          liveness_probe {	
            tcp_socket {	
              port = 3030	
            }	
            initial_delay_seconds = 3	
            period_seconds        = 3	
          }
        }
        volume {
          name = "git-key"
          secret {
            secret_name = "flux-key"
            default_mode = "0400"
          }
        }
        volume {
          name = "git-keygen"
          empty_dir {
            medium = "Memory"
          }
        }
      }
    }
  }
}

#%# memcached not templated
resource "kubernetes_service" "memcached" {
  metadata {
    name = "memcached"
      labels = {
        ip = var.ingress_ip
      }
  }
  spec {
    selector = {
      name = "memcached"
    }
    port {
      port        = var.memcached_port
      target_port = var.memcached_port
    }
  }
}
resource "kubernetes_deployment" "memcached" {
  metadata {
    name = "memcached"
      labels = {
        ip = var.ingress_ip
      }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        name = "memcached"
      }
    }
    template {
      metadata {
        labels = {
          name = "memcached"
        }
      }
      spec {
        container {
          name  = "memcached"
          image = "memcached:${var.memcached_version}"
          args  = ["-I 5m", "-p ${var.memcached_port}"]
          image_pull_policy = "IfNotPresent"
          security_context {
            run_as_user =  var.memcached_port
            allow_privilege_escalation = "false"
          }
          resources {
            limits {
              cpu    = "50m"
              memory = "64Mi"
            }
            requests {
              cpu    = "50m"
              memory = "64Mi"
            }
          }
          port {
            name           = "clients"
            container_port = var.memcached_port
          }
          liveness_probe {
            tcp_socket {
              port = var.memcached_port
            }
            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
}
