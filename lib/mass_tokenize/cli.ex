defmodule MassTokenize.CLI do

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
    Usage:

      Tokenize a text file or directory: $ mass_tokenize --path <some/path>
      Print this help:                   $ mass_tokenize --help

    Options:

    --json-lines  Assume the input format is wikiextract line-oriented json objects

    """
  end

  def process([path: some_path]) do
    MassTokenize.parse_file([path: some_path])
  end

  def parse_args(argv) do

    parse = OptionParser.parse(argv, switches: [help: :boolean, json_lines: :boolean, path: :string], aliases:  [h: :help])

    case parse do
      {[help: true], _,  _ }
        -> :help
      {[path: file_path, json_lines: wikiextract_format ], _, _}
        -> [ path: file_path,  json_lines: wikiextract_format ]
      _
        -> :help
    end

  end
end
