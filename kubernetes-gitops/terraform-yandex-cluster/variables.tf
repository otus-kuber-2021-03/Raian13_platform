
variable iam_token {
  type        = string
  default     = ""
  description = "Yandex.Cloud IAM token"
}

variable "cloudID" {
  type = string
  default = ""
}
variable "folderID" {
  type = string
  default = ""
}
variable "networkID" {
  type = string
  default =  ""
}
variable "subnetID" {
  type = list
  default = []
}
variable "serviceAccount" {
  type = string
  default = ""
}
variable "sshKey" {
  type = string
  default = ""
}
variable "kmsKey" {
  type = string
  default = ""
}