defmodule GrabAdapter do
  use GenServer

  import Jaxon
  import Jason

  # @partial ""

  def start_link(ytchannel) do
    GenServer.start_link(__MODULE__, ytchannel)
  end

  def init(ytchannel) do
    state = %{
      port: nil,
      ytchannel: ytchannel
    }

    :ets.new(:chunk_lookup, [:set, :protected, :named_table])
    :ets.insert(:chunk_lookup, {"chunk", ""}) # start off with empty string


    # :ets.lookup_element(:chunk_lookup, "chunk", 2)

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

    :ets.delete(:chunk_lookup, "chunk")
    :ets.delete(:chunk_lookup)

    {:noreply, state}
  end

  def handle_info({port, {:data, msg}}, state) do
    # IO.puts "Received message from port: #{msg}"

    # {:ok, video} = Jaxon.decode(~s(#{msg}))

    # fragment = @partial
    fragment = :ets.lookup_element(:chunk_lookup, "chunk", 2)
    # fragment = Map.get(state, "chunk")


    # try do
    #   decoded = Jason.decode!(~s(#{msg}))
    # catch
    #   :error, _ ->
    #     IO.puts "there was an error decoding msg"
    #     building_list = [fragment | msg]
    #   {:error, message} -> IO.puts "there was an error: #{message}"
    # end

    intermediate = "#{fragment}#{msg}" # Enum.concat(fragment, msg) #[fragment | msg]

    IO.puts "intermediate: #{intermediate}"

    # intermediate = building_string #Enum.join(building_string,"")
    case Jason.decode(intermediate) do
      {:ok, _} ->
        stream = [~s(#{intermediate})]
        title =
          stream |> Jaxon.Stream.from_enumerable() |> Jaxon.Stream.query([:root, "title"]) |> Enum.to_list()
          IO.puts "title: #{title}"

        # @partial = ""
        :ets.insert(:chunk_lookup, {"chunk", ""})
        # state = Map.put(state, "chunk", "")


      {:error, _} ->
        IO.puts "there was an error decoding intermediate"

        # @partial = building_string
        :ets.insert(:chunk_lookup, {"chunk", intermediate})
        # state = Map.put(state, "chunk", intermediate)

    end

    # Jason.decode("{}")
    # {:ok, %{}}

    # Jason.decode("invalid")
    # {:error, %Jason.DecodeError{data: "invalid", position: 0, token: nil}}
    # fulltitle = Map.get(decoded, "fulltitle")
    # IO.puts "fulltitle: #{fulltitle}"

    # stream = [~s(#{msg})]

    # try do
    #   title =
    #   stream |> Jaxon.Stream.from_enumerable() |> Jaxon.Stream.query([:root, "title"]) |> Enum.to_list()
    #   IO.puts "title: #{title}"
    # catch
    #   :error, _ -> IO.puts "there was an error with no message"
    #   {:error, message} -> IO.puts "there was an error: #{message}"
    # end

    # stream |> Jaxon.Stream.from_enumerable() |> Jaxon.Stream.query(Jaxon.Path.parse!("$.title")) |> Enum.to_list()
    # fulltitle =
    #   stream
    #   |> Jaxon.Stream.from_enumerable()
    #   |> Jaxon.Stream.query([:root, "fulltitle"])
    #   |> Enum.to_list()
    {:noreply, state}
  end
end
