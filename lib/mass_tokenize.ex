defmodule MassTokenize do
  @moduledoc """
  Documentation for MassTokenize.
  """
  import Tokenize
  import InteractingScheduler
  import ExProf.Macro

  @doc """
  Hello world.

  ## Examples

      iex> MassTokenize.hello
      :world

  """

  def start_queues(file_queue, json_lines: true) do
    profile do
      InteractingScheduler.run(self(), 4, FileReader, :read_text, file_queue)
    end
  end

  def process_text_files([path: dir, json_lines: json_lines]) do

    file_list = gather_tree(dir, [])
    |> List.flatten

    start_queues(file_list, json_lines: json_lines)
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
