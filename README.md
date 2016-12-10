# Together

Group actions that need to be performed later together

## Installation

The package can be installed as:

Add `together` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:together, "~> 0.1.0"}]
end
```

## How to use

Start a `Together.Server` to use it

You can start it by adding a worker to your app's supervision tree

```elixir
worker(Together.Server, [[delay: 3000, renew: true], [name: Together.Server]])
```

Or start it as you would any other GenServer

```elixir
{:ok, pid} = Together.Server.start_link(delay: 300, renew: true)
```

Make calls to the server:

- `Together.process(pid, "some_unique_name_or_id", a_function)`
- `Together.process(pid, "id", Module, :func, [arg1, arg2, ...])`
- `Together.process("something", some_func)` you can omit the pid if the server is started with name `Together.Server`
