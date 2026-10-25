#!/usr/bin/env bash
# Enroll renewable Application Default Credentials on this machine.
set -euo pipefail

if [[ "${1-}" == --help || "${1-}" == -h ]]; then
  printf 'Usage: %s ACCOUNT QUOTA_PROJECT\n' "$0"
  exit 0
fi
if [[ $# != 2 || -z "${1-}" || -z "${2-}" || "${1-}" == -* || "${2-}" == -* ]]; then
  printf 'Usage: %s ACCOUNT QUOTA_PROJECT\n' "$0" >&2
  exit 2
fi
if [[ -n "${GOOGLE_APPLICATION_CREDENTIALS-}" ]]; then
  printf 'Unset GOOGLE_APPLICATION_CREDENTIALS first so applications use the local ADC login.\n' >&2
  exit 1
fi

account=$1
quota_project=$2
umask 077

# Explicit flags avoid inheriting a different profile's project or billing project.
# The user completes browser consent; gcloud owns the resulting credential file.
gcloud auth application-default login "$account" \
  --project="$quota_project" --billing-project="$quota_project"
gcloud auth application-default set-quota-project "$quota_project"

# Verify refresh works without printing the access token.
gcloud auth application-default print-access-token >/dev/null
printf 'Application Default Credentials are ready on this machine.\n'
