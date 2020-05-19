defmodule GrabAdapter do
  use GenServer

  import Jaxon
  import Jason

  def start_link(dir) do
    GenServer.start_link(__MODULE__, dir)
  end

  def init(ytchannel) do
    state = %{
      port: nil,
      ytchannel: ytchannel
    }
    {:ok, state, {:continue, :start_grabbing}}
  end

  def handle_continue(:start_grabbing, state = %{ytchannel: ytchannel}) do
    # "python metadatagrabber.py ytchanneldata https://www.youtube.com/channel/UCMCMaXiCRuervjaVe7_gf8w"
    # da lata "https://www.youtube.com/channel/UCIlFrdZCFUPlvlbgdyu1xdQ"

    cmd = "python metadatagrabber.py ytchanneldata #{ytchannel}"
    port = Port.open({:spawn, cmd}, [:binary, :exit_status])
    state = Map.put(state, :port, port)

    {:noreply, state}
  end

  def handle_info({port, {:exit_status, exit_status}}, state) do
    IO.puts "Received exit_status from port: #{exit_status}"
    {:noreply, state}
  end

  def handle_info({port, {:data, msg}}, state) do
    IO.puts "Received message from port: #{msg}"

    # {:ok, video} = Jaxon.decode(~s(#{msg}))

    try do
      decoded = Jason.decode!(~s(#{msg}))
    catch
      :error, _ -> IO.puts "there was an error decoding JSON"
      {:error, message} -> IO.puts "there was an error: #{message}"
    end

    # fulltitle = Map.get(decoded, "fulltitle")
    # IO.puts "fulltitle: #{fulltitle}"

    stream = [~s(#{msg})]

    try do
      title =
      stream |> Jaxon.Stream.from_enumerable() |> Jaxon.Stream.query([:root, "title"]) |> Enum.to_list()
      IO.puts "title: #{title}"
    catch
      :error, _ -> IO.puts "there was an error with no message"
      {:error, message} -> IO.puts "there was an error: #{message}"
    end

    # stream |> Jaxon.Stream.from_enumerable() |> Jaxon.Stream.query(Jaxon.Path.parse!("$.title")) |> Enum.to_list()
    # fulltitle =
    #   stream
    #   |> Jaxon.Stream.from_enumerable()
    #   |> Jaxon.Stream.query([:root, "fulltitle"])
    #   |> Enum.to_list()
    {:noreply, state}
  end
end
