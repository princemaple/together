defmodule Together.Proxy do
  use GenServer
  use Together.Global, :start_link

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
