#!/usr/bin/env bash
set -euo pipefail

application_name="${1:-asrdm}"
location_short="we"
environments=(dev test prod)
resource_groups=()

for environment in "${environments[@]}"; do
  resource_group_name="rg-asr-${application_name}-${environment}-${location_short}-001"

  if [[ "$(az group exists --name "${resource_group_name}")" == "true" ]]; then
    echo "Starting deletion: ${resource_group_name}"
    az group delete \
      --name "${resource_group_name}" \
      --yes \
      --no-wait
    resource_groups+=("${resource_group_name}")
  else
    echo "Resource group ${resource_group_name} does not exist; skipping."
  fi
done

if [[ "${#resource_groups[@]}" -eq 0 ]]; then
  echo "No resource groups found; nothing to delete."
  exit 0
fi

echo "Waiting for all deletions to complete..."

pids=()
for resource_group_name in "${resource_groups[@]}"; do
  az group wait \
    --name "${resource_group_name}" \
    --deleted \
    --timeout 3600 &
  pids+=("$!")
done

failed=0
for pid in "${pids[@]}"; do
  if ! wait "${pid}"; then
    failed=1
  fi
done

if [[ "${failed}" -ne 0 ]]; then
  echo "Cleanup failed or timed out for one or more resource groups." >&2
  exit 1
fi

echo "Cleanup completed for dev, test and prod."
