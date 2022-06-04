variable "location" {
  type        = string
  description = <<-EOF
    (Optional) The Azure location to create the resources

    [Default: eastus]
  EOF
  default     = "eastus"
}

variable "environment" {
  type        = string
  description = <<-EOF
        (Optional) The environment where the resources will be created, as an acronym.
        Possible values:
            - "dev"
            - "stage"
            - "prod"

    [Default: dev]
  EOF
  default     = "dev"

  validation {
    condition     = can(regex("dev|stage|prod", var.environment))
    error_message = "This must be an acronym of the environment."
  }
}

variable "project" {
    type = string
    description = "(Required) The project name"
}

variable "network_range" {
    type = string
    description = "(optional) The network range to use for the virtual network"
    default = "10.0.0.0/24"
}

variable "runner_size" {
    type = string
    description = "(Optional) The size of the runner VM"
    default = "Standard_DS1_v2"
}

variable "image_urn" {
    type = string
    description = "(Optional) The image URN to use for the runner VM"
    default = "Canonical:UbuntuServer:18.04-LTS:latest"
}
