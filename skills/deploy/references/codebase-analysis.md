# Codebase analysis for Seenode deploys

Use this checklist before calling `create_application` or `update_build_settings`. Infer from files in the repo — do not guess blindly. Prefer `inspect_repository` for remote command/env hints, then confirm against the local tree.

## 1. Language and package manager

| Signal | Runtime hint |
|--------|----------------|
| `package.json` + lockfile (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb`) | `node-22` (or match `engines.node`) |
| `requirements.txt`, `pyproject.toml`, `Pipfile`, `poetry.lock` | `python-3.12` (or match declared version) |
| `go.mod` | golang image from `list_images` |
| `mix.exs` | elixir image from `list_images` |
| `Gemfile` | check available images; confirm with `list_images` |
| `Dockerfile` / `docker-compose.yml` | Still deploy via Seenode runtime images unless the platform documents otherwise; use Dockerfile only as a hint for commands/port |

Always call `list_images(image_type="application")` and prefer an explicit tag (`node-22`, `python-3.12`) over a floating major. Runtime ≠ env var.

## 2. Framework → build / run commands

Prefer scripts already in the repo (`package.json` scripts, Makefile, Procfile, README) and hints from `inspect_repository`.

### Node / TypeScript

| Framework signals | Typical build | Typical run |
|-------------------|---------------|-------------|
| Next.js (`next`) | `npm ci && npm run build` | `npm start` (or `npx next start`) |
| Nest / Express / Fastify | `npm ci && npm run build` if `dist/` needed | `npm start` or `node dist/main.js` |
| Vite SPA / static export with no backend | `npm ci && npm run build` | n/a — `application_type='static'` + `publish_directory` |
| Remix / Nuxt / SvelteKit (SSR / Node server) | Use framework start script after build | framework `start` |

Install command must match the lockfile: `npm ci`, `pnpm i --frozen-lockfile`, `yarn install --frozen-lockfile`, or `bun install --frozen-lockfile`.

### Python

| Signals | Build | Run |
|---------|-------|-----|
| Django | `pip install -r requirements.txt` (+ migrate if safe/documented) | `gunicorn ...` or `python manage.py runserver 0.0.0.0:$PORT` adapted to Seenode port |
| FastAPI / Flask | `pip install -r requirements.txt` | `uvicorn app:app --host 0.0.0.0 --port <port>` |
| Poetry | `poetry install --no-dev` (or export requirements) | poetry/uvicorn entrypoint |

### Other

Read README and entrypoints. If unclear, propose options and ask once — do not invent exotic start commands.

## 3. Port

- Web and private apps **require** `port`.
- Prefer the port the process actually listens on (`process.env.PORT`, `listen(3000)`, uvicorn `--port`, etc.).
- Common defaults: `3000`, `8080`, `8000`.
- Workers usually omit `port`.
- Ensure the app binds `0.0.0.0`, not only `127.0.0.1`.

## 4. Root directory (monorepos)

If the deployable app lives under `apps/web`, `services/api`, etc., set `root_directory` and run build/start relative to that directory (Seenode runs commands from the root directory context).

## 5. Environment variables

Scan for:

- `.env.example`, `.env.sample`, `docker-compose` `environment:`
- Framework config (`process.env.*`, `os.environ`, pydantic settings)
- Auth secrets, API keys, `NODE_ENV` / `ENVIRONMENT`

Plan:

- Non-secret defaults can go in `environment_variables` on create.
- Secrets must be listed in `secret_keys` (and never echoed).
- Prefer asking the user for non-DB secret values rather than inventing them.
- For databases, do **not** paste passwords — use `link_database_to_application` after create.

## 6. Database signals

Treat as DB-needed when you see ORMs/drivers or connection URLs:

- Prisma, Drizzle, TypeORM, Sequelize, Knex
- Django/SQLAlchemy/ActiveRecord
- `DATABASE_URL`, `MYSQL_*`, `POSTGRES_*`, `DB_*`
- `psycopg`, `mysql2`, `pg`, `mongodb` (MongoDB is **not** a Seenode managed DB — call out the gap)

Engine choice:

- Clear MySQL / `mysql2` / MariaDB → `database_type="mysql"`
- Otherwise default **`postgresql`** (not `postgres`) unless the user specifies

Create with `create_database`, poll `get_database_state`, then `link_database_to_application`. Never teach dashboard password copy-paste as the primary path.

## 7. Application type

| Need | Type |
|------|------|
| Public HTTP API or website with a server | `web` |
| Vite/SPA/static export, no Node server | `static` (`publish_directory`, optional `client_side_routing`) |
| Queue consumer / sidekiq / bull worker | `worker` |
| Internal-only service | `private` |

## 8. Evidence package before mutate

Before `create_application`, be able to state:

1. Repo + provider + branch
2. `application_type` + port (if any) or `publish_directory` (static)
3. `runtime` or `image_id` (optional for static — build container defaults to Node 22)
4. Exact `build_command` and `run_command` (omit `run_command` for static)
5. `root_directory` if not repo root
6. Env keys to set (names) and which are secrets
7. Whether a managed DB will be created/reused and linked (not password-pasted; skip for static)
