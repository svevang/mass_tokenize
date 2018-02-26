defmodule MassTokenize do
  @moduledoc """
  Documentation for MassTokenize.
  """

  require Logger
  import ExProf.Macro

  def run_queues(file_reader_scheduler, wiki_extractor_tokenizer) do

    if InteractingScheduler.queue_drained?(file_reader_scheduler) and InteractingScheduler.queue_drained?(wiki_extractor_tokenizer) do
      exit(:normal)
    end

    file_reader_scheduler = InteractingScheduler.schedule_processes(file_reader_scheduler)
    wiki_extractor_tokenizer = InteractingScheduler.schedule_processes(wiki_extractor_tokenizer)

    file_reader_uid = file_reader_scheduler.uid
    wiki_extractor_uid = wiki_extractor_tokenizer.uid

    receive do
      {:answer, ^file_reader_uid, result, worker_pid} ->
        file_reader_scheduler = InteractingScheduler.receive_answer(file_reader_scheduler, result, worker_pid)
        Logger.debug("[MassTokenize] answer from FileReader #{file_reader_uid}")
        wiki_extractor_tokenizer = InteractingScheduler.push_queue(wiki_extractor_tokenizer, result)
        run_queues(file_reader_scheduler, wiki_extractor_tokenizer)
      {:answer, ^wiki_extractor_uid, result, worker_pid} ->
        wiki_extractor_tokenizer = InteractingScheduler.receive_answer(wiki_extractor_tokenizer, result, worker_pid)
        Logger.debug("[MassTokenize] answer from TokenizeWikiExtractorJson #{wiki_extractor_uid}")
        IO.puts(result)
        run_queues(file_reader_scheduler, wiki_extractor_tokenizer)
      anything ->
        Logger.debug("[MassTokenize] received #{inspect(anything)}")
        run_queues(file_reader_scheduler, wiki_extractor_tokenizer)
    end

  end

  def tokenize_text_files([path: dir, wikiextractor_json: json_lines]) do

    file_list = gather_tree(dir, [])
    |> List.flatten

    file_reader_scheduler = InteractingScheduler.run(self(), 1, FileReader, :read_text, file_list)
    wiki_extractor_tokenizer = InteractingScheduler.run(self(), 8, TokenizeWikiExtractorJson, :parse_string, [])

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
