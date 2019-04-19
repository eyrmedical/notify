defmodule Notify do
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
  def push(recipients, notification) when is_list(recipients) do
    for recipient <- recipients, do: push(recipient, notification)
  end

  @doc """
  Send a notification to a single device_id
  """
  def push({:ios, device_tokens}, %Notification{voip: true} = notif) do
    case Enum.find(device_tokens, &(&1.type == "APN")) do
      nil ->
        {:error, "No APN token provided to send iOS voip push notification"}

      %{token: token} ->
        Notify.APN.push(token, notif)
    end
  end

  def push({:ios, device_tokens}, %Notification{} = notif) do
    fcm_device_token = Enum.find(device_tokens, &(&1.type == "FCM"))

    if fcm_device_token != nil do
      push_with_fcm(fcm_device_token.token, notif)
    else
      case Enum.find(device_tokens, &(&1.type == "APN")) do
        nil ->
          {:error, "no APN or FCM token provided"}

        apn_token ->
          Notify.APN.push(apn_token.token, notif)
      end
    end
  end

  def push({:android, [%{token: token}]}, %Notification{} = notif) do
    push_with_fcm(token, notif)
  end

  def push({_platform, _device_id}, _), do: {:error, "Invalid %Notification{}"}

  defp push_with_fcm(token, notif) do
    cond do
      is_fcm?() ->
        parse_fcm(token, notif) |> Notify.FCM.push()

      is_gcm?() ->
        parse(token, notif) |> Notify.GCM.push()

      true ->
        {:error, "Configure either FCM or GCM modules"}
    end
  end

  @spec parse(String.t(), %Notification{}) :: Map.t()
  defp parse(
         device_id,
         %Notification{
           priority: priority,
           title: title,
           message: message,
           data: data,
           sound: sound,
           color: color,
           icon: icon,
           tag: tag
         }
       ) do
    %{
      "to" => device_id,
      "priority" => priority,
      "notification" => %{
        "title" => title,
        "body" => message,
        "sound" => sound,
        "color" => color,
        "icon" => icon,
        "tag" => tag
      },
      "data" => data
    }
  end

  @spec parse_fcm(String.t(), %Notification{}) :: Map.t()
  defp parse_fcm(
         device_id,
         %Notification{
           priority: priority,
           title: title,
           message: message,
           data: data,
           sound: sound,
           color: color,
           icon: icon,
           tag: tag
         }
       ) do
    data =
      Map.put(data, "notification", %{
        "title" => title,
        "body" => message,
        "sound" => sound,
        "color" => color,
        "icon" => icon,
        "tag" => tag
      })

    %{
      "to" => device_id,
      "priority" => priority,
      "data" => data
    }
  end

  defp is_fcm? do
    Application.get_env(:notify, Notify.FCM) != nil
  end

  defp is_gcm? do
    Application.get_env(:notify, Notify.GCM) != nil
  end
end
