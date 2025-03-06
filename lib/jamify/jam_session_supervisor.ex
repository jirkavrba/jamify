defmodule Jamify.JamSessionSupervisor do
  use DynamicSupervisor

  require Logger
  alias Jamify.JamSessionServer

  @impl DynamicSupervisor
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_session_server(%Jamify.JamSession{} = session) do
    DynamicSupervisor.start_child(__MODULE__, {JamSessionServer, session}) |> dbg()
  end

  def stop_session_server(%Jamify.JamSession{} = session) do
    case JamSessionServer.find_server_by_slug(session) do
      pid when is_pid(pid) -> DynamicSupervisor.terminate_child(__MODULE__, pid)
    end
  end
end
