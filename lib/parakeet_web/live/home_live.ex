defmodule ParakeetWeb.HomeLive do
  use ParakeetWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    name = session["player_name"] || ""
    {:ok, assign(socket, form: to_form(%{"name" => name}))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex flex-col items-center justify-center min-h-[60vh] space-y-10">
        <div class="flex w-full max-w-sm items-start justify-between gap-3">
          <div class="min-w-0 flex-1 text-center sm:text-left">
            <h1 class="text-5xl font-black tracking-tight text-emerald-600 dark:text-emerald-400">
              Parakeet
            </h1>
            <p class="mt-2 text-sm text-zinc-600 dark:text-zinc-400">Choose a name to play</p>
          </div>
          <Layouts.theme_toggle />
        </div>

        <.form
          for={@form}
          action={~p"/session"}
          id="name-form"
          class="w-full max-w-sm space-y-5"
        >
          <.input
            field={@form[:name]}
            type="text"
            placeholder="What's your name?"
            required
            autofocus
            class="text-center text-lg rounded-xl border-zinc-300 bg-white px-4 py-3 w-full text-zinc-900 shadow-sm focus:outline-none focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500/60 placeholder:text-zinc-400 dark:border-zinc-500/60 dark:bg-zinc-700/80 dark:text-zinc-50 dark:placeholder:text-zinc-400"
          />
          <button
            type="submit"
            class="w-full rounded-xl bg-gradient-to-r from-emerald-600 to-green-600 hover:from-emerald-500 hover:to-green-500 text-white px-6 py-3 text-lg font-bold transition-all hover:scale-[1.02] active:scale-95 shadow-lg shadow-emerald-900/20 dark:shadow-emerald-950/40"
          >
            Play
          </button>
        </.form>
      </div>
    </Layouts.app>
    """
  end
end
