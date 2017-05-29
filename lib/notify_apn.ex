defmodule Notify.APN do
	require Logger
	import Joken
	@moduledoc """
	A module for generating push notifications on the Apple Push Notification service using HTTP2 requests and the new .p8 key standard. This module will generate JWT tokens from the .p8 key and use them to push notifications to device IDs.
	"""

	@config Application.get_env(:notify, Notify.APN) |> IO.inspect
	@key_id Keyword.get(@config, :key_id)
	@team_id Keyword.get(@config, :team_id)
	@bundle_id Keyword.get(@config, :bundle_id)
	@key Keyword.get(@config, :key_path) |> JOSE.JWK.from_pem_file()


	@type result :: {atom(), String.t()}

	unless Application.get_all_env(:notify) do
		raise "Notify is not configured"
	end

	if @config do
		unless @key do
			raise """
			Could not read key file. Provide a path (full, with filename) to a valid .p8 file in config.
			"""
		end

		unless @key_id do
			raise """
			:key_id is not configured. Add the Key ID of your APNsAuthKey_APPLE_KEY_ID.p8 file to config.
			"""
		end

		unless String.length(@team_id) == 10 do
			raise """
			Invalid :team_id (must be 10 characters). Find :team_id in Xcode or in your Apple Developer account"
			"""
		end

		unless @bundle_id do
			raise """
			Missing :bundle_id from configuration. :bundle_id is Apples internal ID for your application.
			"""
		end
	end

	@doc """
	Push a notification to device
	"""
	@spec push(Map.t(), String.t()) :: result
	def push(%{
		"expiration" => expiration,
		"priority" => priority,
		"notification" => notification,
		"data" => data
	}, device_id) do
		Logger.info "Pushing notification to #{device_id}"

		{:ok, pid} = Kadabra.open(get_url(), :https)

		headers = [
			{":authority", get_url() |> to_string()},
			{":method", "POST"},
			{":path", "/3/device/#{device_id}"},
			{"authorization", "bearer " <> get_token()},
			{"apns-topic", @bundle_id},
			{"apns-expiration", expiration |> to_string()},
			{"apns-priority", priority |> to_string()}
		]
		body = Poison.encode!(%{"aps" => notification, "payload" => data}) |> IO.inspect

		Kadabra.request(pid, headers, body)

		receive do
			{:end_stream, %Kadabra.Stream{} = stream} -> reply(stream, device_id)
		after 5_000 ->
			reply(:timeout, device_id)
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

		new_token = %{ "iss" => @team_id, "iat" => time }
		|> token
		|> with_header_arg("kid", @key_id)
		|> sign(es256(@key))
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
			[{ _, stored_token, expires}] -> check_expiration({stored_token, expires})
			_ -> create_token()
		end
	end

	@spec check_expiration({ String.t(), Number.t() }) :: String.t()
	defp check_expiration({stored_token, exp}) do
		time = timestamp()
		if exp >= time do
			# Expiration is set to 60 seconds before actual expiration on APNs
			Logger.debug "Stored token is valid for #{exp - time} more seconds"
			stored_token
		else
			Logger.debug "Stored token has been expired for #{time - exp} seconds"
			create_token()
		end
	end

	@spec reply(%Kadabra.Stream{}, String.t()) :: result
	defp reply(%Kadabra.Stream{:status => 200, :headers => headers}, device_id) do
		Logger.info "Notification to #{device_id} succeeded"
		[_, {"apns-id", notification_id}] = headers
		{:ok, notification_id}
	end

	defp reply(%Kadabra.Stream{} = response, device_id) do
		reason = response
		|> Map.get(:body, "")
		|> Poison.decode!
		|> Map.get("reason", "Unexpected status")
		Logger.warn "Notification to #{device_id} failed: #{reason}"
		{:error, reason}
	end

	@spec reply(atom(), String.t()) :: result
	defp reply(:timeout, device_id) do
		Logger.warn "Notification to #{device_id} timed out."
		{:error, "Request timed out"}
	end


	@spec get_url() :: binary() # Kadabra requires a charlist as address
	defp get_url() do
		if Application.get_env(:notify, :production) do
			'api.push.apple.com'
		else
			'api.development.push.apple.com'
		end
	end

	@spec timestamp() :: number()
	defp timestamp(), do: DateTime.utc_now() |> DateTime.to_unix()
end
