defmodule Registry do
  use GenServer

  alias Registry.Supervisor.Entities, as: EntitiesSupervisor

  # The state structure tracks the current state of the registry.
  defmodule State do
    defstruct entities: %{}, monitors: %{}, supervisor: nil
  end

  ## Client API

  @doc """
  Start a registry called `name` and link it to the calling process. This
  function should be called only by a registry supervisor.
  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, [name: name])
  end

  @doc """
  Bind the `registry` to its entity `supervisor`, which is a child of the
  registry supervisor. This function should be called only by a root
  supervisor.
  """
  def bind_supervisor(registry, supervisor) do
    GenServer.call(registry, {:bind_supervisor, supervisor})
  end

  @doc """
  Create an entity agent for the `value` and store it under `key` in the
  requested `registry`. The `registry` may be a name or a pid.

  Return {:ok, pid} if successful, where pid is the process id of the added
  entity agent holding the `value`. Return :already_registered if an entity
  with the same `key` is already registered.
  """
  def put(registry, key, value) do
    GenServer.call(registry, {:put, key, value})
  end

  @doc """
  Delete the entity with the matching `key` from the `registry`. The
  `registry` may be a name or a pid.

  Return :ok if an entity was found, :not_found otherwise.
  """
  def delete(registry, key) do
    GenServer.call(registry, {:delete, key})
  end

  @doc """
  Get the process for a specific `key` from the `registry`. The `registry`
  may be a name of a pid.

  Return {:ok, pid} if found, :not_found otherwise.
  """
  def get(registry, key) do
    GenServer.call(registry, {:get, key})
  end

  ## Server callbacks

  def init(:ok) do
    {:ok, %State{}}
  end

  def handle_call({:bind_supervisor, supervisor}, _from, state) do
    state = put_in(state.supervisor, supervisor)
    {:reply, :ok, state}
  end

  def handle_call({:put, key, value}, _from, state) do
    case Map.has_key?(state.entities, key) do
      true ->
        {:reply, :already_registered, state}
      false ->
        {:ok, pid} = EntitiesSupervisor.start_entity(state.supervisor, value)
        mon = Process.monitor(pid)
        state = put_in(state.entities, Map.put(state.entities, key, pid))
        state = put_in(state.monitors, Map.put(state.monitors, mon, key))
        {:reply, {:ok, pid}, state}
    end
  end

  def handle_call({:delete, key}, _from, state) do
    case Map.get(state.entities, key) do
      nil ->
        {:reply, :not_found, state}
      pid ->
        EntitiesSupervisor.stop_entity(state.supervisor, pid)
        {:reply, :ok, state}
    end
  end

  def handle_call({:get, key}, _from, state) do
    case Map.get(state.entities, key) do
      nil ->
        {:reply, :not_found, state}
      pid ->
        {:reply, {:ok, pid}, state}
    end
  end

  def handle_info({:DOWN, mon, :process, _pid, _reason}, state) do
    {key, monitors} = Map.pop(state.monitors, mon)
    {_, entities} = Map.pop(state.entities, key)
    state = put_in(state.monitors, monitors)
    state = put_in(state.entities, entities)
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
