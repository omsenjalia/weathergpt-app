# TBD: IMD access from production

Production (Vercel) can't use IMD yet. The gateway rejects the server with `403 IP address 54.87.174.2 not authorized`. Until that's fixed, the backend skips IMD and serves WeatherNext, then Open-Meteo, plus official warnings from NDMA SACHET, so the app keeps working.

**Why:**
- IMD binds each API key to one caller IP. Vercel's serverless functions have no fixed outgoing IP (it changes between requests).
- `216.198.79.3` is Vercel's *incoming* address, so it doesn't apply.
- A key registered for `0.0.0.0` is treated literally, not as "any IP". It was rejected from another IP in testing on 2026-09-28.

**Plan: a small IMD relay on the DanBot server** (`dono-03.danbot.host:43321`, resolves to `82.38.134.56`):
1. In the server console, run `curl https://api.ipify.org` to confirm the outgoing IP. Register that IP with IMD and create an API key for it.
2. Run a relay on the server port that forwards only to `api.imd.gov.in`.
   - The relay holds `IMD_API_KEY`, `IMD_EMAIL` and `IMD_PASSWORD` and mints/renews JWTs itself.
   - It answers only requests carrying a shared secret.
   - Traffic to that port is plain HTTP, so IMD credentials must not travel from Vercel.
3. Backend changes:
   - Point `IMD_BASE_URL` and `IMD_TOKEN_URL` at the relay (both are already configurable).
   - Add an `IMD_RELAY_TOKEN` header for the shared secret. This is new: a small change in `weathergpt/imd/client.py`.
4. Verify with `GET /dev/imd/probe` (header `X-Admin-Token`). All 21 endpoints should answer.

**Cleanup in the meantime:** remove the expired `IMD_JWT_TOKEN` from Vercel. With `IMD_EMAIL`/`IMD_PASSWORD` set, the backend fetches its own tokens.

**Caveat:** free panel hosts can restart or move servers, which can change the IP. If that happens, IMD drops out and the fallback chain takes over automatically.

Other options, if the relay isn't wanted: Vercel's static-IP add-on (paid plans), or hosting the backend somewhere with a fixed outgoing IP.
