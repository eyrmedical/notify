defmodule Notification do
  defstruct title: "",
    message: "",
    expiration: 0,
    priority: "high",
    data: %{},
    sound: Application.get_env(:notify, :sound, "default"),
    color: Application.get_env(:notify, :color, "#333333"),
    icon: Application.get_env(:notify, :icon, "ic_notification"),
    tag: nil,
    voip: false,
    content_available: nil,
    badge: nil
end
