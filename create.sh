#!/bin/bash
source ~/.bashrc
function main
{
	initScript "$@"
	
	echo "Component:" $COMPONENT
	echo "Action:" $ACTION
	
	if [[ $SERVICE == 'minikube' ]]; then
		echo "Service:" $SERVICE
		chart_execution $ACTION $COMPONENT $SERVICE
	elif [[ $SERVICE == 'aws' ]]; then
		echo "Service:" $SERVICE
		chart_execution $ACTION $COMPONENT $SERVICE
	elif [[ $SERVICE == '' ]]; then
		echo "Service is empty"
	else 
		echo "Service is not valid !!!"
	fi	
	#sed -i "/[ ]*type: /c \  type: $service" chronograf/values.yaml
	#sed -i "/[ ]*type: /c \  type: $service" influxdb/values.yaml
	#sed -i "/[ ]*type: /c \  type: $service" kapacitor/values.yaml
	#sed -i "/[ ]*type: /c \  type: $service" telegraf-s/values.yaml


	# if [ $ACTION == 'create' ]; then	
	# 	create_chart $COMPONENT
		
	# elif [ $ACTION == 'destroy' ]; then
	# 	destroy_chart $COMPONENT
	# else
	# 	echo "Action is not valid !!!"
	# fi	
}

function chart_execution
{
	action=$1
	component=$2
	service=$3
	if [ $action == 'create' ]; then
		create_chart $component $service
	elif [ $ACTION == 'destroy' ]; then
		destroy_chart $component $service
	else
		echo "Action is not valid !!!"
	fi	
}

function create_chart
{
	component=$1
	service=$2
	influxURL=""
	kapacitorURL=""
	telInfluxUrl=""
	INFLUX_URL=""
	kAPACITOR_URL=""
	Chronograf_URL=""
	# Initiaize the helm
	helm init

	echo "Creating chart for" $component
	if [[ $component == "influxdb" ]]; then

		helm install --name data --namespace tick influxdb
		echo Deploying influxdb .....
		sleep 60
		#influxURL=`(kubectl describe svc data-influxdb | grep "Ingress" | awk '{print $3}')`
		#echo INFLUX_URL="$influxURL" >> ~/.bashrc
	
	elif [[ $component == "kapacitor" ]]; then

	 	if [[ $service == "aws" ]]; then
	 		sed "/influxURL: /c influxURL: http://$INFLUX_URL" kapacitor/values.yaml	
		fi	
		
		helm install --name alerts --namespace tick kapacitor
		echo Deploying Kapacitor .....
		sleep 60
		kapacitorURL=`(kubectl describe service alerts-kapacitor | grep "Ingress" | awk '{print $3}')`
		#echo KAPACITOR_URL="$kapacitorURL" >> ~/.bashrc

	elif [[ $component == "chronograf" ]]; then
		
		helm install --name dash --namespace tick chronograf
		echo Deploying Chronograf .....
		sleep 60
		create_dashboard $service

	elif [[ $component == "telegraf-s" ]]; then
	
		if [[ $service == "aws" ]]; then
	 	
			influxURL=`cat telegraf-s/values.yaml | grep -A3 -m 1 "\- influxdb:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`
        	kapacitor=`cat telegraf-s/values.yaml | grep -A3 -m 1 "\- kapacitor:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`
			INFLUX_URL=`(kubectl describe svc data-influxdb | grep "Ingress" | awk '{print $3}')`
			KAPACITOR_URL=`(kubectl describe svc alerts-kapacitor | grep "Ingress" | awk '{print $3}')`
			sed -i "s/$influxURL/$INFLUX_URL:8086/g" telegraf-s/values.yaml
			sed -i "s/$kapacitor/$KAPACITOR_URL:9092/g" telegraf-s/values.yaml	

			echo $INFLUX_URL
			echo $KAPACITOR_URL
		fi
		helm install --name polling --namespace tick telegraf-s

	elif [[ $component == "telegraf-ds" ]]; then
		
		if [[ $service == "aws" ]]; then
			influxURL=`cat telegraf-ds/values.yaml | grep -A3 -m 1 "\- influxdb:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`
			INFLUX_URL=`(kubectl describe svc data-influxdb | grep "Ingress" | awk '{print $3}')`
			sed -i "s/$influxURL/$INFLUX_URL:8086/g" telegraf-ds/values.yaml
		fi
		helm install --name hosts --namespace tick telegraf-ds	

	else
		
		helm install --name data --namespace tick influxdb
		echo Deploying Influxdb .....
		if [[ $service == "aws" ]]; then
			sleep 120
		    INFLUX_URL=`(kubectl describe svc data-influxdb | grep "Ingress" | awk '{print $3}')`
			sed -i "/influxURL: /c influxURL: http://$INFLUX_URL:8086" kapacitor/values.yaml
		else 
			sleep 60
		fi	

		helm install --name alerts --namespace tick kapacitor
		echo Deploying Kapacitor .....
        
		if [[ $service == "aws" ]]; then
			sleep 120
			influxURL=`cat telegraf-s/values.yaml | grep -A3 -m 1 "\- influxdb:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`	
			kapacitor=`cat telegraf-s/values.yaml | grep -A3 -m 1 "\- kapacitor:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`	
    	    KAPACITOR_URL=`(kubectl describe svc alerts-kapacitor | grep "Ingress" | awk '{print $3}')`
        	sed -i "s/$influxURL/$INFLUX_URL:8086/g" telegraf-s/values.yaml
        	sed -i "s/$kapacitor/$KAPACITOR_URL:9092/g" telegraf-s/values.yaml
        	sed -i "s/$influxURL/$INFLUX_URL:8086/g" telegraf-ds/values.yaml
		else
			sleep 60
		fi	
		
		helm install --name polling --namespace tick telegraf-s
		
		if [[ $service == "aws" ]]; then
			telInfluxUrl=`cat telegraf-ds/values.yaml | grep -A3 -m 1 "\- influxdb:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`
			sed -i "s/$telInfluxUrl/$INFLUX_URL:8086/g" telegraf-ds/values.yaml
		fi

		helm install --name hosts --namespace tick telegraf-ds
		
		helm install --name dash --namespace tick chronograf
		echo Deploying Chronograf .....
		#sleep 120
		if [[ $service == "aws" ]]; then
			sleep 120
		else
			sleep 60
		fi
		create_dashboard $service
	fi	
	kubectl config set-context $(kubectl config current-context) --namespace=tick
	printf "\n\n=======================================================================\n"
	if [[ $service == "aws" ]]; then
		Chronograf_URL=`(kubectl describe services dash-chronograf | grep "Ingress" | awk '{print $3}')`
		Influx_URL=`(kubectl describe svc data-influxdb | grep "Ingress" | awk '{print $3}')`
		echo "Chronograf Endpoint URL:" $Chronograf_URL
		echo "Influxdb Endpoint URL:" $Influx_URL":8086"
	else
		echo "Chronograf Endpoint URL:" $(minikube ip):30088
		echo "Influxdb Endpoint URL:" $(minikube ip):30080
	fi

	printf "\n=======================================================================\n"
}

