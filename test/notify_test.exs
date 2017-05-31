defmodule NotifyTest do
	use ExUnit.Case
	doctest Notify

	@test_apn false
	@test_fcm false
	@test_gcm true

	@ios {:ios, "PASTE_DEVICE_TOKEN" }
	@android {:android, "PASTE_DEVICE_TOKEN" }
	@voip %Notification{
		data: %{
			"voip": true,
			"name": "Notify Test"
		}
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
