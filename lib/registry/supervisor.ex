defmodule Registry.Supervisor do
  use Supervisor

  @doc """
  Start a root supervisor for the registry with the given `name`.  The
  supervisor creates and manages the registry for agent entities defined by
  the module `entity_mod`. It also launches a child entity supervisor to
  manage the creation and monitoring of registry entities.

  Return {:ok, pid}, where pid is the process id of the registry supervisor.
  """
  def start_link(name, entity_mod) do
    supname = name
      |> Atom.to_string
      |> (fn a,b -> a <> b end).(".Supervisor")
      |> String.to_atom

    {:ok, pid} = Supervisor.start_link(__MODULE__, {name, entity_mod},
                                       [name: supname])

    # Bind the entity supervisor to its registry.
    children = Supervisor.which_children(pid)
    Registry.bind_supervisor(pid_of(children, :worker),
                             pid_of(children, :supervisor))

    {:ok, pid}
  end

  def init({name, entity_mod}) do
    children = [
      worker(Registry, [name]),
      supervisor(Registry.Supervisor.Entities, [name, entity_mod])
    ]
    supervise(children, [strategy: :rest_for_one])
  end

  defp pid_of(children, type) do
    Enum.find_value(children, fn {_, pid, t, _} -> if type == t, do: pid end)
  end


  # This Entities supervisor is a child of the Registry.Supervisor and manages
  # the creation and registration of entities.
  defmodule Entities do
    use Supervisor

    def start_link(name, entity_mod) do
      supname = name
        |> Atom.to_string
        |> (fn a,b -> a <> b end).(".EntitySupervisor")
        |> String.to_atom

      Supervisor.start_link(__MODULE__, entity_mod, [name: supname])
    end

    def start_entity(supervisor, data) do
      Supervisor.start_child(supervisor, [data])
    end

    def stop_entity(supervisor, pid) do
      Supervisor.terminate_child(supervisor, pid)
    end

    def init(entity_mod) do
      children = [
        worker(entity_mod, [], [restart: :temporary])
      ]
      supervise(children, strategy: :simple_one_for_one)
    end
  end
end
