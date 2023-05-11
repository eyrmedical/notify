import Config

config :notify,
  production: Mix.env() == :prod || :false

if File.exists?("config/secret.exs") do
  import_config "secret.exs"
end
