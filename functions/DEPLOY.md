# Deploy Cloud Functions (Nabour)

## Prerequisite: `functions/.env`

Pentru `firebase deploy` în mod non-interactiv, copiază `.env.example` → `.env` (vezi fișierul din acest folder).

## Eroare: build service account / `nabourMaintainTokenWallet` nu se deployează

Mesaj tipic: *Could not build the function due to a missing permission on the build service account.*

Google recomandă: acordă rolul **`roles/cloudbuild.builds.builder`** contului **Compute Engine default** al proiectului:

`PROJECT_NUMBER-compute@developer.gserviceaccount.com`

### Pași (Google Cloud SDK instalat, autentificat ca owner)

```bash
PROJECT_ID=nabour-4b4e4
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${COMPUTE_SA}" \
  --role="roles/cloudbuild.builds.builder"
```

Pentru proiectul curent din repo, numărul poate fi verificat în Console → **IAM** sau cu comanda de mai sus. (Într-un deploy recent a apărut `project=346882274941` — înlocuiește mereu cu output-ul tău.)

### Dacă tot eșuează (proiecte noi, politici org)

- Ghid: [Cloud Build Service Account updates](https://cloud.google.com/build/docs/cloud-build-service-account-updates)
- SA custom cu `logging.logWriter`, `artifactregistry.writer`, `storage.objectViewer`: [Build custom SA](https://cloud.google.com/functions/docs/securing/build-custom-sa#grant_permissions)

## Deploy

```bash
cd functions && npm run build && cd ..
firebase deploy --only functions
```

Sau doar o funcție:

```bash
firebase deploy --only functions:nabourMaintainTokenWallet
```

## Politică artifact registry (mesaj la final de deploy)

```bash
firebase functions:artifacts:setpolicy
```

sau:

```bash
firebase deploy --only functions --force
```
