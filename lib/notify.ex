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
  		color: "#FF6677", # (Android notification color)
  		sound: "sound", # (Notification sound)
  """

  alias Notify.APN
  alias Notify.Notification

  @doc """
  Send a list of notifications
  """
  def push(notifications) when is_list(notifications) do
    for notification <- notifications, do: push(notification)
  end

  @doc """
  Send a notification
  """
  def push(%Notification{voip: true} = notification) do
    APN.push(notification)
  end
end
