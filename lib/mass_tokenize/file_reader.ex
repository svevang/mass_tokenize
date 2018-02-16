defmodule FileReader do
  @moduledoc """
  A task for the InteractingScheduler: Read a file from disk.
  """

  def read_text(scheduler) do
    send scheduler, {:ready, self() }
    receive do
      {:work, path, client} ->
        IO.puts "received work for #{path}"
        IO.inspect client
        send client, {:answer, read_wikiextractor_dump(path), self() }
        read_text(scheduler)
      { :shutdown } ->
        exit(:normal)
    end

  end

  defp read_wikiextractor_dump(path) do
    File.stream!(path)
    |> Enum.to_list
  end

end
