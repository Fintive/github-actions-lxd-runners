# GitHub Actions LXD Runners

Automated, scalable GitHub Actions self-hosted runners using LXD containers and Terraform.

## Overview

This project provides Infrastructure as Code (IaC) to deploy multiple GitHub Actions self-hosted runners as LXD containers. Each runner is fully automated, containerized, and configured with all necessary dependencies for modern CI/CD workflows.

## Features

- **Fully Automated**: Zero manual configuration required
- **Scalable**: Deploy multiple runners simultaneously
- **Docker Support**: Full Docker and Docker Compose capabilities
- **Modern Stack**: Node.js 22, Yarn, AWS CLI, and browser testing support
- **Secure**: Isolated containers with proper security settings
- **Unique Names**: Automatic timestamp-based naming to prevent conflicts

## Prerequisites

- LXD installed and configured
- Terraform installed
- GitHub repository with Actions enabled
- GitHub registration token (generated from repository settings)

## Quick Start

1. **Clone and configure**:
   ```bash
   git clone <this-repo>
   cd github-actions-lxd-runners
   ```

2. **Set your variables** (optional - defaults work for Fintive):
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Deploy runners**:
   ```bash
   # Generate token at: https://github.com/YOUR_ORG/YOUR_REPO/settings/actions/runners
   terraform apply -var="access_token=YOUR_GITHUB_TOKEN"
   ```

4. **Scale up/down**:
   ```bash
   # Deploy 8 runners instead of 4
   terraform apply -var="access_token=YOUR_TOKEN" -var="runner_count=8"
   ```

## Configuration

### Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `runner_count` | Number of runners to deploy | `4` |
| `repo_url` | GitHub repository URL | `https://github.com/Fintive/fintive-core` |
| `runner_name` | Base name for runners | `fintive-runner-v2` |
| `access_token` | GitHub registration token | Required |
| `labels` | Runner labels | `linux,x64,self-hostedv2` |
| `node_version` | Node.js version | `22` |
| `yarn_version` | Yarn version | `1.22.21` |
| `network_interface` | Network interface for bridge (auto-detected) | `""` |
| `lxd_storage_pool` | LXD storage pool | `default` |
| `container_size` | Container root filesystem size | `20GB` |
| `runner_version` | GitHub Actions runner version | `""` (latest) |

### Runner Capabilities

Each runner includes:

- **Docker**: Latest Docker CE with Compose plugin
- **Node.js**: Version 22 with npm and Yarn
- **AWS CLI**: For ECR and cloud operations  
- **Browser Testing**: Cypress dependencies (libgbm1, libxshmfence1, libglu1-mesa)
- **Build Tools**: Essential compilation and development tools
- **Git**: Latest version for repository operations

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Terraform     │───▶│   LXD Profile    │───▶│  LXD Container  │
│   Configuration │    │   cloud-init.yml │    │   (Runner 1-N)  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │  GitHub Actions  │
                       │     Service      │
                       └──────────────────┘
```

## File Structure

```
├── main.tf              # Main Terraform configuration
├── variables.tf         # Variable definitions
├── cloud-init.yml       # Container initialization script
├── terraform.tfvars.example  # Example variables file
├── verify-runners.sh    # Post-deployment verification script
└── README.md           # This file
```

## Usage Examples

### Deploy Single Runner
```bash
terraform apply -var="access_token=YOUR_TOKEN" -var="runner_count=1"
```

### Deploy to Different Repository
```bash
terraform apply \
  -var="access_token=YOUR_TOKEN" \
  -var="repo_url=https://github.com/YourOrg/your-repo" \
  -var="runner_name=your-runner"
```

### Custom Labels
```bash
terraform apply \
  -var="access_token=YOUR_TOKEN" \
  -var="labels=linux,x64,custom-label,gpu"
```

## Monitoring

Check runner status:
```bash
# Verify deployment with included script
./verify-runners.sh

# List all containers
lxc list | grep runner

# Check specific runner service
lxc exec runner-name -- systemctl status actions.runner.service-name.service

# View runner logs
lxc exec runner-name -- journalctl -u actions.runner.service-name.service -f
```

## Token Management

GitHub registration tokens expire after 1 hour. For production use:

1. Generate new token from: `https://github.com/YOUR_ORG/YOUR_REPO/settings/actions/runners`
2. Redeploy: `terraform apply -var="access_token=NEW_TOKEN"`

## Scaling

This infrastructure supports deployment across multiple hosts and is designed for cross-machine portability:

```bash
# Host 1
terraform apply -var="access_token=TOKEN1" -var="runner_count=4"

# Host 2  
terraform apply -var="access_token=TOKEN2" -var="runner_count=4"
```

### Cross-Machine Features
- Automatic network interface detection
- Configurable storage pools and container sizes  
- Retry logic for robust deployment
- Post-deployment verification

## Troubleshooting

### Runner Not Connecting
- Verify token is valid and not expired
- Check network connectivity: `lxc exec runner -- curl -I https://github.com`
- Review logs: `lxc exec runner -- journalctl -u actions.runner.*service`

### Container Creation Fails
- Verify LXD storage pool: `lxc storage list`
- Check available space: `df -h /media/internal/4tbssd`
- Review cloud-init logs: `lxc exec runner -- cat /var/log/cloud-init-output.log`

### Docker Issues
- Verify Docker service: `lxc exec runner -- systemctl status docker`
- Check user groups: `lxc exec runner -- groups runner`
- Test Docker: `lxc exec runner -- docker run hello-world`

## Security Notes

- Containers run with `security.nesting=true` for Docker support
- Containers are **not** privileged (`security.privileged=false`)
- Each runner has isolated filesystem and network namespace
- Runners automatically clean up after job completion

## Contributing

1. Fork the repository
2. Create feature branch
3. Test changes with single runner deployment
4. Submit pull request

## License

MIT License - see LICENSE file for details.