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

## Homework 9 - CRD

Задания со значком выполнялись, задания со звездочкой - нет.
В Kubernetes 1.20+ удаление PV через garbage collector не работает, т.к. crd - это namespaced object, а pv - cluster-wide (https://kubernetes.io/docs/concepts/workloads/controllers/garbage-collection/). Поэтому пришлось немного дописать оператор, добавив в delete_objects_make_backup удаление PV через api. 

Вывод kubectl get jobs:
> $ (⎈ minikube:default) kubectl get jobs                                                                                                   [±kubernetes-operators ✓]
NAME                         COMPLETIONS   DURATION   AGE
backup-mysql-instance-job    1/1           2s         26h
restore-mysql-instance-job   1/1           65s        25h

Вывод при запущенном MySQL:
![screenshot](./images/operator-homework.png)

## Homework Vault

```bash
> $ (⎈ kind-kind:default) helm status vault                                                                                                                [±master ●]
NAME: vault
LAST DEPLOYED: Wed Aug  4 14:20:32 2021
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
Thank you for installing HashiCorp Vault!

Now that you have deployed Vault, you should look over the docs on using
Vault with Kubernetes available here:

https://www.vaultproject.io/docs/


Your release is named vault. To learn more about the release, try:

  $ helm status vault
  $ helm get manifest vault
```

```bash
> $ (⎈ kind-kind:default) kubectl exec -it vault-0 -- vault operator init --key-shares=1 --key-threshold=1                                                 [±master ●]
Unseal Key 1: zL1J5skiMD1dguB+UmitmxoMdzo3/axuiqSi+A/Z5OU=

Initial Root Token: s.l3LYYiyrPMJYe4eV45KnT0be

Vault initialized with 1 key shares and a key threshold of 1. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 1 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated master key. Without at least 1 keys to
reconstruct the master key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.
```

```bash
> $ (⎈ kind-kind:default) for i in {0..2}; do echo "vault-$i status:";  kubectl exec -it vault-$i -- vault status; echo " ";  done                                    
vault-0 status:             
Key             Value        
---             -----                                                              
Seal Type       shamir                                                             
Initialized     true       
Sealed          false                                                              
Total Shares    1             
Threshold       1                                                                  
Version         1.8.0
Storage Type    consul
Cluster Name    vault-cluster-0271dc10                                                                                                                                 
Cluster ID      24081be9-9a88-af95-d379-229d673be748                                                                                                                   
HA Enabled      true
HA Cluster      https://vault-0.vault-internal:8201
HA Mode         active
Active Since    2021-08-04T11:36:12.699965108Z
  
vault-1 status:
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.8.0
Storage Type           consul
Cluster Name           vault-cluster-0271dc10
Cluster ID             24081be9-9a88-af95-d379-229d673be748
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.244.1.3:8200

 
vault-2 status:
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.8.0
Storage Type           consul
Cluster Name           vault-cluster-0271dc10
Cluster ID             24081be9-9a88-af95-d379-229d673be748
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.244.1.3:8200
```

```bash
> $ (⎈ kind-kind:default) kubectl exec -it vault-0 -- vault login                                                                                                     
Token (will be hidden): 
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                s.l3LYYiyrPMJYe4eV45KnT0be
token_accessor       C81PsBH18Qb8FbsYwsQkcxnn
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
```

```bash
> $ (⎈ kind-kind:default) kubectl exec -it vault-0 -- vault auth list                                                                                                 
Path      Type     Accessor               Description
----      ----     --------               -----------
token/    token    auth_token_0c0d4e38    token based credentials
```

```bash
> $ (⎈ kind-kind:default) kubectl exec -it vault-0 -- vault read otus/otus-ro/config                                                                                  
Key                 Value
---                 -----
refresh_interval    768h
password            asxcfgbnjk
username            otus
                                                                                                                                 
> $ (⎈ kind-kind:default) kubectl exec -it vault-0 -- vault kv get otus/otus-rw/config                                                                                
====== Data ======
Key         Value
---         -----
password    asxcfgbnjk
username    otus

```

```bash
> $ (⎈ kind-kind:default) kubectl exec -it vault-0 -- vault auth list                                                                                                 
Path           Type          Accessor                    Description
----           ----          --------                    -----------
kubernetes/    kubernetes    auth_kubernetes_487efb62    n/a
token/         token         auth_token_0c0d4e38         token based credentials
```

Т.к. исходная версия политики разрешает создание, но не изменение файлов в otus/otus-rw (включены права create, list, read) - то мы смогли создать otus/otus-rw/config1, но не смогли изменить otus/otus-rw/config. Для измененения необходимо добавить в список update, при необходимости удалять - добавить в список delete.
