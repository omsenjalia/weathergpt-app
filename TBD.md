# TBD: IMD access from production

Production (Vercel) can't use IMD yet. The gateway rejects the server with `403 IP address 54.87.174.2 not authorized`. Until that's fixed, the backend skips IMD and serves WeatherNext, then Open-Meteo, plus official warnings from NDMA SACHET, so the app keeps working.

**Why:**
- IMD binds each API key to one caller IP. Vercel's serverless functions have no fixed outgoing IP (it changes between requests).
- `216.198.79.3` is Vercel's *incoming* address, so it doesn't apply.
- A key registered for `0.0.0.0` is treated literally, not as "any IP". It was rejected from another IP in testing on 2026-09-28.

**Fix: an IMD relay on the DanBot server** (`dono-03.danbot.host:43321`, resolves to `82.38.134.56`).

Done in code (backend branch `feat/imd-relay`):
- `backend/relay/imd_relay.py`: a relay that uses only the Python standard library. It holds `IMD_API_KEY`/`IMD_EMAIL`/`IMD_PASSWORD`, mints and renews JWTs, forwards only `GET /api/v1/<endpoint>` to `api.imd.gov.in`, and answers only requests carrying `X-Relay-Token`. `GET /healthz` needs no secret.
- Backend relay mode: with `IMD_RELAY_TOKEN` set, the backend sends only that secret to `IMD_BASE_URL`. No IMD credentials live on Vercel. `IMD_TOKEN_URL` isn't needed.
- Tests: `backend/tests/test_imd_relay.py`.

Still to do (needs server/portal access):
1. In the DanBot server console, run `curl https://api.ipify.org` to confirm the outgoing IP. Register that IP with IMD and create an API key for it.
2. Upload `imd_relay.py` to the server, plus a `.env` next to it:
   ```
   IMD_API_KEY=<key for the server IP>
   IMD_EMAIL=...
   IMD_PASSWORD=...
   IMD_RELAY_TOKEN=<32+ random characters>
   PORT=43321
   ```
   Set the startup command to `python imd_relay.py`. Check `http://dono-03.danbot.host:43321/healthz` returns `{"ok": true}`.
3. On Vercel: set `IMD_BASE_URL=http://dono-03.danbot.host:43321/api/v1` and `IMD_RELAY_TOKEN` (same secret). Remove `IMD_API_KEY`, `IMD_EMAIL`, `IMD_PASSWORD` and the expired `IMD_JWT_TOKEN`. Redeploy.
4. Verify with `GET /dev/imd/probe` (header `X-Admin-Token`). All 21 endpoints should answer.

**Caveats:**
- Traffic between Vercel and the relay is plain HTTP, so the shared secret travels unencrypted. It only unlocks IMD reads through the relay (IMD credentials never leave the server). Rotate it if it leaks; put the relay behind HTTPS if the host allows.
- Free panel hosts can restart or move servers, which can change the IP. If that happens, IMD drops out and the fallback chain takes over automatically.

Other options, if the relay isn't wanted: Vercel's static-IP add-on (paid plans), or hosting the backend somewhere with a fixed outgoing IP.
