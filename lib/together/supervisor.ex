defmodule Together.Supervisor do
  @moduledoc """
  Start with application configs

      supervisor(Together.Supervisor, [])

  Start with configs passed in

      supervisor(Together.Supervisor, [workers: ..., store: ...])

  ## Example config

      config :together,
        workers: [
          # name is required, can be anything, prefer strings
          [name: "throttled_job", delay: 30_000, type: :throttle],
          [name: "debounced_job", delay: 5_000, type: :debounce],
          [name: "keep_first_job", keep: :first],
          # etc
        ],
        # omissible, if you don't want to change anything
        store: [
          # name for the Store process
          name: MyApp.Together.Store,
          # name for the ExShards main process
          shards_name: MyApp.Together.Store.Shards,
          # for distributed ets
          scope: :g,
          # nodes in the cluster, will use `Node.list` if omitted
          nodes: [:"node2@172.18.0.3", :"node3@172.18.0.4"]
        ]

  or you could pass the configs into the `start_link/1` function directly
  """
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
    {store_opts, worker_definitions} =
      {Keyword.get(opts, :store, []),
       Keyword.get(opts, :workers, [])}

    {store_name, store_opts} = Keyword.pop(store_opts, :name, @store_name)

    List.flatten([
      worker(Registry, [:unique, @registry_name]),
      worker(Store, [store_opts, [name: store_name]]),
      Enum.map(worker_definitions, &parse_worker_spec(&1, store_name))
    ])
  end

  defp parse_worker_spec(worker_spec, store_name) do
    name = Keyword.fetch!(worker_spec, :name)
    proxy_name = {:via, Registry, {@registry_name, {:proxy, name}}}
    worker_name = {:via, Registry, {@registry_name, name}}

    [
      worker(Proxy, [worker_name, [name: proxy_name]], [id: make_ref()]),
      worker(Worker, [
        [store: store_name, proxy: proxy_name] ++ worker_spec,
        [name: worker_name]
      ], [id: make_ref()])
    ]
  end
end
