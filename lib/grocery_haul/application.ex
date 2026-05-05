defmodule GroceryHaul.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GroceryHaulWeb.Telemetry,
      GroceryHaul.Repo,
      GroceryHaul.Commanded.Application,
      GroceryHaul.Accounts.UserProjector,
      GroceryHaul.Households.HouseholdProjector,
      GroceryHaul.Households.HouseholdMembersProjector,
      GroceryHaul.Households.JoinCodeProjector,
      {DNSCluster, query: Application.get_env(:grocery_haul, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GroceryHaul.PubSub},
      GroceryHaulWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: GroceryHaul.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    GroceryHaulWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
