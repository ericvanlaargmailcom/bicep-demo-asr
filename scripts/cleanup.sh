#!/usr/bin/env bash
set -euo pipefail

environment="${1:-dev}"
application_name="${2:-asrdm}"
location="${3:-westeurope}"
location_short="we"

resource_group_name="rg-asr-${application_name}-${environment}-${location_short}-001"
key_vault_name="kv-asr-${application_name}-${environment}-${location_short}-001"

resource_group_deleted="false"

if [[ "$(az group exists --name "${resource_group_name}")" == "true" ]]; then
  echo "Deleting resource group: ${resource_group_name}"
  az group delete \
    --name "${resource_group_name}" \
    --yes
  resource_group_deleted="true"
else
  echo "Resource group ${resource_group_name} does not exist; continuing with Key Vault purge check."
fi

echo "Checking deleted Key Vault state: ${key_vault_name}"
deleted_vault_count="$(
  az keyvault list-deleted \
    --query "[?name=='${key_vault_name}'] | length(@)" \
    -o tsv
)"

if [[ "${resource_group_deleted}" == "true" ]]; then
  for attempt in {1..30}; do
    if [[ "${deleted_vault_count}" == "1" ]]; then
      break
    fi

    echo "Waiting for deleted Key Vault to become purgeable... attempt ${attempt}/30"
    sleep 10

    deleted_vault_count="$(
      az keyvault list-deleted \
        --query "[?name=='${key_vault_name}'] | length(@)" \
        -o tsv
    )"
  done
fi

if [[ "${deleted_vault_count}" == "1" ]]; then
  echo "Purging deleted Key Vault: ${key_vault_name}"
  subscription_id="$(az account show --query id -o tsv)"
  az rest \
    --method post \
    --url "https://management.azure.com/subscriptions/${subscription_id}/providers/Microsoft.KeyVault/locations/${location}/deletedVaults/${key_vault_name}/purge?api-version=2023-07-01"
else
  echo "No deleted Key Vault found for ${key_vault_name}; nothing to purge."
fi

echo "Cleanup completed for ${environment}."
