defmodule GroceryHaulWeb.PageController do
  use GroceryHaulWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
