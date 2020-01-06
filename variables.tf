variable "cluster_name" {
	description = "Cluster to manage. Alse available as ENVNAME variable in flux container for templating purposes"
}
variable "ingress_ip" {
	description = "Ingress ip address. Also available as LBIP in flux container for templating purposes"
}
variable "flux_version" {
	description = "Flux version (see https://github.com/fluxcd/flux/releases)"
	default     = "1.17.0"
}
variable "memcached_version" {
	description = "Memcached version (see https://hub.docker.com/_/memcached)"
	default     = "1.5.20"
}
variable "memcached_port" {
	default = "11211"
}
variable "repo" {
	description = "repo to sync with"
}
variable "poll_interval" {
	default = "3m0s"
}
variable "sync_interval" {
	default = "3m0s"
}
variable "manifests_path" {
	default = "manifests"
}
variable "domain_name" {
	description = "domain name to tell flux about"
}
