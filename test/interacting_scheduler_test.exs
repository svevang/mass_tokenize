defmodule InteractingSchedulerTest do
  use ExUnit.Case

  defmodule EchoWorker do

    def echo(client, uid) do
      receive do
        {:work, val, client} ->
          send client, {:answer, uid, val, self() }
          echo(client, uid)
        { :shutdown } ->
          exit(:normal)
      end

    end

    defp read_file(path) do
      File.read!(path)
    end

  end

  test "return a struct when creating a new scheduler" do

    scheduler = InteractingScheduler.run(self(), 1, EchoWorker, :echo, [1,2,4])
    assert scheduler.queue == [1, 2, 4]
    assert scheduler.client_pid == self()
    assert MapSet.size(scheduler.processes) == 1
    assert MapSet.size(scheduler.busy_processes) == 0

  end


end
