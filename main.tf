#%# RBAC not templated
resource "kubernetes_service_account" "flux" {
  metadata {
    name = "flux"
  }
  automount_service_account_token = "true"
}
resource "kubernetes_cluster_role" "flux" {
  metadata {
    name = "flux"
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
  }
  data = {
    "identity" = file("flux_key")
  }
}
#%# flux deployment templated
resource "kubernetes_deployment" "flux" {
  metadata {
    name = "flux"
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
          image = "docker.io/weaveworks/flux:1.13.1"
          args  = ["--memcached-service=", "--ssh-keygen-dir=/var/fluxd/keygen", "--git-url=git@github.com:oktossm/gitops.git", "--git-branch=master", "--listen-metrics=:3031", "--git-poll-interval=3m0s", "--sync-interval=3m0s", "--sync-garbage-collection", "--git-path=${var.cluster_name}", "--git-ci-skip-message=[SKIP CI]", "--git-label=fluxhere", "--manifest-generation=true"]
          env {
            name = "ENVNAME"
            value = var.cluster_name
          }
          env {
            name = "LBIP"
            value = var.ingress_ip
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
  }
  spec {
    selector = {
      name = "memcached"
    }
    port {
      port        = "11211"
      target_port = "11211"
    }
  }
}
resource "kubernetes_deployment" "memcached" {
  metadata {
    name = "memcached"
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
          image = "memcached:1.5.15"
          args  = ["-m 512", "-I 5m", "-p 11211"]
          image_pull_policy = "IfNotPresent"
          security_context {
            run_as_user =  "11211"
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
            container_port = "11211"
          }
          liveness_probe {
            tcp_socket {
              port = "11211"
            }
            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
}
