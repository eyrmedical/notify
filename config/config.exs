use Mix.Config

config :logger,
  compile_time_purge_level: :info

config :notify,
  production: Mix.env() == :prod || :false

import_config "secret.exs"
