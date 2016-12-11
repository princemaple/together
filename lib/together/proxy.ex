defmodule Together.Proxy do
  use GenServer

  def start(worker, gen_server_opts \\ []) do
    case GenServer.start(
      __MODULE__,
      worker,
      gen_server_opts
    ) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  def queue(pid \\ __MODULE__, id, delay) do
    GenServer.call(pid, {:queue, id, delay})
  end

  def init(worker) do
    {:ok, worker}
  end

  def handle_call({:queue, id, delay}, _from, worker) do
    {:reply, Process.send_after(self(), {:trigger, id}, delay), worker}
  end

  def handle_info({:trigger, id}, worker) do
    GenServer.cast(worker, {:proceed, id})
    {:noreply, worker}
  end
end
