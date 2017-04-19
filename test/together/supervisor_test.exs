defmodule TogetherSupervisorTest do
  use ExUnit.Case, async: true

  @test_store Together.TestSupervisor.Store

  setup_all do
    {:ok, sup} = Together.Supervisor.start_link(
      workers: [],
      store: [
        name: @test_store,
        shards_name: Together.TestSupervisor.Shards
      ]
    )

    [supervisor: sup]
  end

  test "it works", %{supervisor: sup} do
    start_child(sup, name: "simple", delay: 100, type: :debounce)

    test_process = self()
    Enum.map(1..5, &Together.process(
      gen_name("simple"),
      "test",
      fn -> send test_process, &1 end
    ))

    refute_receive 1
    refute_receive 2
    refute_receive 3
    refute_receive 4
    assert_receive 5
  end

  test "it works with multiple workers", %{supervisor: sup} do
    start_child(sup, name: "one", delay: 100, type: :debounce)
    start_child(sup, name: "two", delay: 100, type: :debounce)

    test_process = self()
    Together.process(gen_name("one"), "test1", fn -> send test_process, 1 end)
    Together.process(gen_name("two"), "test2", fn -> send test_process, 2 end)

    assert_receive 1
    assert_receive 2
  end

  defp start_child(sup, spec) do
    specs = Together.Supervisor.parse_worker_spec(spec, @test_store)
    Enum.each(specs, &Supervisor.start_child(sup, &1))
  end

  defp gen_name(name) do
    {:via, Registry, {Together.WorkerRegistry, name}}
  end
end
