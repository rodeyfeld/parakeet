defmodule ParakeetWeb.DenLiveTest do
  use ParakeetWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  defp enter_den(conn, name) do
    conn = post(conn, ~p"/session", %{"name" => name})
    assert redirected_to(conn) == "/den"
    {:ok, view, _html} = conn |> recycle() |> get("/den") |> live()
    {view, conn}
  end

  describe "create and leave table" do
    test "table disappears after leaving", %{conn: conn} do
      {view, _conn} = enter_den(conn, "Alice")

      view |> form("#create-table-form", %{table_name: "Room A"}) |> render_submit()
      assert render(view) =~ "Room A"
      assert render(view) =~ "Alice"
      assert has_element?(view, "#leave-table-btn")

      view |> element("#leave-table-btn") |> render_click()
      html = render(view)
      refute html =~ "Room A"
    end

    test "table not in open tables after leaving", %{conn: conn} do
      {view, _conn} = enter_den(conn, "Bob")

      view |> form("#create-table-form", %{table_name: "Vanishing Room"}) |> render_submit()
      assert render(view) =~ "Vanishing Room"

      view |> element("#leave-table-btn") |> render_click()

      tables = Parakeet.Den.PitBoss.list_tables()
      refute Enum.any?(tables, fn t -> t.name == "Vanishing Room" end)
    end
  end

  describe "navigate away from pre-game table" do
    test "table shuts down when sole player disconnects", %{conn: conn} do
      {view, _conn} = enter_den(conn, "Solo")

      view |> form("#create-table-form", %{table_name: "Ghost Room"}) |> render_submit()
      assert render(view) =~ "Ghost Room"

      GenServer.stop(view.pid, :normal)
      Process.sleep(500)

      tables = Parakeet.Den.PitBoss.list_tables()
      refute Enum.any?(tables, fn t -> t.name == "Ghost Room" end)
    end
  end

  describe "change name via session controller" do
    test "delete session leaves table", %{conn: conn} do
      {_view, conn} = enter_den(conn, "OldName")

      conn = conn |> recycle() |> delete(~p"/session")
      assert redirected_to(conn) == "/"

      Process.sleep(500)

      tables = Parakeet.Den.PitBoss.list_tables()

      refute Enum.any?(tables, fn t ->
               "OldName" in t.player_names
             end)
    end
  end
end
