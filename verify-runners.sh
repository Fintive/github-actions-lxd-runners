#!/bin/bash

# GitHub Actions LXD Runners Verification Script
# This script verifies that the runners are properly deployed and connected

set -e

echo "🔍 Verifying GitHub Actions LXD Runners..."
echo "==========================================="

# Check if Terraform state exists
if [ ! -f "terraform.tfstate" ]; then
    echo "❌ No terraform.tfstate found. Run 'terraform apply' first."
    exit 1
fi

# Get container names from Terraform output
CONTAINER_NAMES=$(terraform output -json container_names 2>/dev/null | jq -r '.[]' 2>/dev/null || echo "")

if [ -z "$CONTAINER_NAMES" ]; then
    echo "❌ No containers found in Terraform state."
    exit 1
fi

echo "📋 Found containers:"
echo "$CONTAINER_NAMES" | while read container; do
    echo "  - $container"
done
echo ""

# Verify each container
ALL_GOOD=true
echo "$CONTAINER_NAMES" | while read container; do
    echo "🔎 Checking container: $container"
    
    # Check if container exists and is running
    if ! lxc info "$container" >/dev/null 2>&1; then
        echo "  ❌ Container $container not found"
        ALL_GOOD=false
        continue
    fi
    
    STATUS=$(lxc info "$container" | grep "Status:" | awk '{print $2}')
    if [ "$STATUS" != "Running" ]; then
        echo "  ❌ Container $container is not running (Status: $STATUS)"
        ALL_GOOD=false
        continue
    fi
    echo "  ✅ Container is running"
    
    # Check network connectivity
    if lxc exec "$container" -- ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        echo "  ✅ Network connectivity OK"
    else
        echo "  ❌ No network connectivity"
        ALL_GOOD=false
    fi
    
    # Check if GitHub Actions runner service exists
    if lxc exec "$container" -- systemctl list-units --type=service | grep -q "actions.runner"; then
        RUNNER_SERVICE=$(lxc exec "$container" -- systemctl list-units --type=service | grep "actions.runner" | head -1 | awk '{print $1}')
        echo "  ✅ Found runner service: $RUNNER_SERVICE"
        
        # Check service status
        if lxc exec "$container" -- systemctl is-active "$RUNNER_SERVICE" >/dev/null 2>&1; then
            echo "  ✅ Runner service is active"
        else
            echo "  ❌ Runner service is not active"
            ALL_GOOD=false
        fi
    else
        echo "  ❌ No GitHub Actions runner service found"
        ALL_GOOD=false
    fi
    
    # Check cloud-init status
    CLOUD_INIT_STATUS=$(lxc exec "$container" -- cloud-init status 2>/dev/null | cut -d' ' -f2 || echo "unknown")
    case "$CLOUD_INIT_STATUS" in
        "done")
            echo "  ✅ Cloud-init completed successfully"
            ;;
        "running")
            echo "  ⏳ Cloud-init still running"
            ;;
        "error")
            echo "  ❌ Cloud-init failed"
            ALL_GOOD=false
            ;;
        *)
            echo "  ⚠️  Cloud-init status unknown: $CLOUD_INIT_STATUS"
            ;;
    esac
    
    echo ""
done

# Final summary
echo "📊 Summary"
echo "=========="
if [ "$ALL_GOOD" = "true" ]; then
    echo "✅ All runners appear to be working correctly!"
    echo ""
    echo "💡 Next steps:"
    echo "   - Check GitHub repository settings > Actions > Runners"
    echo "   - Runners should appear as 'Idle' if connected properly"
    echo "   - Test by running a workflow that uses labels: linux,x64,self-hostedv2"
else
    echo "❌ Some issues found. Check the details above."
    echo ""
    echo "🔧 Troubleshooting tips:"
    echo "   - Check logs: lxc exec <container> -- tail -f /var/log/cloud-init-output.log"
    echo "   - Check runner logs: lxc exec <container> -- journalctl -u actions.runner.*"
    echo "   - Restart runner: lxc exec <container> -- sudo systemctl restart actions.runner.*"
fi

echo ""
echo "🔗 Useful commands:"
echo "   terraform output container_ips    # Show container IP addresses"
echo "   lxc list                         # List all containers"
echo "   lxc exec <container> -- bash     # Access container shell"