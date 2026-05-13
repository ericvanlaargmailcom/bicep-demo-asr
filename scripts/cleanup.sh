#!/usr/bin/env bash
set -euo pipefail

environment="${1:-dev}"
application_name="${2:-asrdm}"
location="${3:-westeurope}"
location_short="we"

resource_group_name="rg-asr-${application_name}-${environment}-${location_short}-001"

if [[ "$(az group exists --name "${resource_group_name}")" == "true" ]]; then
  echo "Deleting resource group: ${resource_group_name}"
  az group delete \
    --name "${resource_group_name}" \
    --yes
else
  echo "Resource group ${resource_group_name} does not exist; nothing to delete."
fi

echo "Cleanup completed for ${environment}."
