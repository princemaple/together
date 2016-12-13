defmodule Together.Global do
  defmacro __using__(:start_link) do
    quote do
      @spec start_link(keyword, keyword) :: {:ok, pid}
      def start_link(opts \\ [], gen_server_opts \\ []) do
        case GenServer.start(__MODULE__, opts, gen_server_opts) do
          {:ok, pid} ->
            {:ok, pid}
          {:error, {:already_started, pid}} ->
            Process.link(pid)
            {:ok, pid}
        end
      end
    end
  end
end
