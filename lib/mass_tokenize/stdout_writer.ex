defmodule StdoutWriter do
  @moduledoc """
  A task for the InteractingScheduler: Print an IOList of output
  """

  def do_write(result_list) do
    result_list
    |> Enum.map(fn(s) -> [s, '\n'] end)
    |> IO.write
    {:ok}
  end

end
