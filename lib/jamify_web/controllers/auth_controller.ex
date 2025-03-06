defmodule JamifyWeb.AuthController do
  use JamifyWeb, :controller

  alias Jamify.JamSession
  alias Jamify.JamSessionSupervisor

  plug Ueberauth, provider: :spotify

  def callback(%{assigns: %{ueberauth_failure: %Ueberauth.Failure{}}} = conn, _params) do
    conn
    |> put_flash(:error, "Error signing in with Spotify.")
    |> redirect(to: ~p"/")
  end

  def callback(%{assigns: %{ueberauth_auth: %Ueberauth.Auth{} = auth}} = conn, _params) do
    session = JamSession.create_from_spotify_auth(auth)

    JamSessionSupervisor.start_session_server(session)

    conn
    |> clear_session()
    |> put_session(:jam_session, session)
    |> redirect(to: ~p"/session")
  end
end
