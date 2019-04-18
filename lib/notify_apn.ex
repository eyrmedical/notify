defmodule Notify.APN do
  require Logger
  import Joken

  @moduledoc """
  A module for generating push notifications on the Apple Push Notification service using HTTP2 requests and the new .p8 key standard. This module will generate JWT tokens from the .p8 key and use them to push notifications to device IDs.
  """

  @type result :: {atom(), String.t()}

  @doc """
  Push a notification to device
  """
  @spec push(String.t(), Map.t()) :: result
  def push(
        device,
        %Notification{
          data: data,
          sound: sound,
          voip: true
        }
      ) do
    [
      {":authority", get_url() |> to_string()},
      {":method", "POST"},
      {":path", "/3/device/#{device}"},
      {"authorization", "bearer " <> get_token()},
      {"apns-topic", "#{config(:bundle_id)}.voip"},
      {"apns-expiration", "0"},
      {"apns-priority", "10"}
    ]
    |> dispatch(
      %{
        "data" => data,
        "aps" => %{
          "sound" => sound
        }
      },
      device
    )
  end

  @spec push(String.t(), Map.t()) :: result
  def push(
        device,
        %Notification{
          title: title,
          message: message,
          expiration: expiration,
          priority: priority,
          data: data,
          sound: _sound,
          voip: false
        } = notification
      ) do
    priority = if priority == "low", do: "5", else: "10"

    aps_payload =
      %{
        "alert" => %{
          "title" => title,
          "body" => message
        }
      }
      |> maybe_attach_content_available(notification)
      |> maybe_attach_badge(notification)

    [
      {":authority", get_url() |> to_string()},
      {":method", "POST"},
      {":path", "/3/device/#{device}"},
      {"authorization", "bearer " <> get_token()},
      # TODO: remove .voip and find a way to mix regular and voip tokens
      {"apns-topic", "#{config(:bundle_id)}.voip"},
      {"apns-expiration", expiration |> to_string()},
      {"apns-priority", priority}
    ]
    |> dispatch(
      %{
        "data" => data,
        "aps" => aps_payload
      },
      device
    )
  end

  @spec dispatch(List.t(), Map.t(), String.t()) :: result
  defp dispatch(headers, body, device) do
    with {:ok, pid} = Kadabra.open(get_url(), :https) do
      Kadabra.request(pid, headers, Poison.encode!(body))

      receive do
        {:end_stream, %Kadabra.Stream{} = stream} -> reply(stream, device)
      after
        5_000 ->
          reply(:timeout, device)
      end
    end
  end

  @doc """
  Initiates a table to store APNs JWTs
  """
  @spec init_table() :: atom()
  def init_table(), do: :ets.new(:apns_tokens, [:set, :public, :named_table])

  @doc """
  Creates a JWT (valid for one hour after timestamp) and inserts it
  in memory storage
  """
  @spec create_token() :: String.t()
  def create_token() do
    time = timestamp()

    new_token =
      %{"iss" => config(:team_id), "iat" => time}
      |> token
      |> with_header_arg("kid", config(:key_id))
      |> sign(es256(key()))
      |> get_compact()

    :ets.insert(:apns_tokens, {"token", new_token, time + 3000})

    to_string(new_token)
  end

  @doc """
  Gets JWT from memory
  """
  @spec get_token() :: String.t()
  def get_token() do
    case :ets.lookup(:apns_tokens, "token") do
      [{_, stored_token, expires}] -> check_expiration({stored_token, expires})
      _ -> create_token()
    end
  end

  @spec check_expiration({String.t(), Number.t()}) :: String.t()
  defp check_expiration({stored_token, exp}) do
    time = timestamp()

    if exp >= time do
      # Expiration is set to 60 seconds before actual expiration on APNs
      Logger.debug("Stored token is valid for #{exp - time} more seconds")
      stored_token
    else
      Logger.debug("Stored token has been expired for #{time - exp} seconds")
      create_token()
    end
  end

  @spec reply(%Kadabra.Stream{}, String.t()) :: result
  defp reply(%Kadabra.Stream{:status => 200, :headers => headers}, device_id) do
    Logger.info("Notification to #{device_id} succeeded")
    [_, {"apns-id", notification_id}] = headers
    {:ok, notification_id}
  end

  defp reply(%Kadabra.Stream{} = response, device_id) do
    reason =
      response
      |> Map.get(:body, "")
      |> Poison.decode!()
      |> Map.get("reason", "Unexpected status")

    Logger.warn("Notification to #{device_id} failed: #{reason}")
    {:error, reason}
  end

  @spec reply(atom(), String.t()) :: result
  defp reply(:timeout, device_id) do
    Logger.warn("Notification to #{device_id} timed out.")
    {:error, "Request timed out"}
  end

  @spec maybe_attach_content_available(map(), %Notification{}) :: map()
  defp maybe_attach_content_available(payload, %Notification{
         content_available: content_available,
         priority: priority
       })
       when content_available != nil and priority != "low",
       do: Map.put(payload, "content-available", content_available)

  defp maybe_attach_content_available(payload, _), do: payload

  @spec maybe_attach_badge(map(), %Notification{}) :: map()
  defp maybe_attach_badge(payload, %Notification{badge: badge})
       when badge != nil,
       do: Map.put(payload, "badge", badge)

  defp maybe_attach_badge(payload, _), do: payload

  # Kadabra requires a charlist as address
  @spec get_url() :: binary()
  defp get_url() do
    if Application.get_env(:notify, :production) do
      'api.push.apple.com'
    else
      'api.development.push.apple.com'
    end
  end

  @spec timestamp() :: number()
  defp timestamp(), do: DateTime.utc_now() |> DateTime.to_unix()

  @spec key() :: %JOSE.JWK{}
  defp key(), do: JOSE.JWK.from_pem_file(config(:key_path))

  @spec config(atom()) :: Keyword.t()
  defp config(key) do
    :notify
    |> Application.fetch_env!(Notify.APN)
    |> Keyword.fetch!(key)
  end
end
