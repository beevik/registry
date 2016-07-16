# Registry

Registry is an Elixir implementation of a fault-tolerant key-value store,
where values are Elixir agents isolated in their own processes. Each
registry is managed by an OTP supervisor for fault tolerance.

## Examples

Suppose you have a structure called `Person` that you wish to store in
a registry called `:persons`, using each person's name as the key.

```elixir
defmodule Person do
  defstruct name: "", age: 0

  def start_link(data) do
    Agent.start_link(fn -> data end)
  end

  def get(pid) do
    Agent.get(pid, fn data -> data end)
  end
end
```

Here is how you would create a registry to store `Person` records:

```elixir
{:ok, _supervisor_pid} = Registry.Supervisor.start_link(:persons, Person)
```

Here is how you would add a person to the registry and then access its
data:
```elixir
{:ok, jane} = Registry.put(:persons, "Jane", %Person{name: "Jane", age: 20})
data = Person.get(jane)
IO.puts "Name: #{data.name}, Age: #{data.age}"
```

Here is how you would remove a person from the registry:
```elixir
:ok = Registry.delete(:persons, "Jane")
```
