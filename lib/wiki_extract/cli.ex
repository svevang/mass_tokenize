defmodule WikiExtract.CLI do

  @moduledoc """
  Handle the command line parsing and the dispatch to the functions that will
  extract from the wiki.
  """

  def run(argv) do
    argv
    |> parse_args
    |> process
  end

  @doc """
  `argv` can be either -h or --help which returns :help

  otherwise it is a path to a file we want to parse

  Return a tuple of `{ path }` of `:help` if help was given

  """

  def process(:help) do
    IO.puts """
      Usage: wiki_extract --path <some/textfile>
    """
  end

  def process([path: some_path]) do
    WikiExtract.parse_file([path: some_path])
  end

  def parse_args(argv) do

    parse = OptionParser.parse(argv, switches: [help: :boolean, path: :string], aliases:  [h: :help])

    case parse do
      {[help: true], _,  _ }
        -> :help
      {[path: file_path ], _, _}
        -> [ path: file_path ]
      _
        -> :help
    end

  end
end
