defmodule Uptimor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @registry :pinger

  @impl true
  def start(_type, _args) do
    children = [
      Uptimor.Sup,
      {Registry, [keys: :unique, name: @registry]},
      {Finch, name: Uptimor.Finch},
      Uptimor.Processors.WebsiteMonitor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Uptimor.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
