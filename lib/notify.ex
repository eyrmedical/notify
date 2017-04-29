defmodule Notify do
  import Poison
  @moduledoc """
  A module for generating push notifications on the Apple Push Notification Service using HTTP2 requests and the new .p8 key standard. This module will generate JWT tokens from the .p8 key and use them to push notifications to device IDs.

  ## Configuration
    config :notify,
      bundle_id: "your.app.bundle.id",
      key_id: "APPLEKEYID",
      team_id: "APPLETEAMID",
      key: "/full/path/to/key/APNsAuthKey_APPLEKEYID.p8"
  """
  @key Application.get_env(:notify, :key) |> File.read!
  @key_id Application.get_env(:notify, :key_id)
  @team_id Application.get_env(:notify, :team_id)


  unless Application.get_all_env(:notify) do
    raise "Notify is not configured"
  end

  unless @key do
    raise "Could not read key file"
  end

  unless String.length(@team_id) == 10 do
    raise ":team_id must be 10 characters"
  end

  @doc """
  Creates a JWT token
  """
  def create_token() do
    {_alg, token} = JOSE.JWK.from_pem(@key)
    |> JOSE.JWT.sign(
      %{ "alg" => "ES256" },
      %{ "iss" => @team_id, "iat" => timestamp() }
    )

    Poison.encode!(token)
    |> IO.inspect
  end

  def push() do
    "push"
  end

  @spec timestamp() :: number()
  defp timestamp(), do: DateTime.utc_now() |> DateTime.to_unix()

end
