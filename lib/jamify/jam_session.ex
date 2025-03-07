defmodule Jamify.JamSession do
  alias Jamify.JamSessionServer

  @type host :: %{
          name: String.t(),
          image_url: String.t()
        }

  @type song :: %{
          id: String.t(),
          url: String.t(),
          name: String.t(),
          artist: String.t(),
          album: %{
            name: String.t(),
            image_url: String.t()
          },
          youtube_video_id: String.t() | nil
        }

  @type queue :: list(song())

  @type t :: %__MODULE__{
          id: String.t(),
          host: host(),
          spotify_credentials: Ueberauth.Auth.Credentials.t(),
          currently_playing: song() | nil,
          queued_songs: queue(),
          youtube_video_id: String.t() | nil
        }

  @enforce_keys [
    :id,
    :host,
    :spotify_credentials
  ]

  defstruct [
    :id,
    :host,
    :spotify_credentials,
    :currently_playing,
    :queued_songs,
    :youtube_video_id
  ]

  def create_from_spotify_auth(%Ueberauth.Auth{} = auth) do
    id = MnemonicSlugs.generate_slug(5)

    %__MODULE__{
      id: id,
      host: %{
        name: auth.info.name,
        image_url: auth.info.image
      },
      spotify_credentials: auth.credentials,
      currently_playing: nil,
      queued_songs: []
    }
  end

  def find_by_id(id) do
    case JamSessionServer.find_session_by_id(id) do
      {:ok, session} -> {:ok, session}
      {:error, reason} -> {:error, reason}
    end
  end

  def subscribe_to_updates(id) do
    Phoenix.PubSub.subscribe(Jamify.PubSub, "jam:#{id}")
  end
end
