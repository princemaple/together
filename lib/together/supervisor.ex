defmodule Together.Supervisor do
  use Supervisor

  @registry_name Together.WorkerRegistry
  @store_name Together.Store

  alias Together.{Worker, Proxy, Store}

  def start_link do
    start_link(Application.get_all_env(:together))
  end

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(opts) do
    children = parse_opts(opts)

    supervise(children, strategy: :one_for_one)
  end

  defp parse_opts(opts) do
    {shards_opts, worker_definitions} =
      {Keyword.get(opts, :shards, []),
       Keyword.get(opts, :workers, [])}

    List.flatten([
      worker(Registry, [:unique, @registry_name]),
      worker(Store, [shards_opts, [name: @store_name]]),
      Enum.map(worker_definitions, &parse_worker_spec(&1, @store_name))
    ])
  end

  defp parse_worker_spec(worker_spec, store_name) do
    %{name: name, opts: opts} = Enum.into(worker_spec, %{})
    proxy_name = {:via, Registry, {@registry_name, "#{name}_proxy"}}
    worker_name = {:via, Registry, {@registry_name, "#{name}_worker"}}

    [
      worker(Proxy, [name, [name: proxy_name]]),
      worker(Worker, [
        [store: store_name, proxy: proxy_name] ++ opts,
        [name: worker_name]
      ])
    ]
  end
end
