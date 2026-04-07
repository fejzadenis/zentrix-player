/**
 * Example Zentrix license API (Express).
 *
 * Production: replace JSON file with PostgreSQL/MySQL, add rate limiting,
 * WAF, structured logging, and rotate JWT_SECRET.
 *
 * Env:
 *   PORT=4000
 *   JWT_SECRET=change-me-in-production
 *   APP_SECRET=optional-shared-secret-for-X-App-Secret-header
 *   ACTIVATION_MASTER_KEY=optional-master-code-to-activate-any-device
 */

const fs = require('fs');
const path = require('path');
const cors = require('cors');
const express = require('express');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

const PORT = process.env.PORT || 4000;
const JWT_SECRET = process.env.JWT_SECRET || 'dev-only-change-me';
const APP_SECRET = process.env.APP_SECRET || '';
const ACTIVATION_MASTER_KEY = process.env.ACTIVATION_MASTER_KEY || '';

const DATA_PATH = path.join(__dirname, 'devices.json');

function loadDb() {
  try {
    const raw = fs.readFileSync(DATA_PATH, 'utf8');
    return JSON.parse(raw);
  } catch {
    return { devices: {} };
  }
}

function saveDb(db) {
  fs.writeFileSync(DATA_PATH, JSON.stringify(db, null, 2), 'utf8');
}

function trialDays() {
  return 3;
}

function requireAppSecret(req, res, next) {
  if (!APP_SECRET) return next();
  const h = req.headers['x-app-secret'];
  if (h !== APP_SECRET) {
    return res.status(401).json({ error: 'invalid_app_secret' });
  }
  next();
}

function signToken(deviceId) {
  return jwt.sign({ sub: deviceId, typ: 'device' }, JWT_SECRET, {
    expiresIn: '365d',
  });
}

function verifyToken(token) {
  return jwt.verify(token, JWT_SECRET);
}

const app = express();
app.use(cors());
app.use(express.json());
app.use(requireAppSecret);

app.post('/register-device', (req, res) => {
  const deviceId = req.body.device_id;
  if (!deviceId || typeof deviceId !== 'string') {
    return res.status(400).json({ error: 'device_id_required' });
  }

  const db = loadDb();
  let row = db.devices[deviceId];

  if (!row) {
    const now = new Date();
    const trialEnd = new Date(now.getTime() + trialDays() * 86400000);
    row = {
      device_id: deviceId,
      status: 'trial',
      trial_start: now.toISOString(),
      trial_end: trialEnd.toISOString(),
      expiration_date: null,
      created_at: now.toISOString(),
    };
    db.devices[deviceId] = row;
    saveDb(db);
  }

  const token = signToken(deviceId);

  return res.json({
    token,
    device_id: deviceId,
    status: row.status,
    trial_start: row.trial_start,
    trial_end: row.trial_end,
    expiration_date: row.expiration_date,
  });
});

app.post('/check-license', (req, res) => {
  const auth = req.headers.authorization || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
  if (!token) {
    return res.status(401).json({ error: 'missing_token' });
  }

  let payload;
  try {
    payload = verifyToken(token);
  } catch {
    return res.status(401).json({ error: 'invalid_token' });
  }

  const deviceId = req.body.device_id;
  if (!deviceId || payload.sub !== deviceId) {
    return res.status(403).json({ error: 'device_mismatch' });
  }

  const db = loadDb();
  const row = db.devices[deviceId];
  if (!row) {
    return res.status(404).json({ error: 'unknown_device' });
  }

  const now = new Date();
  let status = row.status;

  if (status === 'trial' && row.trial_end && new Date(row.trial_end) < now) {
    status = 'expired';
    row.status = 'expired';
    saveDb(db);
  }

  if (status === 'active' && row.expiration_date && new Date(row.expiration_date) < now) {
    status = 'expired';
    row.status = 'expired';
    saveDb(db);
  }

  return res.json({
    status,
    trial_start: row.trial_start,
    trial_end: row.trial_end,
    expiration_date: row.expiration_date,
    server_time: now.toISOString(),
  });
});

app.post('/activate-device', (req, res) => {
  const auth = req.headers.authorization || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
  if (!token) {
    return res.status(401).json({ error: 'missing_token' });
  }

  let payload;
  try {
    payload = verifyToken(token);
  } catch {
    return res.status(401).json({ error: 'invalid_token' });
  }

  const deviceId = req.body.device_id;
  const code = (req.body.activation_code || '').trim();
  if (!deviceId || payload.sub !== deviceId) {
    return res.status(403).json({ error: 'device_mismatch' });
  }
  if (!code) {
    return res.status(400).json({ error: 'activation_code_required' });
  }

  const valid =
    (ACTIVATION_MASTER_KEY && code === ACTIVATION_MASTER_KEY) ||
    /^ZTX-[A-Z0-9]{8,}$/.test(code);

  if (!valid) {
    return res.status(400).json({ error: 'invalid_activation_code' });
  }

  const db = loadDb();
  let row = db.devices[deviceId];
  if (!row) {
    return res.status(404).json({ error: 'unknown_device' });
  }

  const exp = new Date();
  exp.setFullYear(exp.getFullYear() + 1);

  row.status = 'active';
  row.expiration_date = exp.toISOString();
  db.devices[deviceId] = row;
  saveDb(db);

  return res.json({
    status: 'active',
    trial_start: row.trial_start,
    trial_end: row.trial_end,
    expiration_date: row.expiration_date,
    server_time: new Date().toISOString(),
  });
});

app.get('/health', (_, res) => res.json({ ok: true }));

app.listen(PORT, () => {
  console.log(`Zentrix license API listening on http://localhost:${PORT}`);
});
