#!/bin/bash
source ~/.bashrc
function main
{
	initScript "$@"
	service=$1
	action=$2
	if [[ $action == 'create' ]]; then
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
	influxURL=""
	kapacitorURL=""
	telInfluxUrl=""
	INFLUX_URL=""
	kAPACITOR_URL=""
	chronografURL=""
	prometheusUrl=""

	influxPort=30082
	kapacitorPort=30083
	chronografPort=30088

	minikubeIp=$(minikube ip)
		
	echo "Creating chart for" $service
	if [[ $service == "influxdb" ]]; then

		# Deploying influxdb service
		echo Deploying influxdb .....
		deploy_service data $service
		sleep 30;
		
		printf "\n\n=======================================================================\n"
		echo "Influxdb Endpoint URL:" $(minikube ip):$influxPort
		printf "\n\n=======================================================================\n"
		
	elif [[ $service == "kapacitor" ]]; then

		echo Deploying Kapacitor .....
	 	sed -i "/influxURL: /c influxURL: http://$minikubeIp:30082" kapacitor/values.yaml
		
		# Deploying kapacitor service
		deploy_service alerts $service
		sleep 30;
		
		printf "\n\n=======================================================================\n"
		echo "Kapacitor Endpoint URL:" $(minikube ip):$kapacitorPort
		printf "\n\n=======================================================================\n"
		
		
	elif [[ $service == "chronograf" ]]; then
		
		deploy_service dash $service
		echo Deploying Chronograf .....
		sleep 60;
		# Deploying chronograf service
		create_dashboard 
		printf "\n\n=======================================================================\n"
		echo "Chronograf Endpoint URL:" $(minikube ip):$chronografPort
		printf "\n=======================================================================\n"

	elif [[ $service == "telegraf-s" ]]; then
	
		influxURL=`cat telegraf-s/values.yaml | grep -A3 -m 1 "\- influxdb:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`
        kapacitor=`cat telegraf-s/values.yaml | grep -A3 -m 1 "\- kapacitor:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`
		sed -i "s/$influxURL/$minikubeIp:30082/g" telegraf-s/values.yaml
        sed -i "s/$kapacitor/$minikubeIp:30083/g" telegraf-s/values.yaml
		
		# Deploying telegraf-ds service
		deploy_service polling $service
	
	elif [[ $service == "telegraf-ds" ]]; then
		
		telInfluxUrl=`cat telegraf-ds/values.yaml | grep -A3 -m 1 "\- influxdb:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`
		promethesusUrl=`cat telegraf-ds/values.yaml  | grep -A2 "prometheus" | grep "urls" | sed -e 's/.*\/\/\(.*\):.*/\1/'`
		sed -i "s/$telInfluxUrl/$minikubeIp:30082/g" telegraf-ds/values.yaml
		sed -i "s/$promethesusUrl/$minikubeIp/g" telegraf-ds/values.yaml

		# Deploying telegraf-ds service
		deploy_service hosts $service
	else
		deploy_service data influxdb
		echo Deploying Influxdb .....
		sed -i "/influxURL: /c influxURL: http://$minikubeIp:30082" kapacitor/values.yaml
		sleep 30;
		
		# Deploying kapacitor service
	 	echo Deploying Kapacitor .....
        deploy_service alerts kapacitor

        influxURL=`cat telegraf-s/values.yaml | grep -A3 -m 1 "\- influxdb:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`	
		kapacitor=`cat telegraf-s/values.yaml | grep -A3 -m 1 "\- kapacitor:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`	
		sed -i "s/$influxURL/$minikubeIp:30082/g" telegraf-s/values.yaml
        sed -i "s/$kapacitor/$minikubeIp:30083/g" telegraf-s/values.yaml
        sleep 30;

        # Deploying telegaf-s service
	 	echo Deploying telegraf-s .....
	 	deploy_service polling telegraf-s
		telInfluxUrl=`cat telegraf-ds/values.yaml | grep -A3 -m 1 "\- influxdb:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`
		sed -i "s/$telInfluxUrl/$minikubeIp:30082/g" telegraf-ds/values.yaml
		
		# Deploying telegraf-ds service
		deploy_service hosts telegraf-ds

		# Deploying chronograf service
		echo Deploying Chronograf .....
		deploy_service dash chronograf

		sleep 60;

		# Call dashboard function
		create_dashboard 

		kubectl config set-context $(kubectl config current-context) --namespace=tick
	
		printf "\n\n=======================================================================\n"

		echo "Influxdb Endpoint URL:" $(minikube ip):$influxPort
		echo "Chronograf Endpoint URL:" $(minikube ip):$chronografPort
		echo "Kapacitor Endpoint URL:" $(minikube ip):$kapacitorPort
		printf "\n=======================================================================\n"
	fi
}

function create_dashboard
{
	echo "Inside Dashobard"
	
	dashboard=$(minikube ip)
	DST=http://$dashboard:30088/chronograf/v1/dashboards
	cd ./chronograf/dashboards
    	
    for file in *
    do
	   	curl -X POST -H "Accept: application/json" -d @$(basename "$file") $DST;
	done
}


function deploy_service
{
	service_alias=$1
	service=$2
	helm install --name $service_alias --namespace tick $service
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
