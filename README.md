# kube-influxdb

This is a collection of [Helm](https://github.com/kubernetes/helm) [Charts](https://github.com/kubernetes/charts) for the [InfluxData](https://influxdata.com/time-series-platform) TICK stack. This repo contains the following charts:

- [influxdb](/influxdb/README.md)
- [chronograf](/chronograf/README.md)
- [kapacitor](/kapacitor/README.md)
- [telegraf-s](/telegraf-s/README.md)
- [telegraf-ds](/telegraf-ds/README.md)


Configuration to monitor Kubernetes with the TICK stack

Run the complete TICK stack using this using create.sh script. By using create.sh all four official TICK stack images are deployed in kubernetes.

### Deploy the whole stack!

#### Note: This project will currently supported only OSS kubernetes Cluster version(1.8.10) and work only on Kubernets Cluster setup using Kops on AWS 

- Have your 'kubectl' tool configured for the Kubernetes cluster Running AWS on where you would like to deploy TICK stack.
- Have `helm` and `tiller` installed and configured
  - Download and configure the `helm` cli
    * [link](https://github.com/kubernetes/helm/blob/master/docs/install.md)
  - Run `helm init` to install `tiller` in your cluster
    * [link](https://github.com/kubernetes/helm/blob/master/docs/install.md#installing-tiller)
- Have a 'daemon-set' configuration on the master node of the cluster for 'telegraf-ds'
  - Execute following command on master node. 
       kubectl taint nodes ip-x-x-x-x.ec2.internal node-role.kubernetes.io/master:NoSchedule-
    Note: You need to ssh to master node to execute above command. 

### Usage
just run `./create.sh` and let the shell script do it for you! You can also tear down the installation with `./destroy.sh`

- ./create.sh -c $component -a action
  - Options:
     -c component:  The name of the component. 
    		    Valid options are 'influxdb', 'kapacitor', 'telegraf-s', 'telegraf-ds', 'chronograf' and 'all'
     -a action: Valid options are 'create' and 'destroy'
    
#### Examples:
 - To execute all components from single command:

    	./create.sh -c all -a create
    	./create.sh -c all -a destroy
        
 - To execute individual command:

        ./create.sh -c influxdb -a create
        ./create.sh -c influxdb -a destroy
	
### Manual Steps after complete stack deployement
