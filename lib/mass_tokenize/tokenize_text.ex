defmodule TokenizeText do
  @moduledoc """
  A task for the InteractingScheduler: Parse one line of wikiextractor python script output.
  """

  def parse_string(scheduler) do
    send scheduler, {:ready, self() }
    receive do
      {:work, string, client} ->
        send client, {:answer, do_tokenize(string) , self() }
        parse_string(scheduler)
      { :shutdown } ->
        exit(:normal)
    end

  end

  def do_tokenize(string) do
    {:ok, tokens} = Tokenize.rust_tokenize(string)
    tokens
  end

end
