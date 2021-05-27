# Raian13_platform

Raian13 Platform repository

## Homework 1

Развертывание minikube, изучение компонентов Kubernetes
Создание пода с веб-приложением

## Homework 2

Работа с Replicaset, Deployment и Daemonset

## Homework 3

Создание ServiceAccount и разграничение прав доступа в k8s

## Homework 4

Создание StatefulSet, использование secrets

## Homework 5

Kubernetes services and ingress

## Homework 6

Helm, jsonnet и kustomize - шаблонизация и развертывание (на примере Google Cloud)

## Homework 7

На базе кастомного образа Nginx с встроенным stub_status создан deployment с 3 подами. В каждом поде рядом с Nginx поднят nginx-exporter, собирающий метрики с данного пода. Service публикует порт приложения и порт nginx-exporter. Servicemonitor отслеживает сервис с лейблом nginx-custom - таким же, как в сервисе. 
Prometheus-exporter развернут через helm3, модифицированный values.yaml - в файле helm/values.yaml. 
Основные изменения:
- сервисы Grafana, Alertmanager, Prometheus переключены в режим NodePort для локального доступа к UI
- добавлен общий label monitoring: enabled, который используется в serviceMonitorSelector для target discovery

Команды для развертывания:
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus-operator prometheus-community/kube-prometheus-stack -f helm/values.yaml -n monitor
```

Результат в Графане  - часть официального дашборда nginx-exporter: ![График](./images/monitoring-nginx.png)
