defmodule JamifyWeb.PageController do
  use JamifyWeb, :controller

  alias Jamify.JamSessionSupervisor

  def home(conn, _params) do
    jam_session = get_session(conn, :jam_session)

    conn
    |> assign(:jam_session, jam_session)
    |> render(:home)
  end

  def jam_not_found(conn, _params) do
    render(conn, :jam_not_found)
  end

  def manage_session(conn, _params) do
    case get_session(conn, :jam_session) do
      nil ->
        redirect(conn, to: ~p"/")

      %Jamify.JamSession{} = session ->
        conn
        |> assign(:jam_session, session)
        |> render(:manage_session)
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
