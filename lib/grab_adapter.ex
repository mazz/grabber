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
    :ets.insert(:chunk_lookup, {ytchannel, ""}) # start off with empty string


    # :ets.lookup_element(:chunk_lookup, "chunk", 2)

    {:ok, state, {:continue, :start_grabbing}}
  end

  def handle_continue(:start_grabbing, state = %{ytchannel: ytchannel}) do
    # "python metadatagrabber.py ytchanneldata https://www.youtube.com/channel/UCMCMaXiCRuervjaVe7_gf8w"
    # da lata "https://www.youtube.com/channel/UCIlFrdZCFUPlvlbgdyu1xdQ"

    # GrabAdapter.start_link("https://www.youtube.com/channel/UCMCMaXiCRuervjaVe7_gf8w")
    # GrabAdapter.start_link("https://www.youtube.com/channel/UCIlFrdZCFUPlvlbgdyu1xdQ")
    # GrabAdapter.start_link("https://www.youtube.com/channel/UCMCMaXiCRuervjaVe7_gf8w")

    # GrabAdapter.start_link("https://www.youtube.com/channel/UC47eUBNO8KBH_V8AfowOWOw")

    cmd = "python metadatagrabber.py ytchanneldata #{ytchannel}"
    port = Port.open({:spawn, cmd}, [:binary, :exit_status])
    state = Map.put(state, :port, port)

    {:noreply, state}
  end

  def handle_info({port, {:exit_status, exit_status}}, state) do
    IO.puts "Received exit_status from port: #{exit_status}"

    ytchannel = Map.get(state, :ytchannel)

    :ets.delete(:chunk_lookup, ytchannel)
    :ets.delete(:chunk_lookup)

    {:noreply, state}
  end

  def handle_info({port, {:data, msg}}, state) do
    # IO.puts "Received message from port: #{msg}"

    # {:ok, video} = Jaxon.decode(~s(#{msg}))

    ytchannel = Map.get(state, :ytchannel)

    # fragment = @partial
    fragment = :ets.lookup_element(:chunk_lookup, ytchannel, 2)
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

    # IO.puts "intermediate: #{intermediate}"

    video = %{}

    # intermediate = building_string #Enum.join(building_string,"")
    case Jason.decode(intermediate) do
      {:ok, _} ->
        stream = [~s(#{intermediate})]
        title = stream |> Jaxon.Stream.from_enumerable() |> Jaxon.Stream.query([:root, "title"]) |> Enum.to_list() |> List.flatten() |> List.first()
        video = Map.put(video, "title", title)
        # IO.puts "title:"
        # IO.inspect(title)

        channel_url = stream |> Jaxon.Stream.from_enumerable() |> Jaxon.Stream.query([:root, "channel_url"]) |> Enum.to_list() |> List.flatten() |> List.first()
        video = Map.put(video, "channel", channel_url)
        # IO.puts "channel_url:"
        # IO.inspect(channel_url)

        webpage_url = stream |> Jaxon.Stream.from_enumerable() |> Jaxon.Stream.query([:root, "webpage_url"]) |> Enum.to_list() |> List.flatten() |> List.first()
        video = Map.put(video, "webpage_url", webpage_url)
        # IO.puts "webpage_url:"
        # IO.inspect(webpage_url)

        uploader = stream |> Jaxon.Stream.from_enumerable() |> Jaxon.Stream.query([:root, "uploader"]) |> Enum.to_list() |> List.flatten() |> List.first()
        video = Map.put(video, "uploader", uploader)
        # IO.puts "uploader:"
        # IO.inspect(uploader)

        upload_date = stream |> Jaxon.Stream.from_enumerable() |> Jaxon.Stream.query([:root, "upload_date"]) |> Enum.to_list() |> List.flatten() |> List.first()

        year = String.slice(upload_date, 0..3)
        month = String.slice(upload_date, 4..5)
        day = String.slice(upload_date, 6..7)

        # NaiveDateTime.from_iso8601("2015-01-23 23:50:07")

        {:ok, datetime} = NaiveDateTime.from_iso8601("#{year}-#{month}-#{day} 00:00:00")
        video = Map.put(video, "upload_date", datetime)

        # IO.puts "upload_date:"
        # IO.inspect(upload_date)

        uploader_url = stream |> Jaxon.Stream.from_enumerable() |> Jaxon.Stream.query([:root, "uploader_url"]) |> Enum.to_list() |> List.flatten() |> List.first()
        video = Map.put(video, "uploader_url", uploader_url)
        # IO.puts "uploader_url:"
        # IO.inspect(uploader_url)

        thumbnails = stream |> Jaxon.Stream.from_enumerable() |> Jaxon.Stream.query([:root, "thumbnails", :all]) |> Enum.to_list() |> List.flatten() |> List.first()
        video = Map.put(video, "thumbnail_url", Map.get(thumbnails, "url"))
        # IO.puts "thumbnails:"
        # IO.inspect(Map.get(thumbnails, "url"))

        description = stream |> Jaxon.Stream.from_enumerable() |> Jaxon.Stream.query([:root, "description"]) |> Enum.to_list() |> List.flatten() |> List.first()
        video = Map.put(video, "description", description)
        # IO.puts "description:"
        # IO.inspect(description)

        categories = stream |> Jaxon.Stream.from_enumerable() |> Jaxon.Stream.query([:root, "categories"]) |> Enum.to_list() |> List.flatten()
        video = Map.put(video, "categories", categories)
        # IO.puts "categories:"
        # IO.inspect(categories)

        license = stream |> Jaxon.Stream.from_enumerable() |> Jaxon.Stream.query([:root, "license"]) |> Enum.to_list() |> List.flatten() |> List.first()
        video = Map.put(video, "license", license)
        # IO.puts "license:"
        # IO.inspect(license)

        duration = stream |> Jaxon.Stream.from_enumerable() |> Jaxon.Stream.query([:root, "duration"]) |> Enum.to_list() |> List.flatten() |> List.first()
        video = Map.put(video, "duration", duration)
        # IO.puts "duration:"
        # IO.inspect(duration)

        tags = stream |> Jaxon.Stream.from_enumerable() |> Jaxon.Stream.query([:root, "tags"]) |> Enum.to_list() |> List.flatten()
        video = Map.put(video, "tags", tags)
        # IO.puts "tags:"
        # IO.inspect(tags)

        id = stream |> Jaxon.Stream.from_enumerable() |> Jaxon.Stream.query([:root, "id"]) |> Enum.to_list() |> List.flatten() |> List.first()
        video = Map.put(video, "id", id)
        # IO.puts "id:"
        # IO.inspect(id)

        view_count = stream |> Jaxon.Stream.from_enumerable() |> Jaxon.Stream.query([:root, "view_count"]) |> Enum.to_list() |> List.flatten() |> List.first()
        video = Map.put(video, "view_count", view_count)
        # IO.puts "view_count:"
        # IO.inspect(view_count)

        like_count = stream |> Jaxon.Stream.from_enumerable() |> Jaxon.Stream.query([:root, "like_count"]) |> Enum.to_list() |> List.flatten() |> List.first()
        video = Map.put(video, "like_count", like_count)
        # IO.puts "like_count:"
        # IO.inspect(like_count)

        dislike_count = stream |> Jaxon.Stream.from_enumerable() |> Jaxon.Stream.query([:root, "dislike_count"]) |> Enum.to_list() |> List.flatten() |> List.first()
        video = Map.put(video, "dislike_count", dislike_count)
        # IO.puts "dislike_count:"
        # IO.inspect(dislike_count)

        IO.inspect(video)

        # @partial = ""
        :ets.insert(:chunk_lookup, {ytchannel, ""})
        # state = Map.put(state, "chunk", "")


      {:error, _} ->
        IO.puts "there was an error decoding intermediate"

        # @partial = building_string
        :ets.insert(:chunk_lookup, {ytchannel, intermediate})
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
