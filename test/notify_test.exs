defmodule NotifyTest do
	use ExUnit.Case
	doctest Notify

	@test_apn true
	@test_fcm false
	@test_gcm false

	@ios {:ios, Application.get_env(:notify, :device_token_ios) }
	@android {:android, Application.get_env(:notify, :device_token_android) }
	@voip %Notification{
		sound: "eyr.m4a",
		data: %{
			"voip": true,
			"name": "Notify Test",
			"provider": 1,
			"key": "45589032",
			"session_id": "1_MX40NTU4OTAzMn5-MTQ5NjY3MjkwNjg0OH5sUDhTSGU0Z3UrK0gyOG5LcUNZYlJhS3p-UH4",
			"token": "T1==cGFydG5lcl9pZD00NTU4OTAzMiZzaWc9MDQ2Y2UzNDA4ZjFmYTA5ODIzNzMyNDc5OGI1OWIzYWU1NTIxMjg2ZjpzZXNzaW9uX2lkPTFfTVg0ME5UVTRPVEF6TW41LU1UUTVOalkzTWprd05qZzBPSDVzVURoVFNHVTBaM1VySzBneU9HNUxjVU5aWWxKaFMzcC1VSDQmY3JlYXRlX3RpbWU9MTQ5NjY3MjkwNyZub25jZT0wLjk4Mzk1NjQxMTAwOTU0NzYmcm9sZT1wdWJsaXNoZXImZXhwaXJlX3RpbWU9MTQ5Njc1OTMwNw=="
		},
		voip: true
	}
	@regular %Notification{
		title: "NotifyTest regular notification",
		message: "This is a message from the Notify package written in Elixir",
	}

	setup_all _context do
		Notify.APN.init_table()
		Process.sleep(1000)

		initial_token = Notify.APN.create_token()
		{:ok, token: initial_token}
	end

	test "Retrieve the initial token from memory", %{token: initial_token} do
		assert initial_token == Notify.APN.get_token()
	end

	test "Create a new token", %{token: intial_token} do
		new_token = Notify.APN.create_token()
		assert intial_token != new_token
		assert String.length(new_token) == 200
	end

	if @test_apn do
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

	if @test_fcm do
		test "Android VOIP notification" do
			assert {:ok, _id} = Notify.push(@android, @voip)
		end
	end

	if @test_gcm do
		test "Android VOIP notification" do
			assert {:ok, _id} = Notify.push(@android, @voip)
		end
	end

end
