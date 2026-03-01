defmodule ParakeetWeb.GameLive do
  use ParakeetWeb, :live_view

  alias Parakeet.Den.{PitBoss, Table}
  alias Parakeet.Game.{Engine, CardStack}

  import ParakeetWeb.GameComponents

  @impl true
  def mount(%{"code" => code} = params, _session, socket) do
    player_name = params["name"]

    case PitBoss.find_table(code) do
      {:ok, table_pid} ->
        table = Table.get_state(table_pid)

        cond do
          player_name == nil ->
            {:ok, push_navigate(socket, to: ~p"/")}

          table.engine_pid == nil ->
            {:ok,
             socket
             |> put_flash(:error, "Game hasn't started yet")
             |> push_navigate(to: ~p"/den?code=#{code}&name=#{player_name}")}

          true ->
            if connected?(socket), do: Phoenix.PubSub.subscribe(Parakeet.PubSub, "game:#{code}")

            game = Engine.get_state(table.engine_pid)
            player_idx = Enum.find_index(game.players, fn p -> p.name == player_name end)

            {:ok,
             assign(socket,
               code: code,
               table_pid: table_pid,
               engine_pid: table.engine_pid,
               game: game,
               player_name: player_name,
               player_idx: player_idx,
               log: ["Game started!"]
             )}
        end

      :not_found ->
        {:ok,
         socket
         |> put_flash(:error, "Table not found")
         |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-6">
        <div class="flex items-center justify-between">
          <h1 class="text-3xl font-bold tracking-tight">Parakeet</h1>
          <div class="flex items-center gap-3">
            <span class="text-sm text-zinc-400">
              Playing as <span class="font-semibold text-white">{@player_name}</span>
            </span>
            <.link
              navigate={~p"/den?name=#{@player_name}"}
              class="rounded-lg border border-zinc-700 px-4 py-2 text-sm font-medium text-zinc-400 hover:text-white hover:border-zinc-500 transition-all"
            >
              Leave Game
            </.link>
          </div>
        </div>

        <.game_rules />

        <div class="space-y-6">
          <%= if @game.status == :finished do %>
            <.game_over_banner winner={@game.winner} player_name={@player_name} />
          <% else %>
            <.game_controls game={@game} player_idx={@player_idx} />
          <% end %>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <.player_card
              :for={{player, idx} <- Enum.with_index(@game.players)}
              player={player}
              idx={idx}
              current_player_idx={@game.current_player_idx}
              player_idx={@player_idx}
            />
            <.pile game={@game} />
          </div>

          <.game_log log={@log} />
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("play_turn", _params, socket) do
    old_game = socket.assigns.game
    old_player = Enum.at(old_game.players, old_game.current_player_idx)
    {played_card, _} = CardStack.pop_top(old_player.hand)

    game = Engine.play_turn(socket.assigns.engine_pid)

    msgs = ["#{old_player.name} plays #{format_card(played_card)}"]

    msgs =
      if CardStack.count(old_game.pile) > 0 and CardStack.count(game.pile) == 0 do
        collector = Enum.at(game.players, game.current_player_idx)
        msgs ++ ["── New round ── #{collector.name} collects the pile"]
      else
        msgs
      end

    for msg <- msgs, do: broadcast_game_update(socket.assigns.code, game, msg)
    maybe_notify_game_over(socket, game)

    {:noreply, assign(socket, game: game, log: socket.assigns.log ++ msgs)}
  end

  @impl true
  def handle_event("slap", _params, socket) do
    idx = socket.assigns.player_idx
    player = Enum.at(socket.assigns.game.players, idx)
    game = Engine.slap(socket.assigns.engine_pid, idx)

    slapped_player = Enum.at(game.players, idx)
    old_count = CardStack.count(player.hand)
    new_count = CardStack.count(slapped_player.hand)

    msgs =
      if new_count > old_count do
        [
          "#{player.name} slapped! Won the pile! (#{old_count} → #{new_count} cards)",
          "── New round ── #{player.name} starts"
        ]
      else
        ["#{player.name} bad slap! Lost 2 cards (#{old_count} → #{new_count} cards)"]
      end

    for msg <- msgs, do: broadcast_game_update(socket.assigns.code, game, msg)
    maybe_notify_game_over(socket, game)

    {:noreply, assign(socket, game: game, log: socket.assigns.log ++ msgs)}
  end

  @impl true
  def handle_info({:game_update, game, msg}, socket) do
    {:noreply, assign(socket, game: game, log: socket.assigns.log ++ [msg])}
  end

  defp maybe_notify_game_over(socket, game) do
    if game.status == :finished do
      Table.update_game_status(socket.assigns.table_pid, :finished)
    end
  end

  defp broadcast_game_update(code, game, msg) do
    Phoenix.PubSub.broadcast_from(
      Parakeet.PubSub,
      self(),
      "game:#{code}",
      {:game_update, game, msg}
    )
  end
end
