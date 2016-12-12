defmodule TogetherTest do
  use ExUnit.Case, async: true

  test "it groups jobs together" do
    {:ok, pid} = Together.Worker.start_link(delay: 100)

    slow_send(self(), pid, 1..3, 45)

    assert_receive 3
  end

  test "it works through jobs" do
    {:ok, pid} = Together.Worker.start_link(delay: 100)

    slow_send(self(), pid, 1..4, 45)

    assert_receive 3
    assert_receive 4
  end

  test "it keeps the first value" do
    {:ok, pid} = Together.Worker.start_link(delay: 100, keep: :first)

    slow_send(self(), pid, 1..4, 45)

    assert_receive 1
    assert_receive 4
  end

  test "it renews delay" do
    {:ok, pid} = Together.Worker.start_link(delay: 100, renew: true)

    slow_send(self(), pid, 1..4, 45)

    assert_receive 4
  end

  test "it works with different ids" do
    {:ok, pid} = Together.Worker.start_link(delay: 100, renew: true)

    slow_send(self(), pid, 1..4, 45, "1")
    slow_send(self(), pid, 1..5, 45, "2")

    assert_receive 4
    assert_receive 5
  end

  test "it works with multiple instances" do
    {:ok, pid1} = Together.Worker.start_link(delay: 100, renew: true)
    {:ok, pid2} = Together.Worker.start_link(delay: 100, renew: true)

    slow_send(self(), pid1, 1..4, 45)
    slow_send(self(), pid2, 1..5, 45)

    assert_receive 4
    assert_receive 5
  end

  test "it cancels the jobs" do
    {:ok, pid} = Together.Worker.start_link(delay: 100, renew: true)

    slow_send(self(), pid, [1], 0, "id")
    Together.cancel(pid, "id")

    refute_receive 1
  end

  defp slow_send(test_process, pid, range, delay, id \\ "id") do
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
