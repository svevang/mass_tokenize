defmodule TokenizeText do
  @moduledoc """
  A task for the InteractingScheduler: Parse one line of wikiextractor python script output.
  """

  def parse_string(client, uid) do
    receive do
      {:work, string} ->
        send client, {:answer, do_tokenize(string) , self() }
        parse_string(client, uid)
      { :shutdown } ->
        exit(:normal)
    end

  end

  def do_tokenize(string) do
    {:ok, tokens} = Tokenize.rust_tokenize(string)
    tokens
  end

end
