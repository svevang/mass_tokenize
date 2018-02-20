defmodule FileReader do
  @moduledoc """
  A task for the InteractingScheduler: Read a file from disk.
  """

  def read_text(scheduler) do
    send scheduler, {:ready, self() }
    receive do
      {:work, path, client} ->
        send client, {:answer, read_file(path), self() }
        read_text(scheduler)
      { :shutdown } ->
        exit(:normal)
    end

  end

  defp read_file(path) do
    File.read!(path)
  end

end
