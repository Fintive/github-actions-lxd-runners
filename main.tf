terraform {
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "~> 2.0"
    }
  }
}

# Configure the LXD Provider
provider "lxd" {
  generate_client_certificates = true
  accept_remote_certificate    = true
}

# Auto-detect primary network interface if not specified
data "external" "network_interface" {
  program = ["bash", "-c", "echo '{\"interface\":\"'$(ip route | grep default | head -1 | awk '{print $5}')'\"}'"
  ]
}

# Generate registration token using gh CLI (commented out - need proper token scope)
# data "external" "runner_token" {
#   program = ["bash", "-c", "gh api repos/Fintive/fintive-core/actions/runners/registration-token --jq '{token: .token}'"]
# }

# Create a profile for GitHub runners with necessary configurations
resource "lxd_profile" "github_runner" {
  name = "github-runner-profile"

  config = {
    "security.nesting"    = "true"
    "security.privileged" = "false"
    "user.user-data" = templatefile("${path.module}/cloud-init.yml", {
      repo_url                = var.repo_url
      runner_name            = var.runner_name
      access_token           = var.access_token
      runner_workdir         = var.runner_workdir
      runner_scope           = var.runner_scope
      labels                 = var.labels
      runner_replace_existing = var.runner_replace_existing
      node_version           = var.node_version
      yarn_version           = var.yarn_version
    })
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      "path" = "/"
      "pool" = var.lxd_storage_pool
      "size" = var.container_size
    }
  }

}

# Create multiple GitHub runner containers
resource "lxd_instance" "github_runner" {
  count     = var.runner_count
  name      = "${var.runner_name}-${count.index + 1}"
  image     = "ubuntu:22.04"
  ephemeral = false
  profiles  = ["default", lxd_profile.github_runner.name]

  config = {
    "boot.autostart" = "true"
    "security.nesting" = "true"
    "security.privileged" = "false"
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      "nictype" = "macvlan"
      "parent"  = var.network_interface != "" ? var.network_interface : data.external.network_interface.result.interface
    }
  }

}

# Output the container's IP addresses
output "container_ips" {
  value = { for i, instance in lxd_instance.github_runner : instance.name => instance.ipv4_address }
}

output "container_names" {
  value = [for instance in lxd_instance.github_runner : instance.name]
} 