defmodule Together do
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
