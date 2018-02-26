defmodule TokenizeWikiExtractorJson do
  @moduledoc """
  A task for the InteractingScheduler: Parse one line of wikiextractor python script output.
  """

  require Logger

  def parse_string(client, uid) do
    send client, {:ready, self() }
    receive do
      {:work, string, client} ->
        send client, {:answer, uid, parse_json(string) , self() }
        parse_string(client, uid)
      { :shutdown } ->
        exit(:normal)
    end

  end

  def parse_json(string) do

    string
    |> String.trim
    |> String.split("\n")
    |> Enum.map( fn(line) -> Poison.decode!(line) end )
    |> Enum.map(fn(json) -> 
      {:ok, tokens } = Tokenize.rust_tokenize(json["text"])
      tokens
    end)
    |> List.flatten


  end

end
