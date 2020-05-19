defmodule Grabber.Repo do
  use Ecto.Repo,
    otp_app: :grabber,
    adapter: Ecto.Adapters.Postgres
end
