defmodule JamifyWeb.AuthController do
  use JamifyWeb, :controller

  plug Ueberauth, provider: :spotify

  def callback(%{assigns: %{ueberauth_failure: %Ueberauth.Failure{}}} = conn, _params) do
    conn
    |> put_flash(:error, "Error signing in with Spotify.")
    |> redirect(to: ~p"/")
  end

  def callback(%{assigns: %{ueberauth_auth: %Ueberauth.Auth{} = auth}} = conn, _params) do
    # TODO: Create a new Jam session linked to the account
    jam_session_id = "452cdd2a27bc262cdc1bdae6a1a00f5a"

    dbg(auth)

    conn
    |> clear_session()
    |> put_session(:jam_session_id, jam_session_id)
    |> redirect(to: ~p"/session/#{jam_session_id}")
  end
end
