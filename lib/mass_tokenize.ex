defmodule MassTokenize do
  @moduledoc """
  Documentation for MassTokenize.
  """

  @num_file_workers 2
  @num_tok_workers 9

  require Logger
  import ExProf.Macro

  def print_result_list(results) do
    results
    |> Enum.uniq
    |> Enum.map(fn(s) -> [s, '\n'] end)
    |> IO.write
  end

  def finished?(file_reader_scheduler, tokenizer_scheduler, output_scheduler) do
    InteractingScheduler.queue_drained?(file_reader_scheduler) and InteractingScheduler.queue_drained?(tokenizer_scheduler) and InteractingScheduler.queue_drained?(output_scheduler)
  end

  def objective(file_reader_scheduler, tokenizer_scheduler) do
    if length(tokenizer_scheduler.queue) < (2 * @num_tok_workers) do
      file_reader_scheduler = InteractingScheduler.schedule_processes(file_reader_scheduler)
    end
    file_reader_scheduler
  end

  def run_queues(file_reader_scheduler, tokenizer_scheduler, output_scheduler) do

    if finished?(file_reader_scheduler, tokenizer_scheduler, output_scheduler) do
      exit(:normal)
    end

    # throttle the first step in the pipeline based on the subsequent step's queue length
    file_reader_scheduler = objective(file_reader_scheduler, tokenizer_scheduler)
    tokenizer_scheduler = InteractingScheduler.schedule_processes(tokenizer_scheduler)
    output_scheduler = InteractingScheduler.schedule_processes(output_scheduler)

    file_reader_uid = file_reader_scheduler.uid
    wiki_extractor_uid = tokenizer_scheduler.uid
    output_writer_uid = output_scheduler.uid

    receive do
      {:answer, ^file_reader_uid, result, worker_pid} ->
        Logger.debug("[MassTokenize] answer from FileReader #{file_reader_uid}")
        file_reader_scheduler = InteractingScheduler.receive_answer(file_reader_scheduler, result, worker_pid)

        tokenizer_scheduler = InteractingScheduler.push_queue(tokenizer_scheduler, result)
        run_queues(file_reader_scheduler, tokenizer_scheduler, output_scheduler)
      {:answer, ^wiki_extractor_uid, result, worker_pid} ->
        Logger.debug("[MassTokenize] answer from TokenizeWikiExtractorJson #{wiki_extractor_uid}")
        tokenizer_scheduler = InteractingScheduler.receive_answer(tokenizer_scheduler, result, worker_pid)

        output_scheduler = InteractingScheduler.push_queue(output_scheduler, result)
        run_queues(file_reader_scheduler, tokenizer_scheduler, output_scheduler)
      {:answer, ^output_writer_uid, result, worker_pid} ->
        Logger.debug("[MassTokenize] answer from OutputWriter #{output_writer_uid}")
        output_scheduler = InteractingScheduler.receive_answer(output_scheduler, result, worker_pid)

        run_queues(file_reader_scheduler, tokenizer_scheduler, output_scheduler)
      anything ->
        Logger.debug("[MassTokenize] received #{inspect(anything)}")
        run_queues(file_reader_scheduler, tokenizer_scheduler, output_scheduler)
    end

  end

  def start_tokenizer_scheduler(wikiextractor_json: false) do
    tokenizer_scheduler = InteractingScheduler.run(self(), @num_tok_workers, TokenizeText, :parse_string, [])
  end

  def start_tokenizer_scheduler(wikiextractor_json: true) do
    tokenizer_scheduler = InteractingScheduler.run(self(), @num_tok_workers, TokenizeWikiExtractorJson, :parse_string, [])
  end

  def tokenize_text_files([path: dir, wikiextractor_json: json_lines]) do

    file_list = gather_tree(dir, [])
    |> List.flatten

    file_reader_scheduler = InteractingScheduler.run(self(), @num_file_workers, FileReader, :read_text, file_list)
    tokenizer_scheduler = start_tokenizer_scheduler(wikiextractor_json: json_lines)
    output_scheduler = InteractingScheduler.run(self(), @num_tok_workers, StdoutWriter, :print, [])

    run_queues(file_reader_scheduler, tokenizer_scheduler, output_scheduler)
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
