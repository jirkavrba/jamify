defmodule Jamify.JamSessionServer do
  use GenServer
  require Logger

  @registry :jam_session_registry

  def init(session) do
    dbg(session)
    {:ok, session}
  end

  def start_link(session) do
    GenServer.start_link(__MODULE__, session, name: via_tuple(session.slug))
  end

  def find_session_by_slug(slug) do
    # TODO
  end

  def find_server_by_slug(slug) do
    GenServer.whereis(via_tuple(slug))
    |> dbg()
  end

  defp via_tuple(slug) do
    {:via, Registry, {@registry, slug}}
  end
end
