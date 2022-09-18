import Config

config :logger,
  compile_time_purge_level: :info

config :notify,
  production: Mix.env() == :prod || :false

if File.exists?("config/secret.exs") do
  import_config "secret.exs"
end
