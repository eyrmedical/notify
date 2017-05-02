defmodule NotifyTest do
  use ExUnit.Case
  doctest Notify

  @test_ios true
  @test_android false

  @ios {:ios, "PASTE_YOUR_IOS_DEVICE_TOKEN_HERE"}
  @android {:android, "PASTE_YOUR_ANDROID_DEVICE_TOKEN_HERE"}
  @voip %Notification{
    title: "NotifyTest VOIP notification",
    message: "This is a message from the Notify package written in Elixir",
    data: %{
      "voip": true
    }
  }
  @regular %Notification{
    title: "NotifyTest regular notification",
    message: "This is a message from the Notify package written in Elixir"
  }

  setup_all _context do
    Notify.APNS.init_table()
    Process.sleep(1000)

    initial_token = Notify.APNS.create_token()
    {:ok, token: initial_token}
  end

  test "Retrieve the initial token from memory", %{token: initial_token} do
    assert initial_token == Notify.APNS.get_token()
  end

  test "Create a new token", %{token: intial_token} do
    new_token = Notify.APNS.create_token()
    assert intial_token != new_token
    assert String.length(new_token) == 200
  end

  if @test_ios do
    test "iOS push notification" do
      assert {:ok, _id} = Notify.push(@ios, @regular)
    end

    test "iOS push notification to invalid device_id fails" do
      assert {:error, "BadDeviceToken"} = Notify.push({:ios, "WRONG"}, @regular)
    end


    test "iOS VOIP notification" do
      assert {:ok, _id} = Notify.push(@ios, @voip)
    end
  end

  if @test_android do
    test "Android VOIP notification" do
      assert {:ok, _id} = Notify.push(@android, @voip)
    end
  end

end
