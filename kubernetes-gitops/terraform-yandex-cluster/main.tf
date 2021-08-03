terraform {
  required_version = ">= 0.14.9"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.61.0"
    }
  }

}

provider "yandex" {
  token     = var.iam_token
  cloud_id  = var.cloudID
  folder_id = var.folderID
  zone      = "ru-central1-a"
}

# yandex_kubernetes_cluster.otus-gitops:
resource "yandex_kubernetes_cluster" "otus-gitops" {
    cluster_ipv4_range       = "10.112.0.0/16"
    description              = "Otus gitops homework"
    labels                   = {}
    name                     = "otus-gitops"
    network_id               = var.networkID
    node_ipv4_cidr_mask_size = 24
    node_service_account_id  = var.serviceAccount
    release_channel          = "REGULAR"
    service_account_id       = var.serviceAccount
    service_ipv4_range       = "10.96.0.0/16"

    kms_provider { 
          key_id = var.kmsKey
        }  

    master {
        public_ip              = true
        security_group_ids     = []
        version                = "1.19"

        maintenance_policy {
            auto_upgrade = true
        }

        zonal {
            zone = "ru-central1-a"
        }
    }

    timeouts {}
}

resource "yandex_kubernetes_node_group" "worker1_group" {
# yandex_kubernetes_node_group.worker1_group:
    allowed_unsafe_sysctls = []
    cluster_id             = yandex_kubernetes_cluster.otus-gitops.id
    labels                 = {}
    name                   = "worker-group1"
    node_labels            = {}
    node_taints            = []
    version                = "1.19"

    allocation_policy {
        location {
            zone      = "ru-central1-a"
        }
    }

    deploy_policy {
        max_expansion   = 2
        max_unavailable = 0
    }

    instance_template {
        metadata                  = {
            "ssh-keys" = var.sshKey
        }
        platform_id               = "standard-v2"

        boot_disk {
            size = 64
            type = "network-hdd"
        }

        network_interface {
            ipv4               = true
            ipv6               = false
            nat                = true
            security_group_ids = []
            subnet_ids         = var.subnetID
        }

        resources {
            core_fraction = 100
            cores         = 2
            gpus          = 0
            memory        = 8
        }

        scheduling_policy {
            preemptible = false
        }
    }

    maintenance_policy {
        auto_repair  = true
        auto_upgrade = true
    }

    scale_policy {

        fixed_scale {
            size = 2
        }
    }

    timeouts {}
}
