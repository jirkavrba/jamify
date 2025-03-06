defmodule JamifyWeb.PageController do
  use JamifyWeb, :controller

  def home(conn, _params) do
    jam_session_id = get_session(conn, :jam_session_id)

    conn
    |> assign(:jam_session_id, jam_session_id)
    |> render(:home)
  end
end
