defmodule StdoutWriter do
  @moduledoc """
  A task for the InteractingScheduler: Print an IOList of output
  """

  def print(client, uid) do
    receive do
      {:work, result_list} ->
        send client, {:answer, uid, do_print(result_list), self() }
        print(client, uid)
      { :shutdown } ->
        exit(:normal)
    end

  end

  def do_print(result_list) do
    result_list
    |> Enum.uniq
    |> Enum.map(fn(s) -> [s, '\n'] end)
    |> IO.write
    {:ok}
  end

end
