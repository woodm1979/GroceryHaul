# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```sh
mix deps.get          # install dependencies
mix compile           # build
mix test              # run all tests
mix test path/to/test_file.exs:42  # run single test at line
mix format            # format code
mix credo             # lint (if credo is a dep)
mix dialyzer          # type-check (if dialyxir is a dep)
```

## Project

GroceryHaul is an Elixir application (framework TBD). The project is in early scaffolding — no source files exist yet beyond `.gitignore`.

Config secrets live in `config/*.secret.exs` (gitignored).
