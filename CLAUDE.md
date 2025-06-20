# Claude Setup Guide

This file contains instructions for Claude to help set up the GitHub Actions LXD Runners project on new machines.

## Project Overview

This is a Terraform-based infrastructure project that deploys GitHub Actions self-hosted runners as LXD containers. The project provides automated, scalable CI/CD infrastructure.

## Prerequisites to Verify

Before working on this project, ensure the following are installed:

1. **LXD** - Container management system
   ```bash
   lxd version
   ```

2. **Terraform** - Infrastructure as code tool
   ```bash
   terraform version
   ```

3. **jq** - JSON processor (required by verify-runners.sh)
   ```bash
   jq --version
   ```

## Project Structure

```
├── main.tf                    # Main Terraform configuration
├── variables.tf               # All configurable variables with defaults
├── cloud-init.yml            # Container initialization and runner setup
├── terraform.tfvars.example  # Example configuration file
├── verify-runners.sh         # Post-deployment verification script
└── README.md                 # User documentation
```

## Setup Commands

### Initial Setup
```bash
# 1. Copy example variables (optional - defaults work)
cp terraform.tfvars.example terraform.tfvars

# 2. Initialize Terraform
terraform init

# 3. Plan deployment (requires GitHub token)
terraform plan -var="access_token=YOUR_GITHUB_TOKEN"

# 4. Deploy runners
terraform apply -var="access_token=YOUR_GITHUB_TOKEN"

# 5. Verify deployment
./verify-runners.sh
```

### Common Operations

```bash
# Scale runners (change count)
terraform apply -var="access_token=TOKEN" -var="runner_count=8"

# Deploy to different repository
terraform apply -var="access_token=TOKEN" -var="repo_url=https://github.com/org/repo"

# Check runner status
lxc list | grep runner

# View specific runner logs
lxc exec RUNNER_NAME -- journalctl -u actions.runner.* -f

# Access container shell
lxc exec RUNNER_NAME -- bash
```

## Key Variables (variables.tf)

| Variable | Purpose | Default |
|----------|---------|---------|
| `access_token` | GitHub registration token (required) | None |
| `runner_count` | Number of containers to create | 4 |
| `repo_url` | Target GitHub repository | Fintive/fintive-core |
| `runner_name` | Base name for runners | fintive-runner-v2 |
| `labels` | Runner labels for GitHub | linux,x64,self-hostedv2 |
| `lxd_storage_pool` | LXD storage pool | default |
| `container_size` | Root filesystem size | 20GB |
| `network_interface` | Bridge interface (auto-detected) | "" |

## Recent Enhancements

### Cross-Machine Portability (Latest Commit)
- Automatic network interface detection
- Configurable storage pools and container sizes
- Retry logic in cloud-init for reliability
- Post-deployment verification script

### Security Features
- GitHub tokens handled securely (never stored in code)
- Container isolation with Docker support
- No privileged containers

## Troubleshooting

### Token Issues
GitHub registration tokens expire after 1 hour. Generate new tokens at:
`https://github.com/ORG/REPO/settings/actions/runners`

### Container Issues
```bash
# Check LXD status
lxc storage list
lxc profile list

# View cloud-init logs
lxc exec CONTAINER -- cat /var/log/cloud-init-output.log

# Check runner service
lxc exec CONTAINER -- systemctl status actions.runner.*
```

### Network Issues
```bash
# Test connectivity from container
lxc exec CONTAINER -- ping -c 1 github.com

# Check bridge configuration
ip link show
```

## Testing

Use the included verification script after deployment:
```bash
./verify-runners.sh
```

This script checks:
- Container status and network connectivity
- Runner service installation and status
- Cloud-init completion
- Provides troubleshooting guidance

## Development

When making changes:
1. Test with single runner first: `-var="runner_count=1"`
2. Use verification script to validate deployment
3. Check GitHub repository settings to confirm runner registration