function destroy_chart
{
	component=$1
	echo "Destorying chart of" $component
	if [ $component == "influxdb" ]; then
		helm delete data --purge
	elif [ $component == "kapacitor" ]; then
		helm delete alerts --purge	
	elif [ $component == "chronograf" ]; then
		helm delete dash --purge
	elif [ $component == "telegraf-s" ]; then
		helm delete polling --purge
	elif [ $component == "telegraf-ds" ]; then
		helm delete hosts --purge
	else	
		helm delete data alerts dash polling hosts --purge
	fi
}

function create_dashboard
{
	service=$1
	if [[ $service == "minikube" ]]; then
		dashboard=$(minikube ip)
		DST=http://$dashboard:30088/chronograf/v1/dashboards
	elif [[ $service == "aws" ]]; then
		dashboard=`(kubectl describe svc dash-chronograf | grep "Ingress" | awk '{print $3}')`
		DST=http://$dashboard/chronograf/v1/dashboards
	fi 
	 echo $DST
	 cd chronograf/dashboards
    		for file in *
    		do
	   		curl -X POST -H "Accept: application/json" -d @$(basename "$file") $DST -o output.txt;
		   	done
}

function usage
{
	cat <<EOF

    Usage:
        -c component:  The name of the component. Valid options are influxdb, kapacitor, telegraf-s, telegraf-ds, chronograf and all
        -a action: Valid options are create and destroy
        -s service: Valid options are minikube and aws
    Examples:
        ./create.sh -c influxdb -a create -s minikube
        ./create.sh -c influxdb -a destroy -s minikube
EOF
}

function initScript
{
	COMPONENT="all"
	ACTION="create"
	SERVICE=""
	while getopts h:a:c:s: opt
		do
			case "$opt" in
				h) usage "";exit 1;;
				c) COMPONENT=$OPTARG;;
				a) ACTION=$OPTARG;;
				s) SERVICE=$OPTARG;;
				\?) usage "";exit 1;;
			esac
		done

}

main "$@"
