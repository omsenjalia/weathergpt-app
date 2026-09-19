# Backend Fix Plan — Make WeatherNext Live (for SIH 2026)

**Target repo:** `omsenjalia/weathergpt` (backend at `weathergpt-backend.vercel.app`)
**Current deployed:** v2.1.0, `weathernext.enabled=true`, `auth_mode=oauth`, `project=cool-archery-296710`, `has_refresh_token=true`
**Current failure:**
```
GET /v2/weather?requested_source=weathernext
→ selected_source: open_meteo
→ fallback_reasons: weathernext live_credentials_required (table cool-archery-296710.weathernext.weathernext_3_0_0_0p1deg)

GET /v2/weather/series?variable=temperature_2m
→ {status: unavailable, error: Requested source weathernext unavailable: live_credentials_required}
```
**You have:** All 9 accesses checked in image:
- WN2 on Earth Engine, BigQuery, GCS (Zarr)
- WN2 Mean on Earth Engine, BigQuery, GCS
- WN3 on Earth Engine, BigQuery, GCS
→ Project `cool-archery-296710` is allowlisted.

This plan fixes backend to actually return WeatherNext data to Flutter app.

---

## 1. Root Cause

Backend uses OAuth client ID + secret + refresh token to get BigQuery access token at runtime.

In Vercel serverless (`api/index.py`):
- `GOOGLE_OAUTH_CLIENT_ID=764086051850...`, `CLIENT_SECRET`, `REFRESH_TOKEN` exist (per `/dev`)
- But `google-cloud-bigquery` client with OAuth credentials fails to refresh in serverless (no persistent token cache, clock skew, or missing `google.auth` transport)
- Result: `live_credentials_required` and fallback to Open-Meteo

OAuth refresh is flaky for prod. Service account + ADC is reliable for serverless.

## 2. Solution Architecture

Keep OAuth as fallback, add service account as primary.

```
Flutter /v2/weather?requested_source=weathernext
  → FastAPI routers/v2_weather.py
    → ForecastProvider (IMD → WeatherNext → AccuWeather → Open-Meteo)
      → WeatherNextBigQueryAdapter
        1. Try service account JSON from env GOOGLE_APPLICATION_CREDENTIALS_JSON
        2. Try ADC (GOOGLE_APPLICATION_CREDENTIALS file / workload identity)
        3. Try OAuth refresh token (existing)
        4. If all fail → return FallbackReason live_credentials_required
```

No app change needed once backend returns `selected_source=weathernext` — Flutter already parses v2 provenance.

## 3. Backend Implementation Steps

### 3.1 Create service account (one-time, in GCP console)

In `cool-archery-296710`:

1. IAM → Service Accounts → Create `weathergpt-backend`
2. Roles:
   - `BigQuery Job User` (to run jobs)
   - `BigQuery Data Viewer` on dataset `weathernext` (or project-level if dataset not shareable)
   - `Storage Object Viewer` on buckets `weathernext3_spatial`, `weathernext3_statistics_spatial` (for future GCS Zarr)
3. Keys → Create JSON key → download
4. **Do NOT commit JSON to git** — add to Vercel env

### 3.2 Add env vars to Vercel

In Vercel dashboard for `weathergpt-backend`:

- `GOOGLE_APPLICATION_CREDENTIALS_JSON` = entire JSON file content (stringified)
- Keep existing: `GOOGLE_OAUTH_CLIENT_ID`, `CLIENT_SECRET`, `REFRESH_TOKEN` as fallback
- `GOOGLE_CLOUD_PROJECT=cool-archery-296710`
- `GOOGLE_CLOUD_QUOTA_PROJECT=cool-archery-296710`
- `WEATHERNEXT_TABLE=cool-archery-296710.weathernext.weathernext_3_0_0_0p1deg` (and `...0p05deg`)
- `WEATHERNEXT_ENABLED=1`

### 3.3 Code changes in `omsenjalia/weathergpt/backend`

**File: `backend/services/weathernext_auth.py` (new)**

```python
import json, os
from typing import Optional
from google.oauth2 import service_account
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request

def get_bigquery_credentials() -> Optional[object]:
    # 1. Service account JSON from env (best for Vercel)
    sa_json = os.getenv("GOOGLE_APPLICATION_CREDENTIALS_JSON")
    if sa_json:
        try:
            info = json.loads(sa_json)
            creds = service_account.Credentials.from_service_account_info(
                info,
                scopes=["https://www.googleapis.com/auth/bigquery"]
            )
            return creds
        except Exception as e:
            print(f"[weathernext_auth] SA JSON failed: {e}")

    # 2. ADC file path (Cloud Run / local)
    adc_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    if adc_path and os.path.exists(adc_path):
        try:
            creds = service_account.Credentials.from_service_account_file(
                adc_path,
                scopes=["https://www.googleapis.com/auth/bigquery"]
            )
            return creds
        except Exception as e:
            print(f"[weathernext_auth] ADC file failed: {e}")

    # 3. OAuth refresh token (existing)
    client_id = os.getenv("GOOGLE_OAUTH_CLIENT_ID")
    client_secret = os.getenv("GOOGLE_OAUTH_CLIENT_SECRET")
    refresh_token = os.getenv("GOOGLE_OAUTH_REFRESH_TOKEN")
    if client_id and client_secret and refresh_token:
        try:
            creds = Credentials(
                token=None,
                refresh_token=refresh_token,
                token_uri="https://oauth2.googleapis.com/token",
                client_id=client_id,
                client_secret=client_secret,
                scopes=["https://www.googleapis.com/auth/bigquery"]
            )
            creds.refresh(Request())
            return creds
        except Exception as e:
            print(f"[weathernext_auth] OAuth refresh failed: {e}")

    return None
```

