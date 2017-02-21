defmodule Together.Store do
  use GenServer
  use Together.Global, :start_link

  @spec put(GenServer.server, term, term) :: :ok | no_return
  def put(server, key, value) do
    GenServer.call(server, {:put, key, value})
  end

  @spec get(GenServer.server, term) :: any
  def get(server, key) do
    GenServer.call(server, {:get, key})
  end

  @spec pop(GenServer.server, term) :: any
  def pop(server, key) do
    GenServer.call(server, {:pop, key})
  end

  @spec delete(GenServer.server, term) :: :ok
  def delete(server, key) do
    GenServer.cast(server, {:delete, key})
  end

  def init(opts) do
    {name, opts} = Keyword.pop(opts, :name, Together.Store.Shards)
    {:ok, ^name = ExShards.new(name, opts)}
  end

  def handle_call({:put, key, value}, _from, shards_name) do
    ExShards.put(shards_name, key, value)
    {:reply, :ok, shards_name}
  end

  def handle_call({:get, key}, _from, shards_name) do
    {:reply, ExShards.get(shards_name, key), shards_name}
  end

  def handle_call({:pop, key}, _from, shards_name) do
    value = ExShards.pop(shards_name, key)
    {:reply, value, shards_name}
  end

  def handle_cast({:delete, key}, shards_name) do
    true = ExShards.delete(shards_name, key)
    {:noreply, shards_name}
  end

  def terminate(_, shards_name) do
    with {:state, :shards_local, _, _, _} <- ExShards.state(shards_name) do
      true = ExShards.delete(shards_name)
    end
  end
end
