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

```bash
> $ (⎈ kind-kind:default) kubectl exec -it vault-0 -- vault write pki_int/issue/example-dot-ru common_name="gitlab.example.ru" ttl="24h"        [±kubernetes-vault ●●]
Key                 Value                                                          
---                 -----                                                          
ca_chain            [-----BEGIN CERTIFICATE-----                                   
MIIDnDCCAoSgAwIBAgIUKuk+srBFIXjj1JZb0VUUAfnYQHEwDQYJKoZIhvcNAQEL                   
BQAwFTETMBEGA1UEAxMKZXhtYXBsZS5ydTAeFw0yMTA4MDUwOTQ0MDBaFw0yNjA4
MDQwOTQ0MzBaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1
dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALxTzUY2QKe/
yoRqT3ucjdbk9ZiLXPMVGhLh6AySYMnXMQuul+djNXkzQsQZ5ZxSWQfVjz4oEv3f
W11vhcm7YkpC1YzB8FZpjg1NuS9oVSt/Pw8d4PF219+5lH/YKxi1xY4MobEeA3uK
BS8F7mCdzw5L1gdDQa2kOs5Z4NukZKluIIWmVsjH3n6Rp/CETxxMtEwmU1hpPj+X
Ss5gjWxHmoDB1ZKEG9LJhO8oLjk0+DIjGMFbrJ7EC9GkUcaJeVZ4dKejKH7BNLt5
RR05i36PWjcFGxJUv8UkRmVXmfUp4P38A+OdgFgttLJSZY3ttLdeKXY7X0jmYEvx
VzG1nVMJn3cCAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw               
AwEB/zAdBgNVHQ4EFgQU7B+GGwqHSh83uVc4b2vA4eVHazswHwYDVR0jBBgwFoAU
IWsM4cxnv5qeRaARgTwYo3/wnhgwNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC                                                                                                       
hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc                                                                                                       
aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
kC0uOGFnF448T8SNN74nypxY9KiwRr8+OECVH61299XB794nJbG6x/MXi4ox1ufo
jR60ZwZfpfb+f8YBLGGpMBlaMA15UkMAUWQfG1QnK8XDjzhcaq6dZXfPH31xtQnz
ezNbNtSON83YU5aZh6amczlhKRUXPkhSUFNniTZsLqYOafX6eE5zLg9b6IXzI3sJ
dDvaWtlknYVDlAne+h2kCBTbBBSJl8oFR/GXzFxAYb6IjeFMfFCmpNL+ou6pVVwh
iGRGN/bpYJYb+0lcTbEyBvzu9xkCADu9HzS9XnHCg/yAS3Nyls3Lmt1Hv/gSYpqV
1zkC4q79qr2wSkjTrjRubg==
-----END CERTIFICATE-----]
certificate         -----BEGIN CERTIFICATE-----                                                                                                               [32/1946]
MIIDZzCCAk+gAwIBAgIUc++XsCsky4Fv2l+BiPsg3ixA2ugwDQYJKoZIhvcNAQEL
BQAwLDEqMCgGA1UEAxMhZXhhbXBsZS5ydSBJbnRlcm1lZGlhdGUgQXV0aG9yaXR5
MB4XDTIxMDgwNTEwMzU1N1oXDTIxMDgwNjEwMzYyNlowHDEaMBgGA1UEAxMRZ2l0
bGFiLmV4YW1wbGUucnUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC8
ay7GtYqz7Z9Mg90tfagCnK2jpnk4L4CTjrAuEpBmc/OGKyP1IpuD91h+MwaOexuM
BHKCADW2rfuSkuFfJ6QZLliPJOY0Vd0LyZ4WCdFqXJCp+E6CgB5vNoXLNRYW1fv1
KbELfaEMwqSCDmFDR64o7kqfHySVqVA/g2nXXqceMFz5CTyHWeFtT9j/JxsLXEAb
Qqy4xAODGoB8QrQb/iKxM5xpp/Lp9M78lemrkUmE84KzCh3j8ZnQYmN0d8VATkWw
5VTbIFPQ5y9fyeO7Uhs9gwaVxlZjJFvVIZnT8rz8yVRwjmDkG0uLWG4t1NiqYfEe
fRCep2wLEtQqvJi/S/oVAgMBAAGjgZAwgY0wDgYDVR0PAQH/BAQDAgOoMB0GA1Ud
JQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAdBgNVHQ4EFgQUni9H6eQoPxu+gqOX
jHsgULfH4rowHwYDVR0jBBgwFoAU7B+GGwqHSh83uVc4b2vA4eVHazswHAYDVR0R
BBUwE4IRZ2l0bGFiLmV4YW1wbGUucnUwDQYJKoZIhvcNAQELBQADggEBAGj9s8wU
vkommsA1XeByW1BrSHh0V1rQdEvoeuRx24/oIvgM/YgmMi7X5Hou2ifms8XKb+T1
rcRnA5B8XL9rdHQFmGo+7ykJBh4p20jk49YvtcC+vPZgJl12EGi2FH9X+8J4T66E
Xo5te56jvQvQFAPda/4kvHLoXoNNFL4gjYCBoOA0iKgKzR1uV0BxW14Ko75Y99XC
0wBxLkg4AkvYwR/09IOVim29+nmFv6/FdhwmYcYTz4FpX1zMNWP6iIraEfQkj9AJ
EvSGE6vYmwKExQs1qjiMly/ZTQVLsCqN9cDTfo9xDbXfGR0o9bO7gIVOCEP+OqJ5
whHAKaJvpTvvaWE=
-----END CERTIFICATE-----
expiration          1628246186
issuing_ca          -----BEGIN CERTIFICATE-----                                                                                                                        
MIIDnDCCAoSgAwIBAgIUKuk+srBFIXjj1JZb0VUUAfnYQHEwDQYJKoZIhvcNAQEL                                                                                                       
BQAwFTETMBEGA1UEAxMKZXhtYXBsZS5ydTAeFw0yMTA4MDUwOTQ0MDBaFw0yNjA4                                                                                                       
MDQwOTQ0MzBaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1                                                                                                       
dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALxTzUY2QKe/                                                                                                       
yoRqT3ucjdbk9ZiLXPMVGhLh6AySYMnXMQuul+djNXkzQsQZ5ZxSWQfVjz4oEv3f
W11vhcm7YkpC1YzB8FZpjg1NuS9oVSt/Pw8d4PF219+5lH/YKxi1xY4MobEeA3uK
BS8F7mCdzw5L1gdDQa2kOs5Z4NukZKluIIWmVsjH3n6Rp/CETxxMtEwmU1hpPj+X
Ss5gjWxHmoDB1ZKEG9LJhO8oLjk0+DIjGMFbrJ7EC9GkUcaJeVZ4dKejKH7BNLt5
RR05i36PWjcFGxJUv8UkRmVXmfUp4P38A+OdgFgttLJSZY3ttLdeKXY7X0jmYEvx
VzG1nVMJn3cCAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw
AwEB/zAdBgNVHQ4EFgQU7B+GGwqHSh83uVc4b2vA4eVHazswHwYDVR0jBBgwFoAU
IWsM4cxnv5qeRaARgTwYo3/wnhgwNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC
hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc
aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
kC0uOGFnF448T8SNN74nypxY9KiwRr8+OECVH61299XB794nJbG6x/MXi4ox1ufo
jR60ZwZfpfb+f8YBLGGpMBlaMA15UkMAUWQfG1QnK8XDjzhcaq6dZXfPH31xtQnz
ezNbNtSON83YU5aZh6amczlhKRUXPkhSUFNniTZsLqYOafX6eE5zLg9b6IXzI3sJ
dDvaWtlknYVDlAne+h2kCBTbBBSJl8oFR/GXzFxAYb6IjeFMfFCmpNL+ou6pVVwh
iGRGN/bpYJYb+0lcTbEyBvzu9xkCADu9HzS9XnHCg/yAS3Nyls3Lmt1Hv/gSYpqV
1zkC4q79qr2wSkjTrjRubg==
-----END CERTIFICATE-----
private_key         -----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAvGsuxrWKs+2fTIPdLX2oApyto6Z5OC+Ak46wLhKQZnPzhisj
9SKbg/dYfjMGjnsbjARyggA1tq37kpLhXyekGS5YjyTmNFXdC8meFgnRalyQqfhO
goAebzaFyzUWFtX79SmxC32hDMKkgg5hQ0euKO5Knx8klalQP4Np116nHjBc+Qk8
h1nhbU/Y/ycbC1xAG0KsuMQDgxqAfEK0G/4isTOcaafy6fTO/JXpq5FJhPOCswod
4/GZ0GJjdHfFQE5FsOVU2yBT0OcvX8nju1IbPYMGlcZWYyRb1SGZ0/K8/MlUcI5g
5BtLi1huLdTYqmHxHn0QnqdsCxLUKryYv0v6FQIDAQABAoIBAAiwMJH9IQ428NeI
ZRSJ7MtiCie3r3NFzXoAZGNbe8kdo6cWKixNkjo9l5kKJU1Ao/6K3fTcqZ1o3Gbf
2wCWRVzb5D2FiA/1vaGjhGSjw0JSTmFoD8a4va6HJxg9tG0NJPcjGwTaoCiEeS1+
GEIP9hnxEwPPXdKA4jBrkN/bf31GzUdeTaDDo9jQzr5bDfIR0oOTW+mNu+Y0ybaq
gyfpQW6WkECNrLRmuLjuk5Btbi4+4ti2VBMo+VEYQzByREMp32rPj5XI9vLakxP1
xEdV2SaT/Kl2AvEI3pN/RXay/2aJGy+Ut+fqKg90mfxWCMEhpijDSFK37SUpCwcs
+rbr7cECgYEA8s9VIwlTCijEeLNCMMQDOUQT+HnryNODXXsa6rjZcNKHhqwAACeH
ugQWoHthD/5J4YpwkPbHdZSc/thSRFDL4VvK0SCD2b1g1xYjJgd+yulDNemJPMVW
tlXziKcOuCNqJDr/KHBnF/FeZZJ3H+xC93NN+g5NajFdEi8+CpxL5XkCgYEAxqdz
okvwbNSrQ+dxV6GrqAOVFGawdf1MQg4ulCb2f2UGp9v9O0RA77oKAJbx0zijGVB8
AQZ9Sdb/0f95pb+4Y5jKV+dK6/HZibbbwCaD0Anx8cHeMDsLhO+wx/yQ0r00WPt0
frWanuEULBtHmqfkaiGopIqR7cQtWvQ1X42u3n0CgYAhCHv4rEgT1cAE+75BjCk0
HULqRwwA4mW4zgq3bDaI1tuBQt0tKDOa5vt9Ecv+tQWwHXl6/1fbc0B4m0115dgW
7LoHAXluogkOugBGKDbjvCBcsUzua5qEa+UZ7kBeZNMH4s7b3Y7o/vlssCRsv2PM
7m7pWhDGJbkXxD2Yi/L3YQKBgQCJM/5Zibl0cS4YqDFQJQk58b91Z7dYxql0tfbV
vFNjiZMfPIGZ/XocGJHv9lDvYZ7ETSJYUvMVnLjzgU+zescPgue97rGAZHmq8/Cy
tec0OKoyH4QmK6G5HxMqDPa5lpQhIQtEuIkiUrJsBCtgVbUc2EJx4oMHhQcOWrzC
UkkEwQKBgQCcE35NBnYM1CiGxwhFBan+8ID3JhwRMfx0Kr4JERXmgYmpJ5Hihja4
Ud7p8DvW1isuBPNDpy3bt26ZBbneNIKx3YF0shUUB3xladjhwD7vurUeHY6qGrI2
sejGxU3mCP100XZw2EMhDK/KDQ68Xa4ioBcPcpmW1qaHIJGnFSEF1w==
-----END RSA PRIVATE KEY-----
private_key_type    rsa
serial_number       73:ef:97:b0:2b:24:cb:81:6f:da:5f:81:88:fb:20:de:2c:40:da:e8

> $ (⎈ kind-kind:default) kubectl exec -it vault-0 -- vault write pki_int/revoke serial_number="73:ef:97:b0:2b:24:cb:81:6f:da:5f:81:88:fb:20:de:2c:40:da:e8"
Key                        Value
---                        -----
revocation_time            1628160010
revocation_time_rfc3339    2021-08-05T10:40:10.85608107Z

```
