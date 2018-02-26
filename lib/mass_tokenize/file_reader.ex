defmodule FileReader do
  @moduledoc """
  A task for the InteractingScheduler: Read a file from disk.
  """

  def read_text(client, uid) do
    send client, {:ready, self() }
    receive do
      {:work, path, client} ->
        send client, {:answer, uid, read_file(path), self() }
        read_text(client, uid)
      { :shutdown } ->
        exit(:normal)
    end

  end

  defp read_file(path) do
    File.read!(path)
  end

end
