# `kube-influxdb` Documentation

## Introduction

Kube-InfluxDB is designed to provide users end to end Kubernetes monitoring solution using TICK stack. This solution includes following packages:

1. Telegraf-ds and Telegraf-s
2. Influxdb
3. Chronograf
4. Kapcitor
5. Kube-state-metrics
6. Telegraf input plugin – Kubernetes and Prometheus

It is a collection of manifests including dashboards rules and definitions that can easily be deployed. This solution will collect metrics from underlying resources, the bare metal Kubernetes is running on and Kubernetes resources like services, pods and ingress etc.

## Project Baseline chart

We are using TICK stack helm chart as a baseline charts for this project. We are leveraging single deployment solution on top it.

GitHub Repo: https://github.com/influxdata/tick-charts

TICK Stack:
<p align="left">
  <img src="https://github.com/kube-influxdb/blob/multiple_oss/docs/images/tickstack.png"/>
</p>

From the physical/infrastructure point of view, a Kubernetes cluster is made up of a set of nodes overseen by a master. The master’s tasks include orchestrating containers across nodes, keeping track of state and exposing cluster control through a REST API and a UI.

On the other hand, from the logical/application point of view, Kubernetes clusters are arranged in the hierarchical fashion shown in this picture:

<p align="left">
  <img src="https://github.com/kube-influxdb/blob/multiple_oss/docs/images/kubernetes_tickstackpod.png"/>
</p>

All containers run inside pods. A pod is a set of containers that live together. They are always co-located and co-scheduled, and run in a shared context with shared storage. The containers in the pod are guaranteed to be co-located on the same machine and can share resources.

1. Pods typically sit behind services, which take care of balancing the traffic, and also expose the set of pods as a single discoverable IP address/port.
2. Services are scaled horizontally by replica sets (formerly replication controllers) which create/destroy pods for each service as needed.
3. ReplicaSets are further controlled by deployments which allow you to declare state for a number of running replicasets and pods
4. Namespaces are virtual clusters that can include one or more services.

Typical Kubernetes master and node representation. Telegraf-ds is running as daemon set on each node. Inlfuxdb and Chronograf is running on master in separate namespace.

<p align="left">
  <img src="https://github.com/kube-influxdb/blob/multiple_oss/docs/images/tickstack-pod.png"/>
</p>

## Components diagram of `kube-influxdb`

<p align="left">
  <img src="https://github.com/kube-influxdb/blob/multiple_oss/docs/images/ube-influxdb.png"/>
</p>

### K8S Monitoring Dashboards

Kube-Influxdb has a following inbuilt monitoring dashboard for Kubernetes Cluster.

1. K8S Cluster Health Dashboard
2. K8S Cluster Capacity Planning Dashboard
3. K8S Cluster Usage Metrics.
4. K8S Node Metrics Dashboard
5. K8S Pod Metrics Dashboard
6. K8S Container Metrics Dashboard
7. K8S Deployment Metrics Dashboard
8. K8S Resource Request Metrics
