defmodule FsWatchAdapter do
  use GenServer

  def start_link(dir) do
    GenServer.start_link(__MODULE__, dir)
  end

  def init(dir) do
    state = %{
      port: nil,
      dir: dir
    }
    {:ok, state, {:continue, :start_fswatch}}
  end

  def handle_continue(:start_fswatch, state = %{dir: dir}) do
    cmd = "fswatch #{dir}"
    port = Port.open({:spawn, cmd}, [:binary, :exit_status])
    state = Map.put(state, :port, port)
    {:noreply, state}
  end

  def handle_info({port, {:data, msg}}, state) do
    IO.puts "Received message from port: #{msg}"
    {:noreply, state}
  end
end
