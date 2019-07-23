# Weaveworks flux deployment template

For use with terraform kubernetes provider

Usage:

```
module "flux" {
  source  = "yellowmegaman/flux/google"
  version = "0.1.0"
  cluster_name = google_container_cluster.mycluster.name
  ingress_ip = google_compute_address.my-static-ip-for-mycluster.address
}
```
