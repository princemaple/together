defmodule Together do
  @moduledoc ~S"""
  Group actions that need to be performed later together

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
  """

  @spec process(atom | pid, term, fun) ::
    {:ok, pid} | :ignore | {:error, {:already_started, pid} | term}
  def process(pid \\ Together.Server, id, func) do
    GenServer.call(pid, {:process, id, func})
  end

  @spec process(atom | pid, term, module, atom, list) ::
    {:ok, pid} | :ignore | {:error, {:already_started, pid} | term}
  def process(pid \\ Together.Server, id, m, f, a) do
    GenServer.call(pid, {:process, id, {m, f, a}})
  end
end
