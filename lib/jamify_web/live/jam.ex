defmodule JamifyWeb.Live.Jam do
  use JamifyWeb, :live_view

  alias Jamify.JamSession

  def mount(%{"id" => id}, _session, socket) do
    case JamSession.find_by_id(id) do
      {:ok, session} ->
        JamSession.subscribe_to_updates(id)

        socket =
          socket
          |> assign(:session, session)
          |> assign(:page_title, build_page_title(session))

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

  defp build_page_title(%Jamify.JamSession{currently_playing: nil}), do: "Not playing"
  defp build_page_title(%Jamify.JamSession{currently_playing: song}), do: song.name
end
