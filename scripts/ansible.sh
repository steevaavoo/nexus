#!/bin/bash

# Prepares env vars and runs Ansible Playbook

# Ensure strict mode and predictable pipeline failure
set -euo pipefail
trap "echo 'error: Script failed: see failed command above'" ERR

#region Init
# env vars set in GH build workflow:
# Init tasks:
#   $AKS_CLUSTER_NAME
#   $AKS_RG_NAME
# Run Ansible playbook task:
#   $NEXUS_ADMIN_PASSWORD
#   $DEMO_USER_PASSWORD

# Get AKS Cluster credentials
az aks get-credentials --resource-group "$AKS_RG_NAME" --name "$AKS_CLUSTER_NAME" --overwrite-existing
#endregion Init


#region Passwords
# Get auto-generated admin password from within Nexus container
# Get pod name
podName=$(kubectl get pod -n ingress -l app=nexus -o jsonpath="{.items[0].metadata.name}")

# Get admin password from pod
# NOTE: "/nexus-data/admin.password" is deleted after the admin password is changed
adminPassword=$(kubectl exec -n ingress "$podName" -- sh -c "test -f /nexus-data/admin.password && cat /nexus-data/admin.password || echo 'NOT_DEFINED'")
if [ "$CI_DEBUG" == "true" ]; then
    echo "Default admin password is: [$adminPassword]"
fi

# Set environment variables for passwords
export AUTOGENERATED_ADMIN_PASSWORD=$adminPassword
export NEW_ADMIN_PASSWORD=$NEXUS_ADMIN_PASSWORD
#endregion Passwords


#region Set base url
protocol="http"
if [ "$ENABLE_TLS_INGRESS" == "true" ]; then
    protocol="https"
fi
nexusBaseUrl="$protocol://$DNS_DOMAIN_NAME"
#endregion Set base url


# Run Ansible Playbook
pushd ansible
ansible-playbook site.yml --extra-vars "api_base_uri=$nexusBaseUrl"
popd