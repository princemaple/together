defmodule Together do
  @moduledoc ~S"""
  Group actions that need to be performed later together

  ## What for?

  - group notifications before sending an email about them
  - only sending the very last value of a fast changing entity (renew: true)
  - only using the very first value of a changing entity in every fixed period (renew: false)

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
  """

  @spec process(atom | pid, term, fun) :: :ok | no_return
  def process(pid \\ Together.Worker, id, func) do
    GenServer.call(pid, {:process, id, func})
  end

  @spec process(atom | pid, term, module, atom, list) :: :ok | no_return
  def process(pid \\ Together.Worker, id, m, f, a) do
    GenServer.call(pid, {:process, id, {m, f, a}})
  end
end
