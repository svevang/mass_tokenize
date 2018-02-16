defmodule InteractingScheduler do
  @moduledoc """
  A schedular that returns values to the caller, allowing the caller to modify
  parameters based on another schedular.
  """

  def run(client_pid, num_processes, module, func, queue) do
    busy_processes = (1..num_processes)
    |> Enum.map(fn(_) -> spawn(module, func, [self()]) end)

    schedule_processes(client_pid, MapSet.new(busy_processes), MapSet.new,  queue)

  end

  def schedule_processes(client_pid, processes, busy_processes, queue) do

    avail_workers = MapSet.difference(processes, busy_processes)

    work_batch = Enum.take(queue, MapSet.size(avail_workers))
    queue = Enum.drop(queue, length(work_batch))

    avail_workers
    |> Enum.zip(work_batch)
    |> Enum.each(fn(zipped)->
      {pid, work_item} = zipped
      IO.puts("Sending #{work_item} to #{inspect(pid)}")
      send pid, {:work, work_item, self()}
    end)

    busy_processes = MapSet.union(busy_processes, avail_workers)

    receive do
      {:ready, worker_pid} when length(queue) > 0 ->
        schedule_processes(client_pid, processes, MapSet.delete(busy_processes, worker_pid), queue)
      {:answer, result, worker_pid} when length(queue) == 0 ->
        Enum.each(processes, fn(pid) -> send(pid, :shutdown) end)
      {:answer, result, worker_pid} ->
        schedule_processes(client_pid, processes, MapSet.delete(busy_processes, worker_pid), queue)
    end

  end

end
