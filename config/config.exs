# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :grabber,
  ecto_repos: [Grabber.Repo]

# Configures the endpoint
config :grabber, GrabberWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "ppumTRCjPatAWtXbPeeJTbD0YiGjoy27GYcXdQp0rmUOla2Oe/xsKij4jjolpGYg",
  render_errors: [view: GrabberWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Grabber.PubSub,
  live_view: [signing_salt: "iUJwT/U8"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
