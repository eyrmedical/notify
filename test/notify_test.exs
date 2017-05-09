defmodule NotifyTest do
  use ExUnit.Case
  doctest Notify

  @test_ios true
  @test_android false

  @ios {:ios, "2e3954ad967348ff66b6765bae71376998b2e8c15de63be2005e6eb0c1f9b5df"}
  @android {:android, "PASTE_YOUR_ANDROID_DEVICE_TOKEN_HERE"}
  @voip %Notification{
    data: %{
      "voip": true,
      "name": "Notify Test",
      "key": "45589032",
      "session_id": "1_MX40NTU4OTAzMn5-MTQ5MzgyMjI0NjMxNH52dHFsenNLUnFTOU4vV3N1RmlMcHZ6b0V-UH4",
      "token": "T1==cGFydG5lcl9pZD00NTU4OTAzMiZzaWc9YzExMmE0MTRiYjQ4M2U3MDc1ZGJiOWNjZGExMDE3ZGIyOWM4YTU5MDpzZXNzaW9uX2lkPTFfTVg0ME5UVTRPVEF6TW41LU1UUTVNemd5TWpJME5qTXhOSDUyZEhGc2VuTkxVbkZUT1U0dlYzTjFSbWxNY0haNmIwVi1VSDQmY3JlYXRlX3RpbWU9MTQ5MzgyMjI1MCZub25jZT0wLjc0NTE1NTkwODgwODkwNjYmcm9sZT1wdWJsaXNoZXImZXhwaXJlX3RpbWU9MTQ5MzkwODY1MA=="
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
