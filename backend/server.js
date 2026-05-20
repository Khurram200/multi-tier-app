require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const client = require('prom-client');

const app = express();
app.use(express.json());
app.use(cors({ origin: process.env.ALLOWED_ORIGIN || '*' }));

const register = new client.Registry();
client.collectDefaultMetrics({ register });

const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register],
});

app.use((req, res, next) => {
  res.on('finish', () => {
    const route = req.route?.path || req.path;
    httpRequestsTotal.inc({
      method: req.method,
      route,
      status_code: String(res.statusCode),
    });
  });
  next();
});

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

app.get('/metrics', async (_req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

app.get('/health', async (_req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', database: 'connected' });
  } catch (err) {
    res.status(503).json({ status: 'error', database: 'disconnected' });
  }
});

app.get('/api/todos', async (req, res) => {
  const result = await pool.query('SELECT * FROM todos ORDER BY id ASC');
  res.json(result.rows);
});

const notifyOpenFaaS = (title) => {
  const url = process.env.OPENFAAS_TODO_NOTIFY_URL;
  if (!url) return;
  fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ title }),
  }).catch((err) => console.warn('OpenFaaS notify failed:', err.message));
};

app.post('/api/todos', async (req, res) => {
  const { title } = req.body;
  const result = await pool.query(
    'INSERT INTO todos (title) VALUES ($1) RETURNING *',
    [title]
  );
  notifyOpenFaaS(title);
  res.status(201).json(result.rows[0]);
});

app.put('/api/todos/:id', async (req, res) => {
  const { id } = req.params;
  const { title, completed } = req.body;
  const result = await pool.query(
    'UPDATE todos SET title = $1, completed = $2 WHERE id = $3 RETURNING *',
    [title, completed, id]
  );
  res.json(result.rows[0]);
});

app.delete('/api/todos/:id', async (req, res) => {
  const { id } = req.params;
  await pool.query('DELETE FROM todos WHERE id = $1', [id]);
  res.sendStatus(204);
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Backend running on port ${PORT}`));
