#!/bin/bash
source ~/.bashrc
function main
{
	initScript "$@"
	service=$1
	action=$2
	if [[ $action == 'create' ]]; then

		# create cluster-role-binding
		kubectl create -f rbac-config.yaml
		
		# create kube state metrics
		kubectl apply -f kube-state-metrics/
		
		# Initiaize the helm in the cluster
		helm init 
		sleep 20;
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
	influx_url=""
	tel_influx_url=""
	promethesus_url=""
	kapacitor_url=""
	
	influx_port=30082
	kapacitor_port=30083
	chronograf_port=30088

	minikubeIp=$(minikube ip)

	kubectl config set-context $(kubectl config current-context) --namespace=tick
	
	echo "Creating chart for" $service
	if [ $service == "influxdb" ] || [ $service == "all" ]; then
		# Deploying influxdb service
		echo Deploying influxdb .....
		helm install --name data --namespace tick influxdb
		sleep 30;
		
		printf "\n\n=======================================================================\n"
		echo "Influxdb Endpoint URL:" $(minikube ip):$influx_port
		printf "\n\n=======================================================================\n"
		
	fi
	if [ $service == "kapacitor" ] || [ $service == "all" ]; then
		echo Deploying Kapacitor .....
	 	sed -i "/influxURL: /c influxURL: http://$minikubeIp:30082" kapacitor/values.yaml
		
		# Deploying kapacitor service
		helm install --name alerts --namespace tick kapacitor
		sleep 30;
		
		printf "\n\n=======================================================================\n"
		echo "Kapacitor Endpoint URL:" $(minikube ip):$kapacitor_port
		printf "\n\n=======================================================================\n"
	fi	
		

	if [ $service == "telegraf-s" ] || [ $service == "all" ]; then
		influx_url=`cat telegraf-s/values.yaml | grep -A3 -m 1 "\- influxdb:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`
        kapacitor_url=`cat telegraf-s/values.yaml | grep -A3 -m 1 "\- kapacitor:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`
		sed -i "s/$influx_url/$minikubeIp:30082/g" telegraf-s/values.yaml
        sed -i "s/$kapacitor_url/$minikubeIp:30083/g" telegraf-s/values.yaml
		
		# Deploying telegraf-ds service
		helm install --name polling --namespace tick telegraf-s
	fi
	
	if [ $service == "telegraf-ds" ] || [ $service == "all" ]; then	
		tel_influx_url=`cat telegraf-ds/values.yaml | grep -A3 -m 1 "\- influxdb:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`
		promethesus_url=`cat telegraf-ds/values.yaml  | grep -A2 "prometheus" | grep "urls" | sed -e 's/.*\/\/\(.*\):.*/\1/'`
		sed -i "s/$tel_influx_url/$minikubeIp:30082/g" telegraf-ds/values.yaml
		sed -i "s/$promethesus_url/$minikubeIp/g" telegraf-ds/values.yaml

		# Deploying telegraf-ds service
		helm install --name hosts --namespace tick telegraf-ds
	
	fi
	
	if [ $service == "chronograf" ] || [ $service == "all" ]; then		
		# Deploying chronograf service
		echo Deploying Chronograf .....
		helm install --name dash --namespace tick chronograf
		sleep 60;

		# Call dashboard function
		create_dashboard
		printf "\n\n=======================================================================\n"
		echo "Chronograf Endpoint URL:" $(minikube ip):$chronograf_port
		printf "\n\n=======================================================================\n"
	fi

	if [ $service == "all" ]; then
		printf "\n\n=======================================================================\n"

		echo "Influxdb Endpoint URL:" $(minikube ip):$influx_port
		echo "Chronograf Endpoint URL:" $(minikube ip):$chronograf_port
		echo "Kapacitor Endpoint URL:" $(minikube ip):$kapacitor_port

		printf "\n=======================================================================\n"
	fi		
}

function create_dashboard
{
	dashboard=$(minikube ip)
	DST=http://$dashboard:30088/chronograf/v1/dashboards
	cd ./chronograf/dashboards/common
    	
    for file in *
    do
	   	curl -X POST -H "Accept: application/json" -d @$(basename "$file") $DST;
	done

	cd ../minikube/

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
	echo "Tick Charts for Minikube"	
}
main "$@"
