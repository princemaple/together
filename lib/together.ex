defmodule Together do
  @spec process(atom | pid, term, function)
  def process(pid \\ Together.Server, id, func) do
    GenServer.call(pid, {:process, id, func})
  end

  @spec process(atom | pid, term, atom, atom, list)
  def process(pid \\ Together.Server, id, m, f, a) do
    GenServer.call(pid, {:process, id, {m, f, a}})
  end
end
