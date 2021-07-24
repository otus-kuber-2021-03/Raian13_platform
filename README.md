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

## Homework 8

Домашняя работа выполнялась не в Google Cloud, а локально на кластере kind. Для имитации условий - создана 1 нода с ролью control-plane и 4 ноды worker. Для имитации пулов к нодам применены следующие команды
```
kubectl label nodes kind-worker pool=default-pool
kubectl label nodes kind-worker2 pool=infra-pool
kubectl label nodes kind-worker3 pool=infra-pool
kubectl label nodes kind-worker4 pool=infra-pool

kubectl taint node kind-worker2 node-role=infra:NoSchedule
kubectl taint node kind-worker3 node-role=infra:NoSche
dule
kubectl taint node kind-worker4 node-role=infra:NoSchedule
```

В кластере развернут MetalLB.
Установка Эластика и Кибаны - без существенных особенностей, Для fluent-bit пришлось изменить парсер для разбора логов.
Установка elasticsearch-exporter, prometheus-operator - без существенных особенностей.

Установка loki и promtail выполнена отдельными чартами - в общем чарте loki-stack используется изрядно устаревшая версия чарта promtail.

## Homework Gitops

Kubernetes развертывался в YandexCloud с помощью terraform. Файлы для развертывания в каталоге kubernetes-gitops/terraform-yandex-cluster, terraform.tfvars исключен из репозитория.
Для развертывания необходимо получить токен доступа и применить файлы:
```
export IAMTOKEN=`yc iam create-token`
terraform plan -var="iam_token=$IAMTOKEN"
terraform apply -var="iam_token=$IAMTOKEN"
```

Ссылка на репо в Гитлабе: https://gitlab.com/raian13/microservices_demo

В процессе выполнения ДЗ обнаружились следующие проблемы:
- ссылка на helm chart Redis в микросервисе cartservice неактуальна, переделано на bitnami
- версия API для Canary resource проапгрейжена до v1beta1, при валидной настройке canary предполагаемая проблема с неуспешным релизом фронтенда не воспроизвелась.

Вывод команды kubectl get canaries -n microservices:
NAME       STATUS      WEIGHT   LASTTRANSITIONTIME
frontend   Succeeded   0        2021-07-24T09:16:24Z

Вывод после успешной выкладки - в файле kubernetes-gitops/canaries.out
