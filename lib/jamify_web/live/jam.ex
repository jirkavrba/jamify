defmodule JamifyWeb.Live.Jam do
  alias Jamify.UserIdentifier
  use JamifyWeb, :live_view

  alias Jamify.JamSession
  alias JamifyWeb.Pressence

  def mount(%{"id" => id}, _session, socket) do
    case JamSession.find_by_id(id) do
      {:ok, session} ->
        JamSession.subscribe_to_updates(id)

        peer = get_connect_info(socket, :peer_data)
        user_id = UserIdentifier.create_from_peer_info(peer)

        Pressence.track(self(), presence_topic(id), user_id.id, user_id)

        socket =
          socket
          |> assign(:session, session)
          |> assign(:page_title, build_page_title(session))
          |> assign(:listeners, [])

        {:ok, socket}

      {:error, :jam_session_not_found} ->
        {:ok, push_navigate(socket, to: ~p"/jam/not-found")}
    end
  end

  def handle_info({:jam_session_updated, updated_session}, socket) do
    socket =
      socket
      |> assign(:session, updated_session)
      |> assign(:page_title, build_page_title(updated_session))

    {:noreply, assign(socket, session: updated_session)}
  end

  def handle_info(:jam_session_terminated, socket) do
    {:noreply, push_navigate(socket, to: ~p"/jam/not-found")}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    topic = presence_topic(socket.assigns[:session].id)
    presences = Pressence.list(topic)

    listeners =
      presences
      |> Map.values()
      |> Enum.map(& &1.metas)
      |> Enum.map(&hd/1)

    {:noreply, assign(socket, :listeners, listeners)}
  end

  defp build_page_title(%Jamify.JamSession{currently_playing: nil}), do: "Not playing"
  defp build_page_title(%Jamify.JamSession{currently_playing: song}), do: song.name

  defp presence_topic(jam_id), do: "jam:#{jam_id}"
end
