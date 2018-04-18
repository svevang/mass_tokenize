defmodule FileListProducer do
  use GenStage

  def start_link(path) do
    GenStage.start_link(__MODULE__, path, name: __MODULE__)
  end

  def init(path) do

    file_list = gather_tree(path, [])
    |> List.flatten

    {:producer, file_list}
  end

  def handle_demand(demand, file_list) do

    work_batch = Enum.take(file_list, demand)
    file_list = Enum.drop(file_list, demand)

    {:noreply, work_batch, file_list}
  end

  def gather_tree(dir, results) do
    Enum.map(File.ls!(dir), fn file ->
      fname = Path.join([dir, file])

      if File.dir?(fname) do
        gather_tree(fname, results)
      else
        [ fname | results ]
      end

    end)
  end
end

defmodule FileReaderConsumer do
  use GenStage

  def start_link(:ok) do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    {:producer_consumer, []}
  end

  def handle_events(file_paths, _from, state) do
    files = file_paths
            |> Enum.map(fn(path)-> FileReader.read_file(path) end)
    {:noreply, files, state}
  end
end

defmodule TokenizerConsumer do
  use GenStage

  def start_link(wikiextractor_json: json_lines) do
    GenStage.start_link(__MODULE__, wikiextractor_json: json_lines)
  end

  # Callbacks

  def init(wikiextractor_json: json_lines) do
    {:producer_consumer, [wikiextractor_json: json_lines]}
  end

  def handle_events(files, _from, state) do
    token_lists = files
    |> Enum.map(fn(s) -> tokenize(s, state[:wikiextractor_json]) end)
    {:noreply, token_lists, state}
  end

  def tokenize(str, is_json) do
    if is_json do
      TokenizeWikiExtractorJson.parse_json(str)
    else
      TokenizeText.do_tokenize(str)
    end
  end

end

defmodule ResultConsumer do
  use GenStage

  def start_link(:ok) do
    GenStage.start_link(__MODULE__, :ok)
  end

  # Callbacks

  def init(:ok) do
    {:consumer, []}
  end

  def handle_events(results, _from, state) do
      results
      |> Enum.map(fn(r) -> StdoutWriter.do_write(r) end)
    {:noreply, [], state}
  end
end


defmodule MassTokenize do
  @num_file_workers 2
  @num_tok_workers 9

  def init([path: dir, wikiextractor_json: json_lines]) do
    import Supervisor.Spec

    {:ok, file_producer} = GenStage.start_link(FileListProducer, [dir])

    file_readers = 1..@num_file_workers
                     |> Enum.map(fn(_)-> 
                       {:ok, file_reader} = GenStage.start_link(FileReaderConsumer, :ok)
                       file_reader
                     end)

    tokenizers = 1..@num_tok_workers
    |> Enum.map(fn(i) ->
      reader = Enum.at(file_readers, rem(i, @num_file_workers))
      {:ok, tokenize_consumer} = GenStage.start_link(TokenizerConsumer, wikiextractor_json: json_lines)
      GenStage.sync_subscribe(tokenize_consumer, to: reader, min_demand: 1, max_demand: 10)
      {:ok, printer} = GenStage.start_link(ResultConsumer, :ok)
      GenStage.sync_subscribe(printer, to: tokenize_consumer)
      tokenize_consumer
    end)

    file_readers
    |> Enum.map(fn(file_reader)-> 
      GenStage.sync_subscribe(file_reader, to: file_producer, min_demand: 1, max_demand: 2)
    end)

    Process.sleep(:infinity)

    #Supervisor.start_link(children, strategy: :one_for_one)
  end

end
