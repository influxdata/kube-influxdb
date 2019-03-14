# `kube-influxdb` - Monitor Kubernetes with the TICK stack

`kube-influxdb` is a set of configurations to set up monitoring of Kubernetes with [InfluxData's TICK stack](https://www.influxdata.com/time-series-platform/).
It is implemented as a collection of pre-configured [Helm charts](https://github.com/kubernetes/helm) and corresponding scripts to load Chronograf dashboards.
This repo contains the following charts:

- [influxdb: 1.7.4-alpine](/influxdb/README.md)
- [chronograf: 1.7.8-alpine](/chronograf/README.md)
- [kapacitor: 1.5.2-alpine](/kapacitor/README.md)
- [telegraf-s: 1.10.0-alpine](/telegraf-s/README.md)
- [telegraf-ds: 1.10.0-alpine](/telegraf-ds/README.md)

The `create.sh` script in the root of this repo is a helper script to deploy both the charts and their associated Chronograf dashboards.

`kube-influxdb` will work with open source Kubernetes deployed on EC2 as well as several managed Kubernetes services, including AWS' EKS, GCP's GKS, Red Hat's OpenShift. It can also be deployed locally using minikube.

## Prerequisites

_Note: For clusters running open source Kubernetes, this guide assumes the cluster has been deployed on AWS, e.g. using [kops](https://github.com/kubernetes/kops) or a similar tool._

Set your `kubectl` context to point to an active EKS cluster where you would like to deploy TICK stack.

[Install `helm`](https://github.com/kubernetes/helm/blob/master/docs/install.md) on your local development machine.

Run `helm init` to [install `tiller`](https://github.com/kubernetes/helm/blob/master/docs/install.md#installing-tiller) in your EKS cluster.

If running on AWS, open ports `30000` through `35000` in the security group for `NodePort`.

### Update the script and chart values

This repository contains a few helper scripts to bootstrap monitoring in a cluster (`create.sh` and everything in the `/scripts` directory). Some values in these scripts need to be updated:

Grab the Kubernetes API URL for your EKS cluster using the following `kubectl` command.

```sh
> kubectl cluster-info
Kubernetes master is running at https://tickstackcluster.com
CoreDNS is running at https://tickstackcluster.com/api/v1/namespaces/kube-system/services/kube-dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

Based on the Kubernetes platform being used, replace the value of `cluster_name` with your Kubernetes master URL, i.e. `tickstackcluster.com` in the output of `kubectl cluster-info` above, in the script located in the `/scripts` directory, e.g. `scripts/aws-eks.sh`, `gcp.sh`, `openshift.sh`, or `oss-k8s.ash`.

```sh
# Search for `cluster_name` in the script and replace the value 'api.tickstackcluster.com' with actual k8S cluster name or dns.
cluster_name="tickstackcluster.com"
```

In `kapacitor/values.yaml`, set the value of `influxUrl` to your cluster's master URL. Leave the port set to `30082`.

```yaml
# Search for `influxURL` in the yaml and replace the value 'api.tickstackcluster.com' with actual cluster Name.
influxURL: "http://tickstackcluster.com:30082"
```

In `telegraf-ds/values.yaml`, set the value of `influxUrl` to your cluster's master URL. Leave the port set to `30082`.

```yaml
# Search for `influxdb` in the yaml and Replace value of url 'api.tickstackcluster.com' with actual cluster Name.
- influxdb:
  url: "http://tickstackcluster.com:30082"
```

In `telegraf-ds/values.yaml`, set the value of `prometheus` to your cluster's master URL. Leave the ports set to `30080` and `30081`.

```yaml
# Search for `prometheus` in the yaml and Replace value 'api.tickstackcluster.com' at 2 places in urls with actual cluster Name.
- prometheus:
  urls: ["http://tickstackcluster.com:30080/metrics","http://tickstackcluster.com:30081/metrics"]
```

In `telegraf-s/values.yaml`, set the value of `influxdb` and `kapacitor` for your cluster's master URL. Leave the ports set to `30082` and `30083`.

```yaml
- influxdb:
  urls:
    - "http://tickstackcluster.com:30082"
- kapacitor:
  urls:
    - "http://tickstackcluster.com:30083"
```

There are some additional steps for depending on which flavor of Kubernetes you are using.

### For OSS Kubernetes clusters

Have a `daemon-set` configuration on the `master node` of the cluster for `telegraf-ds`
Execute following command on master node.

```sh
# Note: You need to ssh to master node to execute above command. Replace `ip-x-x-x-x` from `<ip-x-x-x-x.ec2.internal>` with cluster's master node private ip.
kubectl taint nodes <ip-x-x-x-x.ec2.internal> node-role.kubernetes.io/master:NoSchedule-
```

### For OpenShift clusters

_Warning! Deploying Helm charts to an OpenShift cluster can make the cluster less secure. Please read the latest documentation on using Helm with OpenShift before continuing._

Run following commands to add RBAC permissions.

```sh
oc adm policy add-cluster-role-to-user cluster-admin admin
oc adm policy add-scc-to-user hostaccess -z default
oc annotate namespace tick openshift.io/node-selector=""
```

## Usage

After completing the steps above, run the `create.sh` script in the root of the repo.

```sh
./create.sh -s $service -a action -c $component
  - Options:
    -s service:  The name of the service.
             Valid options are `influxdb`, `kapacitor`, `telegraf-s`, `telegraf-ds`, `chronograf` and `all`
    -a action: Valid options are `create` and `destroy`
    -c component: Valid options are `oss-k8s`, `aws-eks`, `gcp`, `openshift` and `minikube`
```

### Examples

To deploy all components with a single command:

```sh
./create.sh -s all -a create -c oss-k8s
./create.sh -s all -a destroy -c oss-k8s
```

To deploy a single TICK component:

```sh
./create.sh -s influxdb -a create -c oss-k8s
./create.sh -s influxdb -a destroy -c oss-k8s
```

### Post-deployment

Once complete, the script will print endpoints for Chronograf and InfluxDB.
Use the Chronograf endpoint URL to access the Chronograf dashboard.
Use the Influxdb endpint URL to add a new InfluxDB connection.
Replace the connection string with the InfluxDB endpoint URL.
