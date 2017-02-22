defmodule Together.Proxy do
  @moduledoc """
  Proxy is here to receive all the `Process.send_after` messages

  It offloads the message handling from worker, and makes sure
  that if the worker dies, the respawned worker will still get
  the messages, since Proxy calls Worker by name instead of pid

  If the Proxy dies, it will lose all the messages, but the Proxy is
  less likely to die than Worker, because it has basically no logic
  and no interaction with outside `Together`
  """
  use GenServer
  use Together.Global, :start_link

  @doc false
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
