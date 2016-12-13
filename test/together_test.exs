defmodule TogetherTest do
  use ExUnit.Case, async: true

  setup do
    {store_name, shards_name} = {rand_name(), rand_name()}

    {:ok, store} = Together.Store.start_link([name: shards_name], name: store_name)

    [store: store]
  end

  test "it groups jobs together", %{store: store} do
    {:ok, pid} = start_worker(store, delay: 100)

    slow_send(pid, 1..3, 45)

    assert_receive 3
  end

  test "it works through jobs", %{store: store} do
    {:ok, pid} = start_worker(store, delay: 100)

    slow_send(pid, 1..4, 45)

    assert_receive 3
    assert_receive 4
  end

  test "it keeps the first value", %{store: store} do
    {:ok, pid} = start_worker(store, delay: 100, keep: :first)

    slow_send(pid, 1..4, 45)

    assert_receive 1
    assert_receive 4
  end

  test "it renews delay", %{store: store} do
    {:ok, pid} = start_worker(store, delay: 100, renew: true)

    slow_send(pid, 1..4, 45)

    assert_receive 4
  end

  test "it works with different ids", %{store: store} do
    {:ok, pid} = start_worker(store, delay: 100, renew: true)

    slow_send(pid, 1..4, 45, "1")
    slow_send(pid, 1..5, 45, "2")

    assert_receive 4
    assert_receive 5
  end

  test "it works with multiple instances", %{store: store} do
    {:ok, pid1} = start_worker(store, delay: 100, renew: true)
    {:ok, pid2} = start_worker(store, delay: 100, renew: true)

    slow_send(pid1, 1..4, 45)
    slow_send(pid2, 1..5, 45)

    assert_receive 4
    assert_receive 5
  end

  @tag :cancel
  test "it cancels the jobs", %{store: store} do
    {:ok, pid} = start_worker(store, delay: 100)

    slow_send(pid, [1], 0, "cancel_success")
    result = Together.cancel(pid, "cancel_success")

    assert result == :ok
    refute_receive 1
  end

  @tag :cancel
  test "it returns error when fails to cancel a job", %{store: store} do
    {:ok, pid} = start_worker(store, delay: 100)

    result = Together.cancel(pid, "cancel_failure")

    assert result == :error
  end

  defp start_worker(store, opts) do
    worker_name = rand_name()
    {:ok, proxy_pid} = Together.Proxy.start_link(worker_name)
    Together.Worker.start_link([store: store, proxy: proxy_pid] ++ opts, name: worker_name)
  end

  defp slow_send(pid, range, delay, id \\ rand_name()) do
    test_process = self()

    Enum.each(
      range,
      fn x ->
        Process.sleep(delay)
        Together.process(
          pid,
          id,
          fn -> send(test_process, x) end
        )
      end
    )
  end

  defp rand_name do
    16 |> :crypto.strong_rand_bytes |> Base.encode64 |> String.to_atom
  end
end
