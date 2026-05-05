defmodule Mix.Tasks.Dev.DbStartup do
  @shortdoc "Opens Docker Desktop and starts the dev database via docker compose"
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.shell().info("Starting Docker and database...")
    System.cmd("open", ["docker"])
    System.cmd("docker", ["compose", "up", "-d"])
    Mix.shell().info("Database started.")
  end
end
