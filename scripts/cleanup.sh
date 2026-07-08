#!/usr/bin/env bash
set -euo pipefail

application_name="${1:-asrdm}"
location_short="we"
environments=(dev test prod)
resource_groups=()
resource_group_candidates=(
  "rg-leerlijn-portal-we-001"
  "rg-leerlijn-cli-we-001"
  "rg-leerlijn-arm-we-001"
  "rg-leerlijn-bicep-we-001"
)

echo "Checking deployment stacks..."

for environment in "${environments[@]}"; do
  stack_name="stack-asr-${application_name}-${environment}-${location_short}-001"
  existing_stack_name="$(az stack sub list \
    --query "[?name=='${stack_name}'].name | [0]" \
    --output tsv)"

  if [[ "${existing_stack_name}" == "${stack_name}" ]]; then
    echo "Deleting deployment stack and managed resources: ${stack_name}"
    az stack sub delete \
      --name "${stack_name}" \
      --action-on-unmanage deleteAll \
      --yes
  else
    echo "Deployment stack ${stack_name} does not exist; skipping."
  fi
done

for environment in "${environments[@]}"; do
  resource_group_candidates+=("rg-asr-${application_name}-${environment}-${location_short}-001")
done

echo "Checking resource groups..."

for resource_group_name in "${resource_group_candidates[@]}"; do
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

if [[ "${#resource_groups[@]}" -gt 0 ]]; then
  echo "Waiting for all resource group deletions to complete..."

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
else
  echo "No remaining resource groups found."
fi

remaining_stacks="$(az stack sub list \
  --query "[?starts_with(name, 'stack-asr-${application_name}-')].name" \
  --output tsv)"
remaining_resource_groups="$(az group list \
  --query "[?starts_with(name, 'rg-asr-${application_name}-') || starts_with(name, 'rg-leerlijn-')].name" \
  --output tsv)"

if [[ -n "${remaining_stacks}" || -n "${remaining_resource_groups}" ]]; then
  echo "Cleanup incomplete. The following course resources still exist:" >&2

  if [[ -n "${remaining_stacks}" ]]; then
    echo "Deployment stacks:" >&2
    echo "${remaining_stacks}" >&2
  fi

  if [[ -n "${remaining_resource_groups}" ]]; then
    echo "Resource groups:" >&2
    echo "${remaining_resource_groups}" >&2
  fi

  exit 1
fi

echo "Cleanup completed. No matching learning-path or final-lab resources remain."
