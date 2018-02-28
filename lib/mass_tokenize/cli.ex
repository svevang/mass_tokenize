defmodule MassTokenize.CLI do

  @moduledoc """
  Handle the command line parsing and the dispatch to the functions that will
  extract from the text files.
  """

  def run(argv) do
    argv
    |> parse_args
    |> process
  end

  @doc """
  `argv` can be either -h or --help which returns :help

  otherwise it is a path to a file we want to parse

  """

  def process(:help) do
    IO.puts """
    Usage: mass_tokenize [OPTIONS] 

      Tokenize a text file or directory: $ mass_tokenize --path <some/path>
      Print this help:                   $ mass_tokenize --help

    Options:
      --wikiextractor-json  Assume the input format is wikiextractor line-oriented json objects
      --help/-h             Print this help

    """
  end

  def process([path: some_path, wikiextractor_json: wikiextractor_json]) do
    MassTokenize.tokenize_text_files([path: some_path, wikiextractor_json: wikiextractor_json])
  end

  def parse_args(argv) do

    parse = OptionParser.parse(argv, switches: [help: :boolean, wikiextractor_json: :boolean, path: :string], aliases:  [h: :help])


    case parse do
      {[help: true], _,  _ }
        -> :help
      {[path: file_path], _, _}
        -> [ path: file_path,  wikiextractor_json: false ]
      {[path: file_path, wikiextractor_json: _], _, _}
        -> [ path: file_path,  wikiextractor_json: true ]
      _
        -> :help
    end

  end
end
