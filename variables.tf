variable "cluster_name" {
	description = "Cluster to manage. Alse available as ENVNAME variable in flux container for templating purposes"
}
variable "ingress_ip" {
	description = "Ingress ip address. Also available as LBIP in flux container for templating purposes"
}
