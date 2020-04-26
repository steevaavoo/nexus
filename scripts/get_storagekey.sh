#!/bin/bash
# Runs Terraform apply
# Ensure strict mode and predictable pipeline failure
set -euo pipefail

taskMessage="Getting Storage Account Key"
echo "STARTED: $taskMessage..."

# Run CLI command
storageKey=(az storage account keys list --resource-group $TERRAFORM_STORAGE_RG --account-name $TERRAFORM_STORAGE_ACCOUNT --query [0].value -o tsv)

# Set env var
# https://help.github.com/en/actions/reference/development-tools-for-github-actions#set-an-environment-variable-set-env
# ::set-env name={name}::{value}
echo "::set-env name=STORAGE_KEY::$storageKey"

# Mask sensitive env var
# https://help.github.com/en/actions/reference/development-tools-for-github-actions#example-masking-an-environment-variable
STORAGE_KEY=$storageKey
echo "::add-mask::$STORAGE_KEY"

# also mask token format
$__STORAGE_KEY__ = $storageKey
echo "::add-mask::$__STORAGE_KEY__"

echo "FINISHED: $taskMessage."
