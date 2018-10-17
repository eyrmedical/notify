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
	@gcm Application.get_env(:notify, Notify.GCM) != nil
	@fcm Application.get_env(:notify, Notify.FCM) != nil

	if @gcm and @fcm do
		raise """
		Found configurations for both Firebase (FCM) and Google Cloud Messaging (GCM). Remove one of the configurations.
		"""
	end

	@doc """
	Send a notification to list of device_ids
	"""
	def push(recipients, notification) when is_list(recipients) do
		for recipient <- recipients, do: push(recipient, notification)
	end

	@doc """
	Send a notification to a single device_id
	"""
	def push({:ios, device}, %Notification{} = notif), do: Notify.APN.push(device, notif)
	def push({:android, device}, %Notification{} = notif) when @fcm, do: parse(device, notif) |> Notify.FCM.push()
	def push({:android, device}, %Notification{} = notif) when @gcm, do: parse(device, notif) |> Notify.GCM.push()
	def push({_platform, _device_id}, _), do: {:error, "Invalid %Notification{}"}

	@spec parse(String.t(), %Notification{}) :: Map.t()
	defp parse(device_id,
		%Notification{
			priority: priority,
			title: title,
			message: message,
			data: data,
			sound: sound,
			color: color,
			icon: icon,
			tag: tag
		})
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
end
