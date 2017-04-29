defmodule Client do
  use GenServer
  require Logger
  import Notify

  @team_id Application.get_env(:notify, :team_id)
  @key_id Application.get_env(:notify, :key_id)
  @bundle_id Application.get_env(:notify, :bundle_id)
  @key_filename "APNsAuthKey_" <> @key_id <> ".p8"

  def start_link do
    GenServer.start_link(__MODULE__, %{ :token => :nil }, name: __MODULE__)
  end

  def init(state) do
    Logger.info "Initialised Notify (APNs) client"
    GenServer.cast(__MODULE__, :create_token)
    {:ok, state}
  end

  def handle_cast(:create_token, state) do
    # state = Map.put(state, :token, Notify.create_token())
    {:noreply, state}
  end
end
