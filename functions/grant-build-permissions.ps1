# Necesită Google Cloud SDK: https://cloud.google.com/sdk/docs/install
# Rulează: powershell -ExecutionPolicy Bypass -File .\grant-build-permissions.ps1
param([string]$ProjectId = "nabour-4b4e4")

$num = gcloud projects describe $ProjectId --format="value(projectNumber)"
if (-not $num) { throw "gcloud failed sau proiect inexistent: $ProjectId" }
$sa = "$num-compute@developer.gserviceaccount.com"
Write-Host "Granting roles/cloudbuild.builds.builder to $sa"
gcloud projects add-iam-policy-binding $ProjectId `
  --member="serviceAccount:$sa" `
  --role="roles/cloudbuild.builds.builder"
Write-Host "Done. Run: firebase deploy --only functions"
