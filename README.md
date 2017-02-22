# Together

[![Hex.pm](https://img.shields.io/hexpm/v/together.svg)]()
[![Documentation](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/together)

Group actions that can be handled / responded to later together

## What for?

- group notifications to be sent in *one* email
    - cancel the previously queued email if another event happens within a short period (type: debounce)
- make heavy operations happen less often, i.e. refresh some global statistics
    - allow only 1 operation per certain period (type: throttle)
- protect some write api
    - additonally you can choose to use the first value in a period (keep: first)
    - or the last value in the period (keep: last)

## Installation

**Elixir 1.4 is required**

The package can be installed as:

Add `together` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:together, "~> 0.5"}]
end
```

## How to use

Start `Together.Supervisor` to use it

- Start with application configs

```elixir
supervisor(Together.Supervisor, [])
```

- Start with configs passed in

```elixir
supervisor(Together.Supervisor, [workers: ..., store: ...])
```

See `Together.Supervisor` for full configuration information

Make calls to the worker process:

```elixir
Together.process(binary_name, "something_unique", some_func)
Together.process(pid, "some_unique_name_or_id", a_function)
Together.process(Together.Worker, "id", Module, :func, [arg1, arg2, ...])
```

## More ideas

- keep: all (seems to be touching `gen_stage` territory)
