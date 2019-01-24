defmodule Notify.FCM do
	@moduledoc """
	A module for generating push notifications on the Firebase Cloud Messaging platform (from Google) using HTTP requests.

	In case you Missing API key for Firebase Cloud Messaging in configuration. Find it at:
	https://console.firebase.google.com/project/PROJECT_ID/settings/cloudmessaging
	"""

	require Logger

	@url "https://fcm.googleapis.com/fcm/send"
	@type result :: {atom(), String.t()}

	@doc """
	Send a push notification through the Firebase Cloud Messaging service.
	"""
	@spec push(Map.t()) :: result
	def push(%{"to" => device_id} = notification) do
		Logger.info "Pushing notification to #{device_id}"

		server_key = config(:server_key)
		body = Poison.encode!(notification)
		headers = [
			"Content-Type": "application/json",
			"Authorization": "key=#{server_key}"
		]

		HTTPotion.post(@url, body: body, headers: headers)
		|> parse_response()
	end


	@spec parse_response(%HTTPotion.Response{}) :: result
	defp parse_response(%HTTPotion.Response{status_code: 401}) do
		reply(%{"results" => [%{"error" => "Unauthorized"}]}, 401)
	end
	defp parse_response(%HTTPotion.Response{status_code: status, body: body}) do
		Poison.decode!(body)
		|> reply(status)
	end

	@spec reply(Map.t(), integer()) :: result
	defp reply(%{"results" => [%{ "message_id" => id}]}, 200) do
		Logger.info "Notification succeded"
		{:ok, id}
	end

	@spec reply(Map.t(), integer()) :: result
	defp reply(%{"results" => [%{"error" => error}]}, _status) do
		{:error, error}
	end

	@spec reply(Map.t(), integer()) :: result
	defp reply(_body, 200) do
		{:error, "Invalid body format"}
	end

	@spec reply(Map.t(), integer()) :: result
	defp reply(_body, status), do: {:error, "Unexpected status #{status}"}

	@spec config(atom()) :: any()
	defp config(key) do
		Application.get_env(:notify, Notify.FCM)
		|> Keyword.get(key)
	end
end
