#!/bin/bash
source ~/.bashrc
function main
{
	initScript "$@"
	echo "Component:" $COMPONENT
	echo "Action:" $ACTION
	
	if [ $ACTION == 'create' ]; then	
		create_chart $COMPONENT
		
	elif [ $ACTION == 'destroy' ]; then
		destroy_chart $COMPONENT
	else
		echo "Action is not valid !!!"
	fi	
}

function create_chart
{
	component=$1
	influxURL=""
	kapacitorURL=""
	INFLUX_URL=""
	kAPACITOR_URL=""
	Chronograf_URL=""
	# Initiaize the helm
	helm init

	echo "Creating chart for" $component
	if [ $component == "influxdb" ]; then

		helm install --name data --namespace tick influxdb
		echo Deploying influxdb .....
		sleep 60
		#influxURL=`(kubectl describe svc data-influxdb | grep "Ingress" | awk '{print $3}')`
		#echo INFLUX_URL="$influxURL" >> ~/.bashrc
	
	elif [ $component == "kapacitor" ]; then

	 	sed "/influxURL: /c influxURL: http://$INFLUX_URL" kapacitor/values.yaml	
		helm install --name alerts --namespace tick kapacitor
		echo Deploying Kapacitor .....
		sleep 60
		kapacitorURL=`(kubectl describe svc alerts-kapacitor | grep "Ingress" | awk '{print $3}')`
		#echo KAPACITOR_URL="$kapacitorURL" >> ~/.bashrc

	elif [ $component == "chronograf" ]; then
		
		helm install --name dash --namespace tick chronograf
		echo Deploying Chronograf .....
		sleep 180
		create_dashboard
	elif [ $component == "telegraf-s" ]; then
	
		influxURL=`cat telegraf-s/values.yaml | grep -A3 -m 1 "\- influxdb:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`
                kapacitor=`cat telegraf-s/values.yaml | grep -A3 -m 1 "\- kapacitor:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`
		INFLUX_URL=`(kubectl describe svc data-influxdb | grep "Ingress" | awk '{print $3}')`
		KAPACITOR_URL=`(kubectl describe svc alerts-kapacitor | grep "Ingress" | awk '{print $3}')`
		sed -i "s/$influxURL/$INFLUX_URL:8086/g" telegraf-s/values.yaml
		sed -i "s/$kapacitor/$KAPACITOR_URL:9092/g" telegraf-s/values.yaml
		echo $INFLUX_URL
		echo $KAPACITOR_URL
		helm install --name polling --namespace tick telegraf-s

	elif [ $component == "telegraf-ds" ]; then
		
		influxURL=`cat telegraf-ds/values.yaml | grep -A3 -m 1 "\- influxdb:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`
		INFLUX_URL=`(kubectl describe svc data-influxdb | grep "Ingress" | awk '{print $3}')`
		sed -i "s/$influxURL/$INFLUX_URL:8086/g" telegraf-ds/values.yaml
		helm install --name hosts --namespace tick telegraf-ds	

	else
		
		helm install --name data --namespace tick influxdb
		echo Deploying Influxdb .....
		sleep 120

        INFLUX_URL=`(kubectl describe svc data-influxdb | grep "Ingress" | awk '{print $3}')`

		sed "/influxURL: /c influxURL: http://$INFLUX_URL" kapacitor/values.yaml
        helm install --name alerts --namespace tick kapacitor
		echo Deploying Kapacitor .....
        sleep 120
	
		influxURL=`cat telegraf-s/values.yaml | grep -A3 -m 1 "\- influxdb:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`	
		kapacitor=`cat telegraf-s/values.yaml | grep -A3 -m 1 "\- kapacitor:" | grep "http" | sed -e 's/.*\/\/\(.*\)".*/\1/'`	
        KAPACITOR_URL=`(kubectl describe svc alerts-kapacitor | grep "Ingress" | awk '{print $3}')`
        sed -i "s/$influxURL/$INFLUX_URL:8086/g" telegraf-s/values.yaml
        sed -i "s/$kapacitor/$KAPACITOR_URL:9092/g" telegraf-s/values.yaml

		helm install --name polling --namespace tick telegraf-s
		
		sed -i "s/$influxURL/$INFLUX_URL:8086/g" telegraf-ds/values.yaml
		helm install --name hosts --namespace tick telegraf-ds

		helm install --name dash --namespace tick chronograf
		echo Deploying Chronograf .....
		sleep 120	
		create_dashboard
	fi	
	kubectl config set-context $(kubectl config current-context) --namespace=tick
	printf "\n\n=======================================================================\n"
	Chronograf_URL=`(kubectl describe svc dash-chronograf | grep "Ingress" | awk '{print $3}')`
	printf "\nChronograf Endpoint URL : " $Chronograf_URL
	printf "\n\nInfluxdb Endpoint URL : " $INFLUX_URL":8086"
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
	#minikube_ip=$(minikube ip)
	dashboard=`(kubectl describe svc dash-chronograf | grep "Ingress" | awk '{print $3}')`
	DST=http://$dashboard/chronograf/v1/dashboards
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
    Examples:
        ./create.sh -c influxdb -a create
        ./create.sh -c influxdb -a destroy
EOF
}

function initScript
{
	COMPONENT="all"
	ACTION="create"
	while getopts h:a:c: opt
		do
			case "$opt" in
				h) usage "";exit 1;;
				c) COMPONENT=$OPTARG;;
				a) ACTION=$OPTARG;;
				\?) usage "";exit 1;;
			esac
		done

}

main "$@"
