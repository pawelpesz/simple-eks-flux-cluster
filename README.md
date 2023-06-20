# simple-eks-flux-cluster

Simple EKS cluster with Flux for GitOps and Prometheus, Grafana, Loki as the observability stack.

Policies required for the Terraform user/role:

* `AmazonEC2FullAccess`
* `AutoScalingFullAccess`
* `SimpleEKSPolicy` defined in the included JSON file.
