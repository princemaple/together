defmodule TogetherTest do
  use ExUnit.Case, async: true

  setup_all do
    Registry.start_link(:unique, WorkerRegistry)
    {:ok, store} = Together.Store.start_link

    [store: store]
  end

  test "it groups jobs together", %{test: test, store: store} do
    {:ok, pid} = start_worker(test, store, delay: 100)

    slow_send(pid, 1..3, 45)

    refute_receive 1
    refute_receive 2
    assert_receive 3
  end

  test "it throttles jobs", %{test: test, store: store} do
    {:ok, pid} = start_worker(test, store, delay: 100)

    slow_send(pid, 1..4, 45)

    refute_receive 1
    refute_receive 2
    assert_receive 3
    assert_receive 4
  end

  test "it keeps the first value", %{test: test, store: store} do
    {:ok, pid} = start_worker(test, store, delay: 100, keep: :first)

    slow_send(pid, 1..4, 45)

    assert_receive 1
    refute_receive 2
    refute_receive 3
    assert_receive 4
  end

  test "it debounces jobs", %{test: test, store: store} do
    {:ok, pid} = start_worker(test, store, delay: 100, type: :debounce)

    slow_send(pid, 1..4, 45)

    refute_receive 1
    refute_receive 2
    refute_receive 3
    assert_receive 4
  end

  test "it works with different ids", %{test: test, store: store} do
    {:ok, pid} = start_worker(test, store, delay: 100, type: :debounce)

    slow_send(pid, 1..4, 45, "1")
    slow_send(pid, 5..8, 45, "2")

    refute_receive 1
    refute_receive 2
    refute_receive 3
    assert_receive 4

    refute_receive 5
    refute_receive 6
    refute_receive 7
    assert_receive 8
  end

  test "it works with multiple instances", %{test: test, store: store} do
    {:ok, pid1} = start_worker(test, store, delay: 100, type: :debounce)
    {:ok, pid2} = start_worker(test, store, delay: 100, type: :debounce)

    slow_send(pid1, 1..4, 45, "1")
    slow_send(pid2, 5..8, 45, "2")

    refute_receive 1
    refute_receive 2
    refute_receive 3
    assert_receive 4

    refute_receive 5
    refute_receive 6
    refute_receive 7
    assert_receive 8
  end

  test "it works with mfa", %{test: test, store: store} do
    {:ok, pid} = start_worker(test, store, delay: 100)

    Together.process(pid, "mfa", Process, :send, [self(), :mfa, []])

    assert_receive :mfa
  end

  @tag :cancel
  test "it cancels the jobs", %{test: test, store: store} do
    {:ok, pid} = start_worker(test, store, delay: 100)

    slow_send(pid, [1], 0, "cancel_success")
    result = Together.cancel(pid, "cancel_success")

    assert result == :ok
    refute_receive 1
  end

  @tag :cancel
  test "it returns error when fails to cancel a job", %{test: test, store: store} do
    {:ok, pid} = start_worker(test, store, delay: 100)

    result = Together.cancel(pid, "cancel_failure")

    assert result == :error
  end

  defp start_worker(test, store, opts) do
    worker_name = {:via, Registry, {WorkerRegistry, test}}
    {:ok, proxy_pid} = Together.Proxy.start_link(worker_name)
    Together.Worker.start_link([store: store, proxy: proxy_pid] ++ opts, name: worker_name)
  end

  defp slow_send(pid, range, delay, id \\ :crypto.strong_rand_bytes(16)) do
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
end