**File: `backend/services/weathernext_bigquery.py`**

Update `get_client()`:

```python
from google.cloud import bigquery
from .weathernext_auth import get_bigquery_credentials

def get_client():
    creds = get_bigquery_credentials()
    if not creds:
        raise RuntimeError("live_credentials_required")
    project = os.getenv("GOOGLE_CLOUD_PROJECT") or os.getenv("GOOGLE_CLOUD_QUOTA_PROJECT") or "cool-archery-296710"
    return bigquery.Client(credentials=creds, project=project)
```

Add `maximum_bytes_billed` and partition filter:

```python
def query_point(lat, lon, init_time, table):
    client = get_client()
    job_config = bigquery.QueryJobConfig(
        maximum_bytes_billed=1_000_000_000,  # 1 GiB hard cap per SIH requirement
        query_parameters=[
            bigquery.ScalarQueryParameter("lat", "FLOAT64", lat),
            bigquery.ScalarQueryParameter("lon", "FLOAT64", lon),
        ]
    )
    sql = f"""
    SELECT t.forecast
    FROM `{table}` t
    WHERE t.init_time = TIMESTAMP(@init_time)
      AND ST_DWITHIN(t.geography, ST_GEOGPOINT(@lon, @lat), 10000)
    LIMIT 1
    """
    # Always filter by init_time to avoid full scan
```

**File: `backend/routers/v2_weather.py`**

Ensure fallback reason includes table:

```python
try:
    data = await weathernext_adapter.fetch(lat, lon, init_time)
    provenance["selected_source"] = "weathernext"
except Exception as e:
    reason = "live_credentials_required" if "live_credentials_required" in str(e) else "unavailable"
    provenance["fallback_reasons"].append({
        "provider": "weathernext",
        "reason": reason,
        "surface": "bigquery",
        "table": os.getenv("WEATHERNEXT_TABLE")
    })
    # try next provider
```

**File: `backend/main.py` — CORS already fixed in PR #17, verify:**

```python
from fastapi.middleware.cors import CORSMiddleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### 3.4 Vercel config

`vercel.json`:

```json
{
  "functions": {
    "api/index.py": {
      "maxDuration": 60
    }
  }
}
```

Already set per PR #9, keep.

### 3.5 Testing

Local:

```bash
cd backend
pip install google-cloud-bigquery google-auth
GOOGLE_APPLICATION_CREDENTIALS_JSON='{"type":"service_account",...}' \
GOOGLE_CLOUD_PROJECT=cool-archery-296710 \
python -m pytest tests/test_weathernext_bigquery.py -v

# Manual
python -c "from services.weathernext_bigquery import query_point; print(query_point(22.56, 72.95, '2026-09-19 00:00:00 UTC', 'cool-archery-296710.weathernext.weathernext_3_0_0_0p1deg'))"
```

Deployed:

```bash
curl https://weathergpt-backend.vercel.app/v2/weather/health | jq .provider_health.weathernext
# expect: configured true, eligible true, reason null

curl "https://weathergpt-backend.vercel.app/v2/weather?lat=22.56&lon=72.95&requested_source=weathernext" | jq .provenance
# expect: selected_source weathernext, no fallback containing weathernext

curl "https://weathergpt-backend.vercel.app/v2/weather/series?lat=22.56&lon=72.95&variable=temperature_2m&requested_source=weathernext" | jq .
# expect: points array, not unavailable
```

## 4. Flutter App Already Ready

App branch `arena/01a0b8b7-weathergpt-app` now:

- Calls `/v2/weather` primary, `requested_source=weathernext` for researcher
- Parses `selected_source`, `fallbackReasons`
- Shows blue WeatherNext badge when live, yellow warning when `live_credentials_required`
- No diagnostic screen (per your request)

Once backend fix deployed, app auto-shows WeatherNext without code change.

## 5. Cost Control for SIH (billing untrusted issue)

You said Google says untrusted account when enabling billing. For SIH:

- Use personal Gmail + credit card, not college email + debit
- Use college GCP education credits if available
- Set budget alert $5, cap per query 1 GiB
- For demo, 2 runs/day (00Z,12Z) = ~510 GiB/month fits in 1TB free tier
- If billing still blocked, use GCS Zarr path: `gs://weathernext3_spatial/` public Zarr can be read with `xarray` + `obstore` without BigQuery billing (only small egress). Show Colab notebook as SIH evidence.

## 6. Done Criteria

- [ ] Service account created, Vercel env set, not committed to git
- [ ] `get_bigquery_credentials()` tries SA → ADC → OAuth
- [ ] `/v2/weather/health` → weathernext eligible true, reason null
- [ ] `/v2/weather?requested_source=weathernext` → selected_source weathernext
- [ ] Flutter app shows WeatherNext badge, p10-p90 spread, next-24h precip when available
- [ ] `flutter test` + `flutter analyze` pass
- [ ] No secrets in Flutter `.env`

## 7. Rollback

If BigQuery fails, fallback chain returns Open-Meteo with explicit `fallback_reasons` — app never crashes, shows honest source.

---

**This plan is for `omsenjalia/weathergpt` backend. Apply, deploy Vercel, then test Flutter app.**
