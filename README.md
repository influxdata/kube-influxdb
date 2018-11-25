# kube-influxdb

This is a collection of [Helm](https://github.com/kubernetes/helm) [Charts](https://github.com/kubernetes/charts) for the [InfluxData](https://influxdata.com/time-series-platform) TICK stack. This repo contains the following charts:

- [influxdb: 1.6.3-alpine](/influxdb/README.md)
- [chronograf: 1.6.2-alpine](/chronograf/README.md)
- [kapacitor: 1.5.1-alpine](/kapacitor/README.md)
- [telegraf-s: 1.8.1-alpine](/telegraf-s/README.md)
- [telegraf-ds: 1.8.1-alpine](/telegraf-ds/README.md)

Configuration to monitor Kubernetes with the TICK stack

Run the complete TICK stack using this using create.sh script. By using `create.sh` all four official TICK stack images are deployed in kubernetes.

### Deploy the whole stack!

#### Note: This project will currently supported only OSS kubernetes Cluster, AWS EKS and minikube 

### Prerequisite:

- Have your `kubectl` tool configured for the Kubernetes cluster Running AWS on where you would like to deploy TICK stack.
- Have `helm` and `tiller` installed and configured
  - Download and configure the `helm` cli
    * [link](https://github.com/kubernetes/helm/blob/master/docs/install.md)
  - Run `helm init` to install `tiller` in your cluster
    * [link](https://github.com/kubernetes/helm/blob/master/docs/install.md#installing-tiller)

- In following section you will require the k8S cluster url, Please use following kubeclt command to get k8S cluster url. 
   `kubectl cluster-info`
   
    ###### Output of the  `kubectl cluster-info` command:
   
    ```
    Kubernetes master is running at https://api.tickstackcluster.com
    
    KubeDNS is running at https://api.tickstackcluster.com/api/v1/namespaces/kube-system/services/kube-dns/proxy
    
    To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
    ```
    
    ###### Note - From above output master url is cluster name which you need to use in following sections. Don't use above 			output, it is only example to show the command output.

#### OSS kubernetes Cluster:

- Once you deploy the cluster, open the port 30000-35000 in security group for NodePort

- Have a `daemon-set` configuration on the `master node` of the cluster for `telegraf-ds`
  - Execute following command on master node. 
  
       `kubectl taint nodes <ip-x-x-x-x.ec2.internal> node-role.kubernetes.io/master:NoSchedule-`
       
    ###### Note: You need to ssh to master node to execute above command. Replace `ip-x-x-x-x` from `<ip-x-x-x-x.ec2.internal>` with cluster's master node private ip.  


- Update the following values:

  - Add the name of K8S cluster in scripts/aws.sh file. 
     ##### Search for `ClusterName` in the script and Replace value 'api.tickstackcluster.com' with actual k8S cluster name or dns.
        ClusterName="`api.tickstackcluster.com`"

  - Add the value of influxUrl in kapacitor/values.yaml. Please don't change port `30082`
     ##### Search for `influxURL` in the yaml and Replace value 'api.tickstackcluster.com' with actual cluster Name.
        influxURL: http://`api.tickstackcluster.com`:30082  

  - Add the value of influxUrl in telegraf-ds/values.yaml. Please don't change port `30082`  
     ##### Search for `influxdb` in the yaml and Replace value of url 'api.tickstackcluster.com' with actual cluster Name.
        - influxdb:
        url: "http://`api.tickstackcluster.com`:30082"

  - Add the value of prometheus in telegraf-ds/values.yaml. Please don't change port `30080`, `30081`
     #####  Search for `prometheus` in the yaml and Replace value 'api.tickstackcluster.com' at 2 places in urls with actual cluster Name.
        - prometheus:
        urls: ["http://`api.tickstackcluster.com`:30080/metrics","http://`api.tickstackcluster.com`:30081/metrics"]
  
  - Add the value of influx and kapacitor in telegraf-s/values.yaml. Please don't change port `30082`, `30083`
     ##### Search `influxdb` in this block replace urls value `api.tickstackcluster.com` with actual cluster Name. Do the similar step for `kapacitor`. Please don't change port `30082`, `30083`
        - influxdb:
           urls:
          - "http://`api.tickstackcluster.com`:30082"

        - kapacitor:
            urls:
             - "http://`api.tickstackcluster.com`:30083"

#### AWS EKS:

To work with AWS EKS service, this solution needed few changes in a file `values.yaml`. EKS required Loadbalancers to expose the services for this reason we need to changes service type to `LoadBalancer`. 

and NodePort In EKS tick stack deployment, service type is LoadBalancer, so it will create external LoadBalancer

  - Change service type from `NodePort` to `LoadBalancer` in values.yaml of `influxdb`, `kapacito`, `telegraf-s` and `chronograf` folders.
    #####  Search for `service` in this block and replace the value of key `type` with `LoadBalancer`.
      service:
        replicas: 1
        `type: NodePort`

  - Change the type from `NodePort` to `LoadBalancer` in `kube-state-metrics-service.yaml` file inside `kube-state-metrics` folder
    #####  Search for `type: NodePort` in yaml and replace a value of key `type` with `LoadBalancer`.
        `type: NodePort`


#### Usage:
just run `./create.sh` and let the shell script do it for you! 

- ./create.sh -s $service -a action -c $component
  - Options:
    -s service:  The name of the component. 
    		    Valid options are `influxdb`, `kapacitor`, `telegraf-s`, `telegraf-ds`, `chronograf` and `all`
    -a action: Valid options are `create` and `destroy`
    -c component: Valid options are `oss-k8s`, `aws-eks` and `minikube`
    
#### Examples:
 - To execute all components from `single command`:

    	./create.sh -s all -a create -c oss-k8s
    	./create.sh -s all -a destroy -c oss-k8s
        
 - To execute `individual command`:

      ./create.sh -s influxdb -a create -c oss-k8s
      ./create.sh -s influxdb -a destroy -c oss-k8s
	

### Manual Steps after complete stack deployement
- There are two Endpoint printed on console at the end of create script 
  - `Chronograf Endpoint URL`.
  - `Influxdb Endpoint URL`.

- Use `Chronograf Endpoint URL` to access `Chronograf dashboard`. 
- Use `Influxdb Endpint URL` to add new influxdb connection.
 - Replace connection string with `Influxdb Endpoint URL`.
