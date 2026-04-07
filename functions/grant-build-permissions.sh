#!/usr/bin/env bash
# Rulează din Git Bash / macOS / Linux după: gcloud auth login
# Remediu oficial: roles/cloudbuild.builds.builder pe Compute default SA.
set -euo pipefail
PROJECT_ID="${1:-nabour-4b4e4}"
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
echo "Project: $PROJECT_ID ($PROJECT_NUMBER)"
echo "Granting roles/cloudbuild.builds.builder -> $COMPUTE_SA"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${COMPUTE_SA}" \
  --role="roles/cloudbuild.builds.builder"
echo "Done. Run: firebase deploy --only functions"
