defmodule Uptimor.Processors.WebsiteMonitor do
  @moduledoc "Process to check website uptime"

  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    Process.send_after(self(), :start_processors, 0)

    {:ok, nil}
  end

  @impl true
  def handle_info(:start_processors, state) do
    Application.fetch_env!(:uptimor, :backend).get_all!()
    |> Enum.each(fn request ->
      Process.send_after(self(), {:start_processor, request}, 0)
    end)

    {:noreply, state}
  end

  @impl true
  def handle_info({:start_processor, request}, state) do
    {:ok, _} = Uptimor.Sup.start_child(request)

    {:noreply, state}
  end
end
