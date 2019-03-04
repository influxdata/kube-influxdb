#!/bin/bash
source ~/.bashrc
function main
{
	initScript "$@"
	service=$1
	action=$2
	if [[ $action == 'create' ]]; then
		# role based access controll
		kubectl create -f rbac-config.yaml
		kubectl create serviceaccount --namespace kube-system tiller
		# create cluster-role-binding
		kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
		kubectl create clusterrolebinding admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value core/account)
		kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud info | grep Account | cut -d '[' -f 2 | cut -d ']' -f 1)
		
		# create kube state metrics
		kubectl apply -f kube-state-metrics/
		
		# Initiaize the helm in the cluster
		helm init 
		sleep 20;
		# create tiller deploy patched
		kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'      
		kubectl create serviceaccount --namespace kube-system tiller
		# create charts
		create_chart $service
	elif [[ $action == 'destroy' ]]; then
		# destroy charts
		destroy_chart $service
	else
		echo "Action is not valid !!!"
	fi	
}

function create_chart
{
	service=$1
	action=$2

	influx_port=30082
	kapacitor_port=30083
	chronograf_port=30088

	# Replace Any NodeIP/URL
	cluster_name="tickstackcluster.com"
	kubectl config set-context $(kubectl config current-context) --namespace=tick
	
	echo "Creating chart for" $service
	if [ $service == "influxdb" ] || [ $service == "all" ]; then
		# Deploying Influxdb service
		echo Deploying Influxdb .....
		helm install --name data --namespace tick influxdb
		sleep 30;	
		printf "\n\n=======================================================================\n"
		echo "Influxdb Endpoint URL:" $cluster_name:$influx_port
		printf "\n\n=======================================================================\n"		
	fi		
		
	if [ $service == "kapacitor" ] || [ $service == "all" ]; then
		# Deploying kapacitor service
		echo Deploying Kapacitor .....
        helm install --name alerts --namespace tick kapacitor
		sleep 30;
		printf "\n\n=======================================================================\n"
		echo "Kapacitor Endpoint URL:" $cluster_name:$kapacitor_port
		printf "\n\n=======================================================================\n"
	fi
		
	if [ $service == "telegraf-s" ] || [ $service == "all" ]; then	
		# Deploying telegraf-ds service
		echo Deploying telegraf-s .....
	 	helm install --name polling --namespace tick telegraf-s
	fi
	
	if [ $service == "telegraf-ds" ] || [ $service == "all" ]; then
		# Deploying telegraf-ds service
		echo Deploying telegraf-s .....
	 	helm install --name hosts --namespace tick telegraf-ds
	fi	
	
	if [ $service == "chronograf" ] || [ $service == "all" ]; then
		# Deploying chronograf service
		echo Deploying Chronograf .....
		helm install --name dash --namespace tick chronograf
		sleep 60;

		create_dashboard
		printf "\n\n=======================================================================\n"
		echo "Chronograf Endpoint URL:" $cluster_name:$chronograf_port
		printf "\n\n=======================================================================\n"
	fi

	if [ $service == "all" ]; then
		printf "\n\n=======================================================================\n"

		echo "Influxdb Endpoint URL:" $cluster_name:$influx_port
		echo "Chronograf Endpoint URL:" $cluster_name:$chronograf_port
		echo "Kapacitor Endpoint URL:" $cluster_name:$kapacitor_port

		printf "\n=======================================================================\n"
	fi
}

function create_dashboard
{
	DST=http://$cluster_name:$chronograf_port/chronograf/v1/dashboards
	cd ./chronograf/dashboards/common
    	
    for file in *
    do
	   	curl -X POST -H "Accept: application/json" -d @$(basename "$file") $DST;
	done

	cd ../gke/

    for file in *
    do
        curl -X POST -H "Accept: application/json" -d @$(basename "$file") $DST;
    done
}


function destroy_chart
{
	service=$1
	echo "Destorying chart of" $service
	if [ $service == "influxdb" ]; then
		helm delete data --purge
	elif [ $service == "kapacitor" ]; then
		helm delete alerts --purge	
	elif [ $service == "chronograf" ]; then
		helm delete dash --purge
	elif [ $service == "telegraf-s" ]; then
		helm delete polling --purge
	elif [ $service == "telegraf-ds" ]; then
		helm delete hosts --purge
	else	
		helm delete data alerts dash polling hosts --purge
	fi
}

function initScript
{
	echo "Tick Charts for GCP"	
}
main "$@"
