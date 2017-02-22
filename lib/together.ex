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
  worker(Together.Worker, [[delay: 3000, type: :debounce], [name: Together.Worker]])
  ```

  Or start it as you would any other GenServer

  ```elixir
  {:ok, pid} = Together.Worker.start_link(delay: 30_000, type: :throttle)
  ```

  Make calls to the worker process:

  - `Together.process(binary_name, "somethiny_unique", some_func)`
  - `Together.process(pid, "some_unique_name_or_id", a_function)`
  - `Together.process(Together.Worker, "id", Module, :func, [arg1, arg2, ...])`
  """

  @registry_name Together.WorkerRegistry

  @doc ~S"""
  put in a function under the id to be processed (invoked) later
  """
  @spec process(binary | GenServer.server, term, fun) :: :ok | no_return
  def process(name, id, func) when is_binary(name) do
    GenServer.call({:via, Registry, {@registry_name, name}}, {:process, id, func})
  end
  def process(server, id, func) do
    GenServer.call(server, {:process, id, func})
  end

  @doc ~S"""
  put in an `mfa` under the id to be processed (invoked/applied) later
  """
  @spec process(binary | GenServer.server, term, module, atom, list) :: :ok | no_return
  def process(name, id, m, f, a) when is_binary(name) do
    GenServer.call({:via, Registry, {@registry_name, name}}, {:process, id, {m, f, a}})
  end
  def process(server, id, m, f, a) do
    GenServer.call(server, {:process, id, {m, f, a}})
  end

  @doc ~S"""
  cancels queued action(s) for the given id
  """
  @spec cancel(binary | GenServer.server, term) :: :ok | :error
  def cancel(name, id) when is_binary(name) do
    GenServer.call({:via, Registry, {@registry_name, name}}, {:cancel, id})
  end
  def cancel(server, id) do
    GenServer.call(server, {:cancel, id})
  end
end
