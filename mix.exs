defmodule Notify.Mixfile do
  use Mix.Project

  def project do
    [app: :notify,
     version: "0.1.6",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger, :poison, :joken, :kadabra, :httpotion]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:joken, "~> 1.4"}, {:poison, "~> 2.2"}, {:kadabra, "~> 0.2.0"}, {:httpotion, "~> 3.0.2"}]
  end
end
