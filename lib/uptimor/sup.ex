defmodule Uptimor.Sup do
  @moduledoc """
  Supervisor that spins up all of the uptime processes.
  Runs a single process for each monitored website
  """

  use DynamicSupervisor

  alias Uptimor.WebsiteMonitor

  def start_link(config) do
    DynamicSupervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  def start_child(config) do
    spec = {WebsiteMonitor, config}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def init(_config) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
