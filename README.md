# kube-influxdb

Configuration to monitor Kubernetes with the TIC stack

Run the complete TICK stack using this using create.sh script. By using create.sh all four official TICK stack images are deployed in kubernetes.

Pre-requisites:

Note: This project will currently supported only OSS kubernetes Cluster version(1.8.10) and work only on Kubernets Cluster setup using Kops on AWS 

1. Running AWS Kubernetes Cluster 
2. Helm should be installed on the server
3. To run the telegraf(daemon-set) on master, run the following on master:
	RUn the below command on master:
	kubectl taint nodes ip-x-x-x-x.ec2.internal node-role.kubernetes.io/master:NoSchedule-

Here is the command to execute the script:

        ./create.sh -c $component -a action

        -c component:  The name of the component. Valid options are influxdb, kapacitor, telegraf-s, telegraf-ds, chronograf and all
        -a action: Valid options are create and destroy
    
    Examples:
    	To execute all components from single command:

    	./create.sh -c all -a create
    	./create.sh -c all -a destroy
        
        To execute individual command:

        ./create.sh -c influxdb -a create
        ./create.sh -c influxdb -a destroy