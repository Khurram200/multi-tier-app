# Run the application locally (without Docker)

Use this guide for **Task 3** of Setup and Initial Exploration: understand each component before containerization.

## Prerequisites

- **Node.js** 18+ (you have v22+)
- **npm**
- **PostgreSQL** installed and running on port `5432`

## 1. Database

Create the database (if needed):

```sql
CREATE DATABASE todo;
```

Load schema and sample data from the project root:

```powershell
psql -U postgres -d todo -f db/init.sql
```

## 2. Backend API

```powershell
cd backend
copy .env.example .env
# Edit .env — set DB_PASSWORD to match your local Postgres user
npm install
npm start
```

Verify: http://localhost:5000/api/todos should return JSON (seed todos).

## 3. Frontend

In a **second** terminal:

```powershell
cd web
npm install
npm start
```

Browser: http://localhost:3000

The UI calls `http://localhost:5000/api/todos` by default (`web/src/App.js`).

## Architecture (three processes)

| Layer | Technology | Port |
|-------|------------|------|
| UI | React (Create React App) | 3000 |
| API | Node.js + Express | 5000 |
| Data | PostgreSQL | 5432 |

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `ECONNREFUSED` on API | Start Postgres; check `DB_HOST`, `DB_PORT`, password in `.env` |
| Empty or error on `/api/todos` | Run `db/init.sql`; confirm database name `todo` |
| UI loads but no todos | Ensure backend is running; check browser Network tab for failed requests to port 5000 |
| Port 5000 in use (Windows) | Stop other app or change `PORT` in `.env` and update `REACT_APP_API_URL` in web |

Document results in `docs/TECHNICAL_LOGBOOK.md` Entry 1.
