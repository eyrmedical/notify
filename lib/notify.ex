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
	def push(device_ids, notification) when is_list(device_ids) do
		for id <- device_ids, do: push(id, notification)
	end

	@doc """
	Send a notification to a single device_id
	"""
	def push({ platform, device_id }, %Notification{} = notification) do
		case platform do
			:ios ->
				parse(:ios, notification)
                |> Notify.APN.push(device_id)

			:android ->
                parse(:android, notification, device_id)
                |> push_android

			invalid_platform ->
                Logger.warn "Invalid platform: #{platform}"
		end
	end
	def push({ platform, device_id}, _), do: {:error, "Invalid %Notification{}"}

    defp push_android(notification) when @fcm, do: Notify.FCM.push(notification)
    defp push_android(notification) when @gcm, do: Notify.GCM.push(notification)
    defp push_android(_), do: Logger.warn "No Android Cloud Messaging service configured"

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

		%{
			"expiration" => expiration,
			"priority" =>  priority,
			"data" => data,
			"notification"=> %{
				"alert" => %{
					"title" => title,
					"body" => message,
				},
				"sound" => sound,
				"content-available" => "1"
			},
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
