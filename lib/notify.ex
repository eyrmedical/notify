defmodule Notify do
  require Logger
  require Kadabra
  @moduledoc """
  A module for generating push notifications and dispatch them to either the
  Firebase Cloud Messaging (Android) or Apple Push Notification service (iOS).

  ## Configuration
    config :notify,
      bundle_id: "com.example.app",
      key_id: "APNS_AUTH_KEY_ID",
      team_id: "APPLE_DEVELOPER_TEAM_ID",
      key_path: "/path/to/APNsAuthKey_<APNS_AUTH_KEY_ID>.p8",
      project_id: "firebase-project-id",
      server_key: "FIREBASE_SERVER_KEY",
      color: "#FF6677", # (Android notification color)
      sound: "sound", # (Notification sound)
  """

  @doc """
  Send a notification to list of device_ids
  """
  def push(device_ids, notification) when is_list(device_ids) do
    for id <- device_ids, do: push(id, notification)
  end

  @doc """
  Send a notification to a single device_id
  """
  def push({ platform, device_id }, %Notification{} = notification) do
    case platform do
      :ios -> parse(:ios, notification) |> Notify.APNS.push(device_id)
      :android -> parse(:android, notification, device_id) |> Notify.FCM.push()
      invalid_platform -> Logger.warn "Invalid platform: #{platform}"
    end
  end
  def push({ platform, device_id}, _), do: {:error, "Invalid %Notification{}"}

  @spec parse(:ios, %Notification{}) :: Map.t()
  defp parse(:ios, %Notification{
    priority: priority,
    title: title,
    message: message,
    data: data,
    sound: sound,
    expiration: expiration
  }) do

    # Change "high" or "normal" to corresponding numeric values for APNS. Defaults to "high" / 10.
    if priority == "normal" do
      priority = 5
    else
      priority = 10
    end

    notification = %{
      "alert" => %{
        "title" => title,
        "body" => message,
      },
      "sound" => sound,
      "content-available" => "1"
    }

    unless Map.keys(data) == [] do
      notification = Map.put(notification, "payload", data)
    end
    %{
      "expiration" => expiration,
      "priority" =>  priority,
      "notification"=> notification
    }
  end

  @spec parse(:android, %Notification{}, String.t()) :: Map.t()
  defp parse(:android,
    %Notification{
      priority: priority,
      title: title,
      message: message,
      data: data,
      sound: sound,
      color: color,
      icon: icon,
      tag: tag
    }, device_id)
  do
    %{
      "to" => device_id,
      "priority" => priority,
      "notification" => %{
        "title" => title,
        "body" => message,
        "sound" => sound,
        "color" => color,
        "icon" => icon,
        "tag" => tag,
      },
      "data" => data
    }
  end

  @spec timestamp() :: number()
  defp timestamp(), do: DateTime.utc_now() |> DateTime.to_unix()
end
