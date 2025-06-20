variable "repo_url" {
  description = "GitHub repository URL for runner registration"
  type        = string
  default     = "https://github.com/Fintive/fintive-core"
}

variable "runner_name" {
  description = "Name of the GitHub runner"
  type        = string
  default     = "fintive-runner-v2"
}

variable "access_token" {
  description = "GitHub registration token (generate from repository settings)"
  type        = string
  sensitive   = true
  # No default - must be provided via command line or terraform.tfvars
}

variable "runner_workdir" {
  description = "Working directory for the runner"
  type        = string
  default     = "/tmp/runner/work"
}

variable "runner_scope" {
  description = "Scope of the runner (repo, org, enterprise)"
  type        = string
  default     = "repo"
}

variable "labels" {
  description = "Labels for the runner"
  type        = string
  default     = "linux,x64,self-hostedv2"
}

variable "runner_replace_existing" {
  description = "Whether to replace existing runners with the same name"
  type        = string
  default     = "true"
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for container access"
  type        = string
  default     = "/home/jeff/.ssh/id_ed25519"
}

variable "node_version" {
  description = "Node.js version to install"
  type        = string
  default     = "22"
}

variable "yarn_version" {
  description = "Yarn version to install"
  type        = string
  default     = "1.22.21"
}

variable "runner_count" {
  description = "Number of GitHub runner instances to create"
  type        = number
  default     = 4
}

variable "network_interface" {
  description = "Network interface to bridge containers to (auto-detected if not specified)"
  type        = string
  default     = ""
}

variable "lxd_storage_pool" {
  description = "LXD storage pool to use for containers"
  type        = string
  default     = "default"
}

variable "container_size" {
  description = "Container root filesystem size"
  type        = string
  default     = "20GB"
}

variable "runner_version" {
  description = "GitHub Actions runner version (latest if not specified)"
  type        = string
  default     = ""
}