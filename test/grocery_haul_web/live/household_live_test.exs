defmodule GroceryHaulWeb.HouseholdLiveTest do
  use GroceryHaulWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias GroceryHaul.Accounts
  alias GroceryHaul.Households

  setup do
    # Allow projector processes to use the sandbox connection
    for projector <- [
          GroceryHaul.Accounts.UserProjector,
          GroceryHaul.Households.HouseholdProjector,
          GroceryHaul.Households.HouseholdMembersProjector,
          GroceryHaul.Households.JoinCodeProjector
        ] do
      key =
        {GroceryHaul.Commanded.Application, Commanded.Event.Handler, inspect(projector)}

      case Registry.lookup(GroceryHaul.Commanded.Application.LocalRegistry, key) do
        [{pid, _}] ->
          Ecto.Adapters.SQL.Sandbox.allow(GroceryHaul.Repo, self(), pid)

        [] ->
          :ok
      end
    end

    :ok
  end

  defp register_and_login(conn, email) do
    {:ok, user_id} = Accounts.register_user(email, "password123")
    {:ok, user} = Accounts.authenticate_user(email, "password123")
    token = Accounts.create_user_token(user)
    conn = Phoenix.ConnTest.init_test_session(conn, user_token: token)
    {conn, user_id, user}
  end

  describe "post-login routing" do
    test "user without a household is redirected to create-or-join", %{conn: conn} do
      {conn, _user_id, _user} = register_and_login(conn, "nohousehold@example.com")
      {:error, {:redirect, %{to: to}}} = live(conn, ~p"/dashboard")
      assert to == "/households/new"
    end

    test "user with a household is redirected to household dashboard", %{conn: conn} do
      {conn, user_id, _user} = register_and_login(conn, "hashousehold@example.com")
      {:ok, household_id} = Households.create_household(user_id, "My Family")
      {:error, {:redirect, %{to: to}}} = live(conn, ~p"/dashboard")
      assert to == "/households/#{household_id}"
    end
  end

  describe "create-or-join screen" do
    test "logged-in user without household sees create-or-join page", %{conn: conn} do
      {conn, _user_id, _user} = register_and_login(conn, "joinpage@example.com")
      {:ok, _view, html} = live(conn, ~p"/households/new")
      assert html =~ "Create"
      assert html =~ "Join"
    end

    test "user can create a household and is redirected to household dashboard", %{conn: conn} do
      {conn, _user_id, _user} = register_and_login(conn, "creator@example.com")
      {:ok, view, _html} = live(conn, ~p"/households/new")

      {:error, {:redirect, %{to: to}}} =
        view
        |> form("#create-household-form", household: %{name: "The Smiths"})
        |> render_submit()

      assert String.starts_with?(to, "/households/")
    end

    test "user can join a household with a valid code and is redirected", %{conn: conn} do
      # Creator sets up a household
      creator_id = Ecto.UUID.generate()
      {:ok, household_id} = Households.create_household(creator_id, "Join Me HH")
      %{code: join_code} = Households.get_join_code(household_id)

      # Joiner opens the new page and submits the join form
      {conn, _user_id, _user} = register_and_login(conn, "joiner@example.com")
      {:ok, view, _html} = live(conn, ~p"/households/new")

      {:error, {:redirect, %{to: to}}} =
        view
        |> form("#join-household-form", join: %{code: join_code})
        |> render_submit()

      assert to == "/households/#{household_id}"
    end

    test "entering an invalid join code shows an error", %{conn: conn} do
      {conn, _user_id, _user} = register_and_login(conn, "badjoin@example.com")
      {:ok, view, _html} = live(conn, ~p"/households/new")

      html =
        view
        |> form("#join-household-form", join: %{code: "BADCODE1"})
        |> render_submit()

      assert html =~ "Invalid join code"
    end
  end

  describe "household dashboard" do
    setup %{conn: conn} do
      {conn, user_id, user} = register_and_login(conn, "dashboard@example.com")
      {:ok, household_id} = Households.create_household(user_id, "Dashboard Family")
      %{conn: conn, user: user, user_id: user_id, household_id: household_id}
    end

    test "shows household name", %{conn: conn, household_id: household_id} do
      {:ok, _view, html} = live(conn, ~p"/households/#{household_id}")
      assert html =~ "Dashboard Family"
    end

    test "shows user email and role", %{conn: conn, household_id: household_id, user: user} do
      {:ok, _view, html} = live(conn, ~p"/households/#{household_id}")
      assert html =~ user.email
      assert html =~ "admin"
    end

    test "admin sees join code on dashboard", %{conn: conn, household_id: household_id} do
      {:ok, _view, html} = live(conn, ~p"/households/#{household_id}")
      assert html =~ "Join Code"
    end

    test "admin can regenerate join code", %{conn: conn, household_id: household_id} do
      {:ok, view, html} = live(conn, ~p"/households/#{household_id}")
      old_code = Households.get_join_code(household_id).code
      assert html =~ old_code

      html = view |> element("button[phx-click=\"regenerate_code\"]") |> render_click()

      new_entry = Households.get_join_code(household_id)
      assert new_entry.code != old_code
      assert html =~ new_entry.code
    end
  end
end
