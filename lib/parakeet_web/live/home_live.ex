defmodule ParakeetWeb.HomeLive do
  use ParakeetWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{"name" => ""}))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex flex-col items-center justify-center min-h-[60vh] space-y-10">
        <div class="text-center space-y-3">
          <h1 class="text-5xl font-black tracking-tight bg-gradient-to-r from-amber-300 via-orange-400 to-red-400 bg-clip-text text-transparent">
            Egyptian Rats Crew
          </h1>
        </div>

        <.form
          for={@form}
          phx-submit="enter"
          id="name-form"
          class="w-full max-w-sm space-y-5"
        >
          <.input
            field={@form[:name]}
            type="text"
            placeholder="What's your name?"
            required
            autofocus
            class="text-center text-lg rounded-xl border-zinc-600 bg-zinc-800/80 px-4 py-3 w-full focus:outline-none focus:ring-2 focus:ring-amber-500/50 focus:border-amber-500/60 placeholder:text-zinc-500"
          />
          <button
            type="submit"
            class="w-full rounded-xl bg-gradient-to-r from-amber-600 to-orange-600 hover:from-amber-500 hover:to-orange-500 text-white px-6 py-3 text-lg font-bold transition-all hover:scale-[1.02] active:scale-95 shadow-lg shadow-amber-900/30"
          >
            Play
          </button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("enter", %{"name" => name}, socket) do
    name = String.trim(name)

    if name == "" do
      {:noreply, put_flash(socket, :error, "Enter a name to play")}
    else
      {:noreply, push_navigate(socket, to: ~p"/den?name=#{name}")}
    end
  end
end
