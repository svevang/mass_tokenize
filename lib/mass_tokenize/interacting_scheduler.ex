defmodule InteractingScheduler do
  @moduledoc """
  A scheduler that allows the client to modify
  parameters based on another scheduler.
  """

  require Logger

  @enforce_keys [:client_pid, :module, :uid, :processes, :busy_processes, :queue]
  defstruct @enforce_keys

  def run(client_pid, num_processes, module, func, queue) do
    InteractingScheduler.setup_queues(client_pid, num_processes, module, gen_uid(), func, queue)
  end

  def setup_queues(client_pid, num_processes, module, uid, func, queue) do
    processes = (1..num_processes)
    |> Enum.map(fn(_) -> spawn(module, func, [self(), uid]) end)

    scheduler = %InteractingScheduler{
      client_pid: client_pid,
      module: module,
      uid: uid,
      processes: MapSet.new(processes),
      busy_processes: MapSet.new,
      queue: queue
    }

    scheduler
  end

  def queue_drained?(scheduler = %InteractingScheduler{}) do
    MapSet.size(scheduler.busy_processes) == 0 and length(scheduler.queue) == 0
  end

  def receive_answer(scheduler = %InteractingScheduler{}, result, worker_pid) do
    Logger.debug("[InteractingScheduler] answer from #{scheduler.module}")

    scheduler = %{ scheduler | busy_processes: MapSet.delete(scheduler.busy_processes, worker_pid) }

    scheduler
  end

  def push_queue(scheduler = %InteractingScheduler{}, work_item) do
    Logger.debug("[InteractingScheduler] pushed work for #{scheduler.module}")
    %{ scheduler | queue: [work_item | scheduler.queue] }
  end

  def schedule_processes(scheduler = %InteractingScheduler{}) do

    Logger.debug("[InteractingScheduler] setting up work for #{scheduler.module}, queue length: #{length(scheduler.queue)}")

    avail_workers = MapSet.difference(scheduler.processes, scheduler.busy_processes)

    work_batch = Enum.take(scheduler.queue, MapSet.size(avail_workers))
    scheduler = %{ scheduler | queue: Enum.drop(scheduler.queue, length(work_batch)) }

    # keep track of availible workers.
    # Gather a list of workers that will be assigned work:
    {used_pids, _} = avail_workers
    |> Enum.zip(work_batch)
    |> Enum.map(fn(zipped)->
      {pid, work_item} = zipped
      send pid, {:work, work_item}
      zipped
    end)
    |> Enum.unzip

    Logger.debug("[InteractingScheduler] #{scheduler.module} executing #{length(used_pids)} workers with #{MapSet.size(scheduler.busy_processes)} working.")

    scheduler = %{ scheduler | busy_processes: MapSet.union(scheduler.busy_processes, MapSet.new(used_pids)) }

  end

  defp gen_uid(length \\ 32) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
  end


end
