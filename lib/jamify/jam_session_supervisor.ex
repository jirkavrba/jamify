defmodule Jamify.JamSessionSupervisor do
  use DynamicSupervisor, restart: :permanent

  require Logger
  alias Jamify.JamSessionServer

  # Forcily terminate the session after 6 hours
  @session_time_to_live 6 * 60 * 60 * 1000

  @impl DynamicSupervisor
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_session_server(%Jamify.JamSession{} = session) do
    schedule_jam_termination(session)
    DynamicSupervisor.start_child(__MODULE__, {JamSessionServer, session})
  end

  def stop_session_server(%Jamify.JamSession{} = session) do
    case Registry.lookup(JamSessionServer.registry(), session.id) do
      [{pid, _}] when is_pid(pid) ->
        Phoenix.PubSub.broadcast!(Jamify.PubSub, "jam:#{session.id}", :jam_session_terminated)
        DynamicSupervisor.terminate_child(__MODULE__, pid)

      _ ->
        {:error, :jam_session_server_not_found}
    end
  end

  def schedule_jam_termination(session) do
    Task.async(fn ->
      Process.sleep(@session_time_to_live)
      stop_session_server(session)
    end)
  end
end
