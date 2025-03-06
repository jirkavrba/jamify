defmodule JamifyWeb.Live.Jam do
  use JamifyWeb, :live_view

  def mount(%{"session_slug" => slug}, session, socket) do
    {:ok, socket}
  end
end
