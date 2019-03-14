# kube-influxdb

This is a collection of [Helm](https://github.com/kubernetes/helm) [Charts](https://github.com/kubernetes/charts) for the [InfluxData](https://influxdata.com/time-series-platform) TICK stack. This repo contains the following charts:

- [influxdb: 1.6.3-alpine](/influxdb/README.md)
- [chronograf: 1.6.2-alpine](/chronograf/README.md)
- [kapacitor: 1.5.1-alpine](/kapacitor/README.md)
- [telegraf-s: 1.8.1-alpine](/telegraf-s/README.md)
- [telegraf-ds: 1.8.1-alpine](/telegraf-ds/README.md)

Configuration to monitor Kubernetes with the TICK stack

Run the complete TICK stack using this using create.sh script. By using `create.sh` all four official TICK stack images are deployed in kubernetes.

## Deploy the whole stack

_Note: This project will currently supported only OSS kubernetes Cluster, AWS EKS and minikube._

### Prerequisites

Set your `kubectl` context to point to an active EKS cluster where you would like to deploy TICK stack.

[Install `helm`](https://github.com/kubernetes/helm/blob/master/docs/install.md) on your local development machine.

Run `helm init` to [install `tiller`](https://github.com/kubernetes/helm/blob/master/docs/install.md#installing-tiller) in your EKS cluster.

Grab the Kubernetes API URL for your EKS cluster using the following `kubeclt` command.

```sh
> kubectl cluster-info
Kubernetes master is running at https://api.tickstackcluster.k8slab.xyz
CoreDNS is running at https://api.tickstackcluster.k8slab.xyz/api/v1/namespaces/kube-system/services/kube-dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

Record the master URL to use in following sections, i.e. `api.tickstackcluster.k8slab.xyz` in the example above to use in the following sections.

#### OSS Kubernetes Cluster

_Note: This guide assumes an open source cluster has been deployed on AWS, e.g. using [kops](https://github.com/kubernetes/kops) or another tool._

With an active cluster, open ports `30000` to `35000` in the security group for `NodePort`.

Have a `daemon-set` configuration on the `master node` of the cluster for `telegraf-ds`
Execute following command on master node.

```sh
# Note: You need to ssh to master node to execute above command. Replace `ip-x-x-x-x` from `<ip-x-x-x-x.ec2.internal>` with cluster's master node private ip.
kubectl taint nodes <ip-x-x-x-x.ec2.internal> node-role.kubernetes.io/master:NoSchedule-
```

This repository contains a few helper scripts to bootstrap monitoring in a cluster (`create.sh` and everything in the `/scripts` directory). Some values in these scripts need to be updated:

- In `scripts/aws.sh`, set `ClusterName` to the Kubernetes master URL of your cluster.

    ```sh
    # Search for `ClusterName` in the script and replace the value 'api.tickstackcluster.com' with actual k8S cluster name or dns.
    ClusterName="`api.tickstackcluster.com`"
    ```

- In `kapacitor/values.yaml`, set the value of `influxUrl` to your cluster's master URL. Leave the port set to `30082`.

    ```sh
    # Search for `influxURL` in the yaml and replace the value 'api.tickstackcluster.com' with actual cluster Name.
    influxURL: http://`api.tickstackcluster.com`:30082
    ```

- In `telegraf-ds/values.yaml`, set the value of `influxUrl` to your cluster's master URL. Leave the port set to `30082`.

    ```sh  
    # Search for `influxdb` in the yaml and Replace value of url 'api.tickstackcluster.com' with actual cluster Name.
    - influxdb:
      url: "http://`api.tickstackcluster.com`:30082"
    ```

- In `telegraf-ds/values.yaml`, set the value of `prometheus` to your cluster's master URL. Leave the ports set to `30080` and `30081`.

    ```sh
    # Search for `prometheus` in the yaml and Replace value 'api.tickstackcluster.com' at 2 places in urls with actual cluster Name.
    - prometheus:
      urls: ["http://`api.tickstackcluster.com`:30080/metrics","http://`api.tickstackcluster.com`:30081/metrics"]
    ```

- In `telegraf-s/values.yaml`, set the value of `influxdb` and `kapacitor` for your cluster's master URL. Leave the ports set to `30082` and `30083`.

    ```sh
    - influxdb:
      urls:
        - "http://`api.tickstackcluster.com`:30082"
    - kapacitor:
      urls:
        - "http://`api.tickstackcluster.com`:30083"
    ```

#### AWS EKS

Deploying `kube-influxdb` on on AWS EKS requires a few changes to the `values.yaml` file. In particular, EKS requires load balancers to expose services.

- In the `values.yaml` files of the `influxdb`, `kapacito`, `telegraf-s` and `chronograf` folders, change the service type from `NodePort` to `LoadBalancer`.

    ```sh
    # Search for "service" in this block and replace the value of key "type" with "LoadBalancer".
    service:
      replicas: 1
        type: NodePort
    ```

- In the `kube-state-metrics-service.yaml` file inside the `kube-state-metrics` folder, change the type from `NodePort` to `LoadBalancer`.

    ```sh
    # Search for "type: NodePort" in yaml and replace the value with "LoadBalancer".
    type: NodePort
    ```

_Note: Changing the `NodePort` to `LoadBalancer` in EKS will create a load balancer._

### Usage

After completing the steps above, run the `create.sh` script in the root of the repo.

```sh
./create.sh -s $service -a action -c $component
  - Options:
    -s service:  The name of the component. 
             Valid options are `influxdb`, `kapacitor`, `telegraf-s`, `telegraf-ds`, `chronograf` and `all`
    -a action: Valid options are `create` and `destroy`
    -c component: Valid options are `oss-k8s`, `aws-eks` and `minikube`
```

#### Examples

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
