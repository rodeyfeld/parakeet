defmodule Parakeet.Repo do
  use Ecto.Repo,
    otp_app: :parakeet,
    adapter: Ecto.Adapters.Postgres
end
