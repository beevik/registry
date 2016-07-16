defmodule RegistryTest do
  use ExUnit.Case
  doctest Registry

  defmodule Entity do
    defstruct name: "", age: 0

    def start_link(data) do
      Agent.start_link(fn -> data end)
    end

    def get(pid) do
      Agent.get(pid, fn data -> data end)
    end
  end

  test "registry updates" do
    {:ok, _pid} = Registry.Supervisor.start_link(:entities, Entity)

    {:ok, _pid} = Registry.put(:entities, "brett", %Entity{name: "brett", age: 45})

    :already_registered = Registry.put(:entities, "brett", %Entity{})

    {:ok, pid} = Registry.get(:entities, "brett")

    entity = Entity.get(pid)
    assert entity.name == "brett"
    assert entity.age == 45

    :ok = Registry.delete(:entities, "brett")

    :not_found = Registry.delete(:entities, "brett")
  end
end
