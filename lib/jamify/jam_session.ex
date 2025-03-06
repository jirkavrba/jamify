defmodule Jamify.JamSession do
  alias Jamify.JamSessionServer

  @type host :: %{
          name: String.t(),
          image_url: String.t()
        }

  @type t :: %__MODULE__{
          id: String.t(),
          slug: String.t(),
          host: host(),
          spotify_credentials: Ueberauth.Auth.Credentials.t()
        }

  @enforce_keys [
    :id,
    :slug,
    :host,
    :spotify_credentials
  ]

  defstruct [
    :id,
    :slug,
    :host,
    :spotify_credentials
  ]

  def create_from_spotify_auth(%Ueberauth.Auth{} = auth) do
    id = create_session_id()
    slug = MnemonicSlugs.generate_slug(5)

    %__MODULE__{
      id: id,
      slug: slug,
      host: %{
        name: auth.info.name,
        image_url: auth.info.image
      },
      spotify_credentials: auth.credentials
    }
  end

  def find_by_slug(slug) do
    case JamSessionServer.find_jam_by_slug(slug) do
      {:ok, pid} -> GenServer.call(pid, :get_session)
      {:error, reason} -> {:error, reason}
    end
  end

  defp create_session_id() do
    seed = :rand.bytes(32)
    seed_hash = :crypto.hash(:md5, seed)

    Base.encode16(seed_hash)
  end
end
