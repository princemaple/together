# Together [![Hex.pm](https://img.shields.io/hexpm/v/together.svg)]()

Group actions that need to be performed later together

## Links

- [Hex](https://hex.pm/packages/together)
- [Hex Docs](https://hexdocs.pm/together/Together.html)

## What for?

- group notifications before sending an email about them
- only sending the very last value of a fast changing entity (renew: true)
- only using the very first value of a changing entity in every fixed period (renew: false)

## Installation

The package can be installed as:

Add `together` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:together, "~> 0.1.0"}]
end
```

## How to use

Start a `Together.Worker` to use it

You can start it by adding a worker to your app's supervision tree

```elixir
worker(Together.Worker, [[delay: 3000, renew: true], [name: Together.Worker]])
```

Or start it as you would any other GenServer

```elixir
{:ok, pid} = Together.Worker.start_link(delay: 300, renew: true)
```

Make calls to the worker process:

- `Together.process(pid, "some_unique_name_or_id", a_function)`
- `Together.process(pid, "id", Module, :func, [arg1, arg2, ...])`
- `Together.process("something", some_func)` you can omit the pid if the server is started with name `Together.Worker`

## TODO

- value accumulation
- pooling
- distributed buffer
