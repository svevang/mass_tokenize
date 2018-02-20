defmodule InteractingScheduler do
  @moduledoc """
  A scheduler that allows the client to modify
  parameters based on another scheduler.
  """

  require Logger

  @enforce_keys [:client_pid, :module, :processes, :busy_processes, :queue]
  defstruct @enforce_keys

  def run(client_pid, num_processes, module, func, queue) do
    spawn_link(InteractingScheduler, :setup_queues, [client_pid, num_processes, module, func, queue])
  end

  def setup_queues(client_pid, num_processes, module, func, queue) do
    processes = (1..num_processes)
    |> Enum.map(fn(_) -> spawn(module, func, [self()]) end)

    scheduler = %InteractingScheduler{
      client_pid: client_pid,
      module: module,
      processes: MapSet.new(processes),
      busy_processes: MapSet.new,
      queue: queue
    }

    InteractingScheduler.schedule_processes(scheduler)
  end

  def schedule_processes(scheduler = %InteractingScheduler{}) do

    Logger.info("[InteractingScheduler] setting up work for #{scheduler.module}, queue length: #{length(scheduler.queue)}")

    avail_workers = MapSet.difference(scheduler.processes, scheduler.busy_processes)

    work_batch = Enum.take(scheduler.queue, MapSet.size(avail_workers))
    scheduler = %{ scheduler | queue: Enum.drop(scheduler.queue, length(work_batch)) }

    # Because we can add work after the queue is drained,
    # keep track of availible workers.
    # Gather a list of workers that will be assigned work:
    {used_pids, _} = avail_workers
    |> Enum.zip(work_batch)
    |> Enum.map(fn(zipped)->
      {pid, work_item} = zipped
      send pid, {:work, work_item, self()}
      zipped
    end)
    |> Enum.unzip

    scheduler = %{ scheduler | busy_processes: MapSet.union(scheduler.busy_processes, MapSet.new(used_pids)) }

    receive do
      {:answer, result, worker_pid} ->
        Logger.info("[InteractingScheduler] answer from #{scheduler.module}")

        scheduler = %{ scheduler | busy_processes: MapSet.delete(scheduler.busy_processes, worker_pid) }
        send scheduler.client_pid, {:answer, scheduler.module, result}
        if MapSet.size(scheduler.busy_processes) == 0 and length(scheduler.queue) == 0  do
          send scheduler.client_pid, {:queue_drain, scheduler.module}
        end
        schedule_processes(scheduler)
      {:push_queue, work_item} ->
        Logger.info("[InteractingScheduler] pushed work for #{scheduler.module}")
        scheduler = %{ scheduler | queue: [work_item | scheduler.queue] }
        schedule_processes(scheduler)
      #anything ->
        #Logger.info("[InteractingScheduler] received #{inspect(anything)}")
        #schedule_processes(scheduler)

    end

  end

end
