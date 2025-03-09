defmodule Jamify.JamSessionServer do
  alias Jamify.YoutubeApi
  alias Jamify.SpotifyApi
  use GenServer
  require Logger

  @registry :jam_session_registry

  def registry(), do: @registry

  def init(session) do
    {:ok, session, {:continue, :initialize_timers}}
  end

  def start_link(session) do
    GenServer.start_link(__MODULE__, session, name: via_tuple(session.id))
  end

  def handle_call(:get_session, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_continue(:initialize_timers, state) do
    schedule_spotify_update(0)
    schedule_youtube_cache_cleanup()

    {:noreply, state}
  end

  def handle_info(:update_spotify_data, state) do
    updated_session = update_spotify_data(state)
    schedule_spotify_update()

    {:noreply, updated_session}
  end

  def handle_info(:cleanup_youtube_cache, state) do
    # TODO: Cleanup old videos from cache
    updated_session = cleanup_youtube_cache(state)
    schedule_youtube_cache_cleanup()

    {:noreply, updated_session}
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

  defp schedule_spotify_update(delay \\ 3000) do
    Process.send_after(self(), :update_spotify_data, delay)
  end

  defp schedule_youtube_cache_cleanup(delay \\ 10 * 60 * 1000) do
    Process.send_after(self(), :cleanup_youtube_cache, delay)
  end

  defp update_spotify_data(%Jamify.JamSession{} = session) do
    Logger.info("Updating spotify data for session #{session.id}")

    refreshed_credentials = SpotifyApi.refresh_credentials(session.spotify_credentials)

    updated_session =
      SpotifyApi.fetch_currently_playing_and_queue(refreshed_credentials)
      |> map_spotify_response_to_session(session, refreshed_credentials)
      |> resolve_youtube_videos()

    Phoenix.PubSub.broadcast!(Jamify.PubSub, "jam:#{session.id}", {
      :jam_session_updated,
      updated_session
    })

    updated_session
  end

  defp map_spotify_response_to_session(
         {currently_playing, queued_songs},
         %Jamify.JamSession{} = session,
         %Ueberauth.Auth.Credentials{} = credentials
       ) do
    %Jamify.JamSession{
      session
      | spotify_credentials: credentials,
        currently_playing: currently_playing,
        queued_songs: queued_songs
    }
  end

  defp cleanup_youtube_cache(%Jamify.JamSession{} = session) do
    now = DateTime.utc_now()

    filtered_cache =
      session.youtube_videos_cache
      |> Map.filter(fn {_key, entry} ->
        DateTime.before?(entry.expiration, now)
      end)

    %{session | youtube_videos_cache: filtered_cache}
  end

  defp resolve_youtube_videos(%Jamify.JamSession{currently_playing: nil} = session), do: session

  defp resolve_youtube_videos(%Jamify.JamSession{currently_playing: currently_playing} = session) do
    {video_id, updated_video_cache} = resolve_youtube_video(session, currently_playing.url)
    updated_currently_playing = %{currently_playing | youtube_video_id: video_id}

    updated_session = %{
      session
      | currently_playing: updated_currently_playing,
        youtube_videos_cache: updated_video_cache
    }

    updated_session
  end

  # Try to resolve video from cache first, if not found, call the backing API and store the result in cache
  defp resolve_youtube_video(%Jamify.JamSession{} = session, spotify_url) do
    cache = session.youtube_videos_cache
    cached_result = Map.get(cache, spotify_url, :cache_miss)

    case cached_result do
      :cache_miss ->
        video_id = YoutubeApi.resolve_video_id_from_spotify(spotify_url)
        expiration = DateTime.add(DateTime.utc_now(), 30, :minute)

        cache_entry = %{
          video_id: video_id,
          expiration: expiration
        }

        updated_cache = Map.put(cache, spotify_url, cache_entry)

        {video_id, updated_cache}

      cache_entry ->
        {cache_entry.video_id, cache}
    end
  end
end
