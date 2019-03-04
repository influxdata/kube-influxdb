#!/bin/bash
source ~/.bashrc
function main
{
	initScript "$@"
	
	echo "Service:" $SERVICE
	echo "Action:" $ACTION
	
	if [[ $COMPONENT == 'minikube' ]]; then
		echo "Component:" $COMPONENT
		scripts/minikube.sh $SERVICE $ACTION
	
	elif [[ $COMPONENT == 'oss-k8s' ]]; then
		echo "Component:" $COMPONENT $ACTION
		scripts/oss-k8s.sh $SERVICE $ACTION

	elif [[ $COMPONENT == 'aws-eks' ]]; then
		echo "Component:" $COMPONENT $ACTION
		scripts/aws-eks.sh $SERVICE $ACTION

	elif [[ $COMPONENT == 'gcp' ]]; then
		echo "Component:" $COMPONENT $ACTION
		scripts/gcp.sh $SERVICE $ACTION

	elif [[ $COMPONENT == 'openshift' ]]; then
		echo "Component:" $COMPONENT $ACTION
		scripts/openshift.sh $SERVICE $ACTION

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
        -c component: Valid options are oss-k8s, aws-eks, gcp, openshift and minikube 
        -a action: Valid options are create and destroy
        -s service: The name of the component. Valid options are influxdb, kapacitor, telegraf-s, telegraf-ds, chronograf and all
    Examples:
        ./create.sh -s influxdb -a create -c oss-k8s
        ./create.sh -s influxdb -a destroy -c oss-k8s

        ./create.sh -s all -a create -c oss-k8s
        ./create.sh -s all -a destroy -c oss-k8s
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
