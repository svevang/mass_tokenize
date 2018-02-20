defmodule TokenizeWikiExtractorJson do
  @moduledoc """
  A task for the InteractingScheduler: Parse one line of wikiextractor python script output.
  """

  require Logger

  def parse_string(scheduler) do
    send scheduler, {:ready, self() }
    receive do
      {:work, string, client} ->
        send client, {:answer, parse_json(string) , self() }
        parse_string(scheduler)
      { :shutdown } ->
        exit(:normal)
    end

  end

  def parse_json(string) do

    {:ok, stream} =
      string
       |> StringIO.open()

    stream
    |> IO.binstream(:line)
    |> Enum.map( fn(line) -> Poison.decode!(line) end )
    |> Enum.map(fn(json) -> 
      {:ok, tokens } = Tokenize.rust_tokenize(json["text"])
      tokens
    end)
    |> List.flatten


  end

end
