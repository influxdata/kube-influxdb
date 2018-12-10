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
		kubectl config set-context $(kubectl config current-context) --namespace=kube-system
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
	statemetricsUrl=""

	influxPort=8086
	kapacitorPort=9092
	chronografPort=80

	# Replace the cluster Name
	ClusterName="http://DCF5E3C91F38585831A446B7D504ED8F.sk1.us-east-1.eks.amazonaws.com"
	kubectl config set-context $(kubectl config current-context) --namespace=tick
	echo "Creating chart for" $service
	if [[ $service == "influxdb" ]]; then

		# Deploying influxdb service
		echo Deploying influxdb .....
		deploy_service data $service
		sleep 120;
		
		INFLUX_URL=`(kubectl describe svc data-influxdb | grep "Ingress" | awk '{print $3}')`
		
		printf "\n\n=======================================================================\n"
		echo "Influxdb Endpoint URL:" $INFLUX_URL:8086
		printf "\n\n=======================================================================\n"
		
	elif [[ $service == "kapacitor" ]]; then

		echo Deploying Kapacitor .....
		INFLUX_URL=`(kubectl describe svc data-influxdb | grep "Ingress" | awk '{print $3}')`
	 	sed -i "/influxURL: /c influxURL: http://$INFLUX_URL:8086" kapacitor/values.yaml	

		# Deploying kapacitor service
		deploy_service alerts $service
		sleep 120;
		KAPACITOR_URL=`(kubectl describe svc alerts-kapacitor | grep "Ingress" | awk '{print $3}')`
		printf "\n\n=======================================================================\n"
		echo "Kapacitor Endpoint URL:" $KAPACITOR_URL:9092
		printf "\n\n=======================================================================\n"
		
		
	elif [[ $service == "chronograf" ]]; then
		
		deploy_service dash $service
		echo Deploying Chronograf .....
		sleep 120;
		# Deploying chronograf service
		create_dashboard 
		chronografURL=`(kubectl describe svc dash-chronograf | grep "Ingress" | awk '{print $3}')`
		printf "\n\n=======================================================================\n"
		echo "Chronograf Endpoint URL:" $chronografURL
		printf "\n=======================================================================\n"

	elif [[ $service == "telegraf-s" ]]; then
	
		influxURL=`cat telegraf-s/values.yaml | grep -A3 -m 1 "\- influxdb:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`
        kapacitor=`cat telegraf-s/values.yaml | grep -A3 -m 1 "\- kapacitor:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`
		INFLUX_URL=`(kubectl describe svc data-influxdb | grep "Ingress" | awk '{print $3}')`
		KAPACITOR_URL=`(kubectl describe svc alerts-kapacitor | grep "Ingress" | awk '{print $3}')`
		sed -i "s/$influxURL/$INFLUX_URL:8086/g" telegraf-s/values.yaml
		sed -i "s/$kapacitor/$KAPACITOR_URL:9092/g" telegraf-s/values.yaml
		# Deploying telegraf-ds service
		deploy_service polling $service
	
	elif [[ $service == "telegraf-ds" ]]; then

		kubectl config set-context $(kubectl config current-context) --namespace=kube-system
		statemetricsUrl=`(kubectl describe svc kube-state-metrics | grep Ingress | awk '{print $3}')`
		promethesusUrl=`cat telegraf-ds/values.yaml  | grep -A2 "prometheus" | grep "urls" | sed -e 's/.*\/\/\(.*\):.*/\1/'`
		kubectl config set-context $(kubectl config current-context) --namespace=tick
		
		telInfluxUrl=`cat telegraf-ds/values.yaml | grep -A3 -m 1 "\- influxdb:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`
		INFLUX_URL=`(kubectl describe svc data-influxdb | grep "Ingress" | awk '{print $3}')`
		sed -i "s/$telInfluxUrl/$INFLUX_URL:8086/g" telegraf-ds/values.yaml
		sed -i "s/$promethesusUrl:30080/$statemetricsUrl:8080/g" telegraf-ds/values.yaml
		sed -i "s/$promethesusUrl:30081/$statemetricsUrl:8081/g" telegraf-ds/values.yaml
		
		# Deploying telegraf-ds service
		deploy_service hosts $service
	else
		
		echo Deploying Influxdb .....
		deploy_service data influxdb
		sleep 180;
		INFLUX_URL=`(kubectl describe svc data-influxdb | grep "Ingress" | awk '{print $3}')`
		
		# Deploying kapacitor service
	 	echo Deploying Kapacitor .....
        sed -i "/influxURL: /c influxURL: http://$INFLUX_URL:8086" kapacitor/values.yaml	
        deploy_service alerts kapacitor
		sleep 150;

        # Deploying telegaf-s service
	 	echo Deploying telegraf-s .....
	 	influxURL=`cat telegraf-s/values.yaml | grep -A3 -m 1 "\- influxdb:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`
        kapacitor=`cat telegraf-s/values.yaml | grep -A3 -m 1 "\- kapacitor:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`
		KAPACITOR_URL=`(kubectl describe svc alerts-kapacitor | grep "Ingress" | awk '{print $3}')`
		sed -i "s/$influxURL/$INFLUX_URL:8086/g" telegraf-s/values.yaml
		sed -i "s/$kapacitor/$KAPACITOR_URL:9092/g" telegraf-s/values.yaml
	 	deploy_service polling telegraf-s
		
	 	echo "Deploying telegraf-ds"
		# Deploying telegraf-ds service

		kubectl config set-context $(kubectl config current-context) --namespace=kube-system
		statemetricsUrl=`(kubectl describe svc kube-state-metrics | grep Ingress | awk '{print $3}')`
		promethesusUrl=`cat telegraf-ds/values.yaml  | grep -A2 "prometheus" | grep "urls" | sed -e 's/.*\/\/\(.*\):.*/\1/'`
		kubectl config set-context $(kubectl config current-context) --namespace=tick
		
		telInfluxUrl=`cat telegraf-ds/values.yaml | grep -A3 -m 1 "\- influxdb:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`
		INFLUX_URL=`(kubectl describe svc data-influxdb | grep "Ingress" | awk '{print $3}')`
		sed -i "s/$telInfluxUrl/$INFLUX_URL:8086/g" telegraf-ds/values.yaml
		sed -i "s/$promethesusUrl:30080/$statemetricsUrl:8080/g" telegraf-ds/values.yaml
		sed -i "s/$promethesusUrl:30081/$statemetricsUrl:8081/g" telegraf-ds/values.yaml
		
		# Deploying telegraf-ds service
		deploy_service hosts telegraf-ds
		
		# Deploying chronograf service
		echo Deploying Chronograf .....
		deploy_service dash chronograf

		sleep 120;
		# Call dashboard function
		create_dashboard 

		printf "\n\n=======================================================================\n"
		chronografURL=`(kubectl describe svc dash-chronograf | grep "Ingress" | awk '{print $3}')`
		echo "Influxdb Endpoint URL:" $INFLUX_URL:$influxPort
		echo "Chronograf Endpoint URL:" $chronografURL
		echo "Kapacitor Endpoint URL:" $KAPACITOR_URL:$kapacitorPort

		printf "\n=======================================================================\n"
	fi
}

function create_dashboard
{

	chronografURL=`(kubectl describe svc dash-chronograf | grep "Ingress" | awk '{print $3}')`	
	DST=http://$chronografURL/chronograf/v1/dashboards
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
	echo "Tick Charts for EKS"	
}
main "$@"
