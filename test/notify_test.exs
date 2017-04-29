defmodule NotifyTest do
  use ExUnit.Case
  doctest Notify

  setup_all _context do
    {:ok, pid} = Client.start_link
    Process.sleep(1000)
    {:ok, monitor: pid}
  end

  test "Generate token" do
    token = Notify.create_token()
    assert is_binary(token)
  end

end
