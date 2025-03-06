defmodule JamifyWeb.SessionController do
  alias Jamify.JamSessionSupervisor
  alias Jamify.JamSessionServer
  use JamifyWeb, :controller

  def manage_session(conn, _params) do
    case get_session(conn, :jam_session) do
      nil ->
        redirect(conn, to: ~p"/")

      %Jamify.JamSession{} = session ->
        conn
        |> assign(:jam_session, session)
        |> render(:manage)
    end
  end

  def stop_session(conn, _params) do
    jam_session = get_session(conn, :jam_session)

    if not is_nil(jam_session) do
      JamSessionSupervisor.stop_session_server(jam_session)
    end

    conn
    |> clear_session()
    |> redirect(to: ~p"/")
  end
end
