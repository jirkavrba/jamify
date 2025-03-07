defmodule JamifyWeb.Live.Jam do
  use JamifyWeb, :live_view

  alias Jamify.JamSession

  def mount(%{"id" => id}, _session, socket) do
    case JamSession.find_by_id(id) do
      {:ok, session} ->
        JamSession.subscribe_to_updates(id)
        {:ok, assign(socket, session: session)}

      {:error, :jam_session_not_found} ->
        {:ok, push_navigate(socket, to: ~p"/jam/not-found")}
    end
  end

  def handle_info({:jam_session_updated, updated_session}, socket) do
    {:noreply, assign(socket, session: updated_session)}
  end

  def handle_info(:jam_session_terminated, socket) do
    {:noreply, push_redirect(socket, to: ~p"/jam/not-found")}
  end
end
