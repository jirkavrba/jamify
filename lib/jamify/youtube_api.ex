defmodule Jamify.YoutubeApi do
  require Logger

  def resolve_video_id_from_spotify(spotify_url) do
    Logger.info("Resolving YouTube music video for spotify url: #{spotify_url}")

    case Req.get("https://ytm2spotify.com/convert?to_service=youtube_ytm&url=#{spotify_url}") do
      {:ok, response} ->
        response.body
        |> Map.get("results")
        |> List.first()
        |> Map.get("url")
        |> String.replace("https://youtube.com/watch?v=", "")

      _ ->
        nil
    end
  end
end
