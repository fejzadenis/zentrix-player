# Zentrix license API (example)

Node.js + Express + JSON file store. Replace `devices.json` with PostgreSQL for production.

## Run locally

```bash
cd server
npm install
set JWT_SECRET=your-long-random-secret
npm start
```

Default: `http://localhost:4000`

## Flutter configuration

Build or run with:

```bash
flutter run --dart-define=LICENSE_API_BASE_URL=http://10.0.2.2:4000
```

Use your machine’s LAN IP instead of `10.0.2.2` on a physical Android device. Optional:

```bash
--dart-define=LICENSE_APP_SECRET=shared-with-server
```

Set the same value in `APP_SECRET` on the server.

## API examples

### POST `/register-device`

Creates a device row with `trial` and 3-day `trial_end` if new.

**Request**

```json
{
  "device_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response**

```json
{
  "token": "<jwt>",
  "device_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "trial",
  "trial_start": "2026-04-08T12:00:00.000Z",
  "trial_end": "2026-04-11T12:00:00.000Z",
  "expiration_date": null
}
```

### POST `/check-license`

**Headers:** `Authorization: Bearer <jwt>`

**Request**

```json
{
  "device_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response**

```json
{
  "status": "trial",
  "trial_start": "2026-04-08T12:00:00.000Z",
  "trial_end": "2026-04-11T12:00:00.000Z",
  "expiration_date": null,
  "server_time": "2026-04-08T12:30:00.000Z"
}
```

### POST `/activate-device`

**Headers:** `Authorization: Bearer <jwt>`

**Request**

```json
{
  "device_id": "550e8400-e29b-41d4-a716-446655440000",
  "activation_code": "ZTX-DEMO12345"
}
```

Valid codes: `ACTIVATION_MASTER_KEY` env, or pattern `ZTX-` + alphanumeric (8+ chars).

**Response**

```json
{
  "status": "active",
  "trial_start": "2026-04-08T12:00:00.000Z",
  "trial_end": "2026-04-11T12:00:00.000Z",
  "expiration_date": "2027-04-08T12:00:00.000Z",
  "server_time": "2026-04-08T12:30:00.000Z"
}
```

## Production notes

- HTTPS only; pin certificates in the app for high-risk deployments.
- Rate-limit `/register-device` and `/check-license` per IP and per `device_id`.
- Store devices in a real DB; add unique index on `device_id`.
- Rotate JWT signing keys; use short-lived access tokens + refresh if needed.
- Never trust client-side license flags; always validate on the server.
