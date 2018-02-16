defmodule ParseWikiExtractorOutput do
  @moduledoc """
  A task for the InteractingScheduler: Parse the wikiextractor python script output.
  """

  def parse_string(scheduler) do
    send scheduler, {:ready, self() }
    receive do
      {:work, json_string, client} ->
        send client, {:answer, parse_json(json_string) , self() }
        parse_string(scheduler)
      { :shutdown } ->
        exit(:normal)
    end

  end

  def parse_json(json_string) do
    json = Poison.decode!(json_string)
    {:ok, tokens} = Tokenize.rust_tokenize(json["text"])
    tokens
  end

end
