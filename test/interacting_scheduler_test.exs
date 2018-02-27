defmodule EchoWorker do
  def echo(client, uid) do
    receive do
      {:work, val} ->
        send client, {:answer, uid, val, self() }
        echo(client, uid)
      { :shutdown } ->
        exit(:normal)
    end
  end
end

defmodule InteractingSchedulerTest do
  use ExUnit.Case

  setup [:create_scheduler]

  describe "#new" do
    setup [:create_scheduler]
    test "return a struct when creating a new scheduler", context do

      scheduler = context[:scheduler]
      assert scheduler.queue == [1, 2, 4]
      assert scheduler.client_pid == self()
      assert MapSet.size(scheduler.processes) == 1
      assert MapSet.size(scheduler.busy_processes) == 0

    end
  end

  describe "#push_queue" do
    setup [:create_scheduler]
    test "should add work items to the queue", context do
      scheduler = context[:scheduler]
      scheduler = InteractingScheduler.push_queue(scheduler, 99)
      assert scheduler.queue == [99,1,2,4]
    end
  end


  describe "InteractingScheduler.schedule_processes/1" do
    setup [:create_scheduler]

    test "running scheduler removes from queue", context do
      scheduler = context[:scheduler]
      scheduler = InteractingScheduler.schedule_processes(scheduler)

      assert scheduler.queue == [2,4]
      assert assert MapSet.size(scheduler.busy_processes) == 1
    end

    test "scheduler sends work to worker", context do
      scheduler = context[:scheduler]
      scheduler = InteractingScheduler.schedule_processes(scheduler)

      # XXX, worker_pid and uid and marked as unused by the compiler
      worker_pid = hd(MapSet.to_list(scheduler.busy_processes))
      uid = scheduler.uid
      assert_receive({:answer, uid, 1, worker_pid}, 100)
    end

  end

  defp create_scheduler(context) do
    scheduler = InteractingScheduler.run(self(), 1, EchoWorker, :echo, [1,2,4])
    Map.put(context, :scheduler, scheduler)
  end

end
