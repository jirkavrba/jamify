defmodule Jamify.JamSessionServer do
  alias Jamify.SpotifyApi
  use GenServer
  require Logger

  @registry :jam_session_registry

  def registry(), do: @registry

  def init(session) do
    {:ok, session, {:continue, :fetch_spotify_data}}
  end

  def start_link(session) do
    GenServer.start_link(__MODULE__, session, name: via_tuple(session.id))
  end

  def handle_call(:get_session, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_continue(:fetch_spotify_data, state) do
    updated = update_spotify_data(state)
    schedule_spotify_update()

    {:noreply, updated}
  end

  def handle_info(:update_spotify_data, state) do
    updated = update_spotify_data(state)
    schedule_spotify_update()

    {:noreply, updated}
  end

  def find_session_by_id(id) do
    try do
      GenServer.call(via_tuple(id), :get_session)
    catch
      # TODO: Is there a better way to check whether the process is alive?
      :exit, _ -> {:error, :jam_session_not_found}
    end
  end

  defp via_tuple(id) do
    {:via, Registry, {@registry, id}}
  end

  defp schedule_spotify_update(delay \\ 5000) do
    Process.send_after(self(), :update_spotify_data, delay)
  end

  defp update_spotify_data(%Jamify.JamSession{} = session) do
    Logger.info("Updating spotify data for session #{session.id}")

    refreshed_credentials = SpotifyApi.refresh_credentials(session.spotify_credentials)

    {currently_playing, queued_songs} =
      SpotifyApi.fetch_currently_playing_and_queue(refreshed_credentials)

    updated_session =
      %{
        session
        | spotify_credentials: refreshed_credentials,
          currently_playing: currently_playing,
          queued_songs: queued_songs
      }

    Phoenix.PubSub.broadcast!(Jamify.PubSub, "jam:#{session.id}", {
      :jam_session_updated,
      updated_session
    })

    updated_session
  end
end
