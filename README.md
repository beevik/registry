# Registry

Registry is an Elixir implementation of a monitored process registry.
It allows processes to be associated with names, which may be any type
(except for a pid). When a registered process terminates, its association
is automatically removed.

The registry is designed to be used with Elixir GenServer
[:via tuples](http://elixir-lang.org/docs/stable/elixir/GenServer.html#module-name-registration).

## Examples

Here is how to create a registry:

```elixir
Registry.start_link()
```

Here is how to add an entry to the registry:
```elixir
Registry.register_name(:foo, pid)
```

Here is how to remove an entry from the registry:
```elixir
Registry.unregister_name(:foo)
```

Here is how to look up an entry in the registry:
```elixir
pid = Registry.whereis_name(:foo)
```
