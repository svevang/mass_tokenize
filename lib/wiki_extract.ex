defmodule WikiExtract do
  @moduledoc """
  Documentation for WikiExtract.
  """

  @doc """
  Hello world.

  ## Examples

      iex> WikiExtract.hello
      :world

  """

  def parse_file([path: wiki_dump_path]) do
    IO.puts(wiki_dump_path)

  end

end
