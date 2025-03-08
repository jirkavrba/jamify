defmodule JamifyWeb.Pressence do
  use Phoenix.Presence,
    otp_app: :jamify,
    pubsub_server: Jamify.PubSub
end
