defmodule MassTokenize do
  @moduledoc """
  Documentation for MassTokenize.
  """

  require Logger
  import ExProf.Macro

  def run_queues(file_reader_scheduler, wiki_extractor_tokenizer) do
    receive do
      {:answer, FileReader, result} ->
        Logger.info("[MassTokenize] answer from FileReader #{String.slice(result, 1..120)}")
        send wiki_extractor_tokenizer, {:push_queue, result}
        run_queues(file_reader_scheduler, wiki_extractor_tokenizer)
      {:answer, TokenizeWikiExtractorJson, result} ->
        Logger.info("[MassTokenize] answer from TokenizeWikiExtractorJson #{inspect(result)}")
        run_queues(file_reader_scheduler, wiki_extractor_tokenizer)
      {:queue_drain, TokenizeWikiExtractorJson} ->
        Logger.info("[MassTokenize] queue drain from TokenizeWikiExtractorJson")
      {:queue_drain, FileReader} ->
        Logger.info("[MassTokenize] queue drain from FileReader")
        run_queues(file_reader_scheduler, wiki_extractor_tokenizer)
    end
  end

  def tokenize_text_files([path: dir, wikiextractor_json: json_lines]) do

    file_list = gather_tree(dir, [])
    |> List.flatten

    file_reader_scheduler = InteractingScheduler.run(self(), 4, FileReader, :read_text, file_list)
    wiki_extractor_tokenizer = InteractingScheduler.run(self(), 16, TokenizeWikiExtractorJson, :parse_string, [])

    run_queues(file_reader_scheduler, wiki_extractor_tokenizer)
  end

  def gather_tree(dir, results) do
    Enum.map(File.ls!(dir), fn file ->
      fname = Path.join([dir, file])

      if File.dir?(fname) do
        gather_tree(fname, results)
      else
        [ fname |results ]
      end

    end)
  end

end
