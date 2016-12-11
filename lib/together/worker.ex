defmodule Together.Worker do
  use GenServer

  @moduledoc ~S"""
  Together.Worker can be started with the following options:

  - `keep: :first | :last | :all`
  - `delay: integer`
  - `renew: boolean`
  """

  @default_opts %{
    keep: :last,
    delay: 60_000,
    renew: false,
    count: false
  }

  def start_link(opts \\ [], gen_server_opts \\ []) do
    case GenServer.start_link(
      __MODULE__,
      proxy_name(opts, gen_server_opts),
      gen_server_opts
    ) do
      {:ok, pid} ->
        {:ok, pid}
      {:error, {:already_started, pid}} ->
        Process.link(pid)
        {:ok, pid}
    end
  end

  defp proxy_name(opts, gen_server_opts) do
    case Keyword.fetch(gen_server_opts, :name) do
      {:ok, name} ->
        [{:name, name} | opts]
      :error ->
        opts
    end
  end

  def init(opts) do
    opts =
      with [{:name, name} | _rest] <- opts do
        [{:proxy, Together.Proxy.start(name)} | opts]
      else
        _ -> [{:proxy, Together.Proxy.start(self())} | opts]
      end

    {:ok, {Enum.into(opts, @default_opts), %{}}}
  end

  def handle_call({:process, id, action}, _from, {config, buffer}) do
    {:reply, :ok, {config, update(buffer, id, action, config)}}
  end

  defp update(buffer, id, action, %{proxy: proxy, delay: delay} = config) do
    record =
      with %{^id => record} <- buffer do
        update_record(record, id, action, config)
      else
        _ ->
          {[action], Together.Proxy.queue(proxy, id, delay)}
      end

    Map.put(buffer, id, record)
  end

  defp update_record({actions, ref}, id, action, config) do
    {update_actions(actions, action, config), update_ref(ref, id, config)}
  end

  defp update_actions(actions, _action, %{keep: :first}), do: actions
  defp update_actions(_actions, action, %{keep: :last}), do: [action]
  defp update_actions(actions, action, %{keep: :all}), do: [action | actions]

  defp update_ref(ref, _id, %{renew: false}), do: ref
  defp update_ref(ref, id, %{renew: true, delay: delay, proxy: proxy}) do
    Process.cancel_timer(ref)
    Together.Proxy.queue(proxy, id, delay)
  end

  def handle_cast({:proceed, id}, {config, buffer}) do
    {{actions, _ref}, buffer} = Map.pop(buffer, id)

    actions
    |> Enum.reverse
    |> Enum.each(fn
      {m, f, a} -> Task.start(m, f, a)
      func -> Task.start(func)
    end)

    {:noreply, {config, buffer}}
  end
end
