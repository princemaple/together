defmodule Together.Supervisor.Default do
  use Supervisor

  alias Together.{Worker, Proxy, Store}

  def start_link(:config) do
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
    {[name: store_name], workers} =
      {Keyword.get(opts, :store, [name: Store]),
       Keyword.get(opts, :workers, [])}

    List.flatten([
      worker(Store, [[name: store_name], [name: {:global, store_name}]]),
      Enum.map(workers, &parse_worker_spec(&1, store_name))
    ])
  end

  defp parse_worker_spec(worker_spec, store_name) do
    %{name: name, proxy_name: proxy_name, opts: opts} = Enum.into(worker_spec, %{})

    [
      worker(Proxy, [name, [name: proxy_name]]),
      worker(Worker, [
        [store: {:global, store_name}, proxy: proxy_name] ++ opts,
        [name: name]
      ])
    ]
  end
end
