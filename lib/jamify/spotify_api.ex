defmodule Jamify.SpotifyApi do
  require Logger

  alias Plug.BasicAuth
  alias Jamify.JamSession

  # Refresh spotify credentials 5 minutes before expiration
  @credentials_refresh_treshold 300

  def refresh_credentials(%Ueberauth.Auth.Credentials{} = credentials) do
    now = DateTime.utc_now()
    expiration = DateTime.from_unix!(credentials.expires_at)
    remaining_validity = DateTime.diff(expiration, now)

    if remaining_validity <= @credentials_refresh_treshold do
      perform_access_token_refresh(credentials)
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
          |> Enum.take(10)
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

  defp perform_access_token_refresh(%Ueberauth.Auth.Credentials{} = credentials) do
    client = Ueberauth.Strategy.Spotify.OAuth.client()
    authorization = BasicAuth.encode_basic_auth(client.client_id, client.client_secret)

    response =
      Req.post(
        client.token_url,
        headers: %{
          "authorization" => authorization
        },
        form: %{
          "grant_type" => "refresh_token",
          "refresh_token" => credentials.refresh_token,
          "client_id" => client.client_id
        }
      )

    case response do
      {:ok, %Req.Response{status: 200, body: body}} ->
        expiration =
          DateTime.utc_now()
          |> DateTime.add(body["expires_in"], :second)
          |> DateTime.to_unix(:second)
          |> dbg()

        %{credentials | expires_at: expiration, token: body["access_token"]}

      _ ->
        Logger.error("Error refreshing credentials: #{response}.")
        credentials
    end
  end
end
