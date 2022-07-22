defmodule Uptimor.WebsiteMonitor do
  @moduledoc "Process in charge of monitoring websites"

  use GenServer

  require Logger

  @minute_multiplier 60000
  @default_next_process_ms 10 * @minute_multiplier
  @registry :pinger

  @schema [
    name: [
      doc: """
      Unique name of the process. It will be added to the registry
      and looked up by it
      """,
      type: :string,
      required: true
    ],
    next_process_in_ms: [
      doc: "Time in ms to run next check. Will default to 10 minutes if not provided",
      type: :integer,
      required: false,
      default: @default_next_process_ms
    ],
    host: [
      doc: "Host of the website",
      type: :string,
      required: true
    ],
    path: [
      doc: "Path of the website. Will default to / if not provided",
      type: :any,
      required: false,
      default: "/"
    ],
    scheme: [
      doc: ":http or :https. Defaults to :https if not provided",
      type: {:in, [:http, :https]},
      required: false,
      default: :https
    ],
    port: [
      doc: "Port number. Usually 80 or 443. Defaults to 443 if not provided",
      type: :integer,
      required: false,
      default: 443
    ],
    method: [
      doc: "Method of the call. POST or GET. Will default to GET if not provided",
      type: {:in, ["POST", "GET"]},
      required: false,
      default: "GET"
    ],
    request_timeout: [
      doc: "Request timeout in ms. When timeout expires, the request will be cancelled",
      type: :integer,
      required: false,
      default: 30_000
    ],
    headers: [
      doc: "Request headers",
      type: :any,
      required: false,
      default: []
    ],
    body: [
      doc: "Request body",
      type: :any,
      required: false,
      default: ""
    ],
    query: [
      doc: "Request query",
      type: :any,
      required: false,
      default: []
    ],
    expected_status_code: [
      doc: "Expected status code from response",
      type: :integer,
      required: true
    ]
  ]

  defstruct Keyword.keys(@schema)

  def start_link(config) do
    config =
      config
      |> remove_nils()
      |> with_scheme()
      |> validate!()
      |> structify()

    GenServer.start_link(__MODULE__, config, name: via_tuple(config.name))
  end

  @impl true
  def init(config) do
    conn = %Finch.Request{
      scheme: config.scheme,
      host: config.host,
      port: config.port,
      method: config.method,
      path: config.path,
      headers: config.headers,
      body: config.body,
      query: config.query
    }

    Process.send_after(self(), :run, 0)

    {:ok, %{config: config, conn: conn}}
  end

  @impl true
  def handle_info(:run, state) do
    response = Finch.request(state.conn, Uptimor.Finch)

    Process.send_after(self(), {:handle_response, response}, 0)
    Process.send_after(self(), :run, state.config.next_process_in_ms)

    Logger.info("Request: #{inspect(response)}")

    {:noreply, state}
  end

  @impl true
  def handle_info(
        {:handle_response, {:ok, %{status: expected_status_code}}},
        %{config: %{expected_status_code: expected_status_code}} = state
      ) do
    {:noreply, state}
  end

  @impl true
  def handle_info(
        {:handle_response, {:ok, %{status: status} = _response}},
        state
      ) do
    Logger.error("Unexpected status code received. Status: #{status}")

    {:noreply, state}
  end

  defp via_tuple(name) do
    {:via, Registry, {@registry, name}}
  end

  defp to_scheme(nil), do: nil

  defp to_scheme(scheme) when is_atom(scheme) do
    scheme
  end

  defp to_scheme(scheme) when is_binary(scheme) do
    String.to_atom(scheme)
  end

  defp remove_nils(config) do
    Enum.reject(config, fn {_, v} -> is_nil(v) end)
  end

  defp validate!(config) do
    NimbleOptions.validate!(config, @schema)
  end

  defp structify(config) do
    struct(__MODULE__, config)
  end

  defp with_scheme(config) do
    Keyword.put(config, :scheme, to_scheme(config[:scheme]))
  end
end
