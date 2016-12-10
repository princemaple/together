defmodule TogetherTest do
  use ExUnit.Case, async: true

  test "it groups jobs together" do
    {:ok, pid} = Together.start_link(delay: 100)

    slow_send(self(), pid, 1..3, 45)

    assert_receive 3
  end

  test "it works through jobs" do
    {:ok, pid} = Together.start_link(delay: 100)

    slow_send(self(), pid, 1..4, 45)

    assert_receive 3
    assert_receive 4
  end

  test "it renews delay" do
    {:ok, pid} = Together.start_link(delay: 100, renew: true)

    slow_send(self(), pid, 1..4, 45)

    assert_receive 4
  end

  test "it works with different ids" do
    {:ok, pid} = Together.start_link(delay: 100, renew: true)

    slow_send(self(), pid, 1..4, 45, "1")
    slow_send(self(), pid, 1..5, 45, "2")

    assert_receive 4
    assert_receive 5
  end

  test "it works with multiple instances" do
    {:ok, pid1} = Together.start_link(delay: 100, renew: true)
    {:ok, pid2} = Together.start_link(delay: 100, renew: true)

    slow_send(self(), pid1, 1..4, 45)
    slow_send(self(), pid2, 1..5, 45)

    assert_receive 4
    assert_receive 5
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
