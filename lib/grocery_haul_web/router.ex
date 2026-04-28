defmodule GroceryHaulWeb.Router do
  use GroceryHaulWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GroceryHaulWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :require_auth do
    plug GroceryHaulWeb.Plugs.RequireAuth
  end

  scope "/", GroceryHaulWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/register", AuthLive.Register, :register
    live "/login", AuthLive.Login, :login
    get "/auth/session", AuthController, :create
    delete "/logout", AuthController, :delete
    get "/logout", AuthController, :delete
  end

  scope "/", GroceryHaulWeb do
    pipe_through [:browser, :require_auth]

    live "/dashboard", DashboardLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", GroceryHaulWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:grocery_haul, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: GroceryHaulWeb.Telemetry
    end
  end
end
