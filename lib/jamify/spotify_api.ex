defmodule Jamify.SpotifyApi do
  alias Jamify.JamSession
  # Refresh spotify credentials 5 minutes before expiration
  @credentials_refresh_treshold 300

  def refresh_credentials(%Ueberauth.Auth.Credentials{} = credentials) do
    now = DateTime.utc_now()
    expiration = DateTime.from_unix!(credentials.expires_at)
    remaining_validity = DateTime.diff(expiration, now)

    if remaining_validity <= @credentials_refresh_treshold do
      # TODO: Refresh spotify credentials using OAuth2
    else
      credentials
    end
  end

  @spec fetch_currently_playing_and_queue(Ueberauth.Auth.Credentials.t()) ::
          {JamSession.song() | nil, JamSession.queue()}
  def fetch_currently_playing_and_queue(%Ueberauth.Auth.Credentials{} = credentials) do
    response =
      Req.new()
      |> Req.Request.put_header("Authorization", "Bearer #{credentials.token}")
      |> Req.get(url: "https://api.spotify.com/v1/me/player/queue")

    case response do
      {:ok, response} ->
        {
          response.body["currently_playing"] |> map_song(),
          response.body["queue"]
          |> Enum.take(5)
          |> Enum.map(&map_song/1)
          |> Enum.reject(&is_nil/1)
        }

      _ ->
        {nil, []}
    end
  end

  defp map_song(json) when is_nil(json), do: nil

  defp map_song(json) do
    %{
      id: json["id"],
      url: json["external_urls"]["spotify"],
      name: json["name"],
      artist: hd(json["artists"])["name"],
      album: %{
        name: json["album"]["name"],
        image: hd(json["album"]["images"])["url"]
      },
      youtube_video_id: nil
    }
  end
end
