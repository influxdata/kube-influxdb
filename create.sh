#!/bin/bash
source ~/.bashrc
function main
{
	initScript "$@"
	
	echo "Service:" $SERVICE
	echo "Action:" $ACTION
	
	if [[ $COMPONENT == 'minikube' ]]; then
		echo "Component:" $COMPONENT
		#chart_execution $ACTION $COMPONENT $SERVICE
		scripts/minikube.sh $SERVICE $ACTION
	
	elif [[ $COMPONENT == 'aws' ]]; then
		echo "Component:" $COMPONENT $ACTION
		#chart_execution $ACTION $COMPONENT $SERVICE
		scripts/aws.sh $SERVICE $ACTION

	elif [[ $COMPONENT == 'eks' ]]; then
		echo "Component:" $COMPONENT $ACTION
		#chart_execution $ACTION $COMPONENT $SERVICE
		scripts/eks.sh $SERVICE $ACTION

	elif [[ $COMPONENT == '' ]]; then
		echo "Component is empty"
	else 
		echo "Component is not valid !!!"
	fi		
}

function usage
{
	cat <<EOF

    Usage:
        -c component: Valid options are aws, eks and minikube 
        -a action: Valid options are create and destroy
        -s service: The name of the component. Valid options are influxdb, kapacitor, telegraf-s, telegraf-ds, chronograf and all
    Examples:
        ./create.sh -s influxdb -a create -c aws
        ./create.sh -s influxdb -a destroy -c aws

        ./create.sh -s all -a create -c aws
		./create.sh -s all -a delete -c aws
EOF
}

function initScript
{
	COMPONENT=""
	ACTION="create"
	SERVICE="all"
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
