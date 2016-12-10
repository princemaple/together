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
    GenServer.start_link(Together.Worker, opts, gen_server_opts)
  end

  def init(opts) do
    {:ok, {Enum.into(opts, @default_opts), %{}}}
  end

  def handle_call({:process, id, action}, _from, {config, buffer}) do
    {:reply, :ok, {config, update(buffer, id, action, config)}}
  end

  defp update(buffer, id, action, config) do
    record =
      with %{^id => record} <- buffer do
        update_record(record, id, action, config)
      else
        _ ->
          {[action], Process.send_after(self(), {:proceed, id}, config.delay)}
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
  defp update_ref(ref, id, %{renew: true, delay: delay}) do
    Process.cancel_timer(ref)
    Process.send_after(self(), {:proceed, id}, delay)
  end

  def handle_info({:proceed, id}, {config, buffer}) do
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
