# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```sh
mix deps.get          # install dependencies
mix compile           # build
mix test              # run all tests
mix test path/to/test_file.exs:42  # run single test at line
mix format            # format code
mix credo             # lint
mix dialyzer          # type-check (slow on first run)
mix dev.db_startup    # open Docker Desktop and start the dev database via docker compose
```

## Database troubleshooting

If tests fail with database connection errors (e.g. `DBConnection.ConnectionError`, `Postgrex.Error`, "connection refused", or event store connection failures), run `mix dev.db_startup` to open Docker Desktop and start the database before retrying.

## Setup after cloning

After cloning, run `lefthook install` once to activate the git pre-commit hooks (requires `brew install lefthook` if not already installed).

## Project

GroceryHaul is an Elixir application (framework TBD). The project is in early scaffolding — no source files exist yet beyond `.gitignore`.

Config secrets live in `config/*.secret.exs` (gitignored).

## GitHub Actions secrets

Add `FLY_API_TOKEN` as a repository secret in GitHub (Settings → Secrets and variables → Actions) before the deploy job can run. Generate the token with `fly tokens create deploy`.
