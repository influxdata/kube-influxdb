#!/bin/bash
# helm install --name data --namespace tick ./influxdb/

# helm install --name alerts --namespace tick ./kapacitor/
# helm install --name dash --namespace tick ./chronograf/
# sleep 15
# helm install --name polling --namespace tick ./telegraf-s/
# helm install --name hosts --namespace tick ./telegraf-ds/
# kubectl get svc -w --namespace tick -l app=dash-chronograf

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

	
	echo "Creating chart for" $component
	if [ $component == "influxdb" ]; then
		helm install --name data --namespace tick influxdb
	elif [ $component == "kapacitor" ]; then
		helm install --name alerts --namespace tick kapacitor
	elif [ $component == "chronograf" ]; then
		helm install --name dash --namespace tick chronograf
	elif [ $component == "telegraf-s" ]; then
		helm install --name polling --namespace tick telegraf-s
	elif [ $component == "telegraf-ds" ]; then
		helm install --name hosts --namespace tick telegraf-ds	
	else
		helm install --name data --namespace tick influxdb
		sleep 10
		helm install --name alerts --namespace tick kapacitor
		sleep 10
		helm install --name dash --namespace tick chronograf
		helm install --name polling --namespace tick telegraf-s
		helm install --name hosts --namespace tick telegraf-ds
	fi

# 	kubectl describe services data-influxdb > output.txt
# 	data=`sed -n 's/^NodePort: //p' output.txt`
# 	data1=`echo $data | cut -b 5-9`
# 	echo $data1
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

function usage
{
	cat <<EOF

    Usage:
        -c component:  The name of the component. Valid options are influxdb, kapacitor, chronograf, telegraf-s, telegraf-ds and all
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
