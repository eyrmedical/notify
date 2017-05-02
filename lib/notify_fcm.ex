defmodule Notify.FCM do
  require Logger
  @moduledoc """
  A module for generating push notifications on the Firebase Cloud Messaging platform (from Google) using HTTP requests.
  """

  @project_id Application.get_env(:notify, :project_id)
  || "PROJECT_ID"
  @server_key Application.get_env(:notify, :server_key)
  @url "https://fcm.googleapis.com/fcm/send"
  @type result :: {atom(), String.t()}

  unless @server_key do
    raise """
    Missing API key for Firebase Cloud Messaging in configuration. Find it at:
    https://console.firebase.google.com/project/#{@project_id}/settings/cloudmessaging
    """
  end

  @doc """
  Send a push notification through the Firebase Cloud Messaging service.
  """
  @spec push(Map.t()) :: result
  def push(%{ "to" => device_id } = notification) do
    Logger.info "Pushing notification to #{device_id}"

    body = Poison.encode!(notification)
    headers = [
      "Content-Type": "application/json",
      "Authorization": "key=#{@server_key}"
    ]

    HTTPotion.post(@url, body: body, headers: headers)
    |> parse_response()
  end


  @spec parse_response(%HTTPotion.Response{}) :: result
  defp parse_response(%HTTPotion.Response{ status_code: status, body: body }) do
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
  defp reply(body, 200) do
    IO.inspect(body)
    {:error, "Invalid body format"}
  end

  @spec reply(Map.t(), integer()) :: result
  defp reply(body, status), do: {:error, "Unexpected status #{status}"}


end
