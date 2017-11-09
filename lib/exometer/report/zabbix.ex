defmodule Exometer.Report.Zabbix do
  @moduledoc """
  Exometer reporter for Zabbix. It does batch sending every second by default.
  The reason for this is that the zabbix server closes the connection after
  your data is being sent.
  """
  use Exometer.Report
  alias Exometer.Report.Zabbix.Utils
  alias Exometer.Report.Zabbix.Server

  # Default application values
  @host "127.0.0.1"
  @port 10051
  @timestamping true
  @batch_window_size 1_000

  @type t :: %__MODULE__{
    host: String.t,
    port: Integer.t,
    hostname: String.t,
    timestamping: boolean,
    batch_window_size: Integer.t,
    data: List.t,
    create_items: boolean
  }
  defstruct [:host, :port, :hostname, :timestamping, :batch_window_size, :data, :create_items]

  @doc """
  Initialize a zabbix reporter for exometer
  """
  @spec exometer_init(opts :: term) :: __MODULE__.t
  def exometer_init(opts) do
    host = Keyword.get(opts, :host, @host)
    port = Keyword.get(opts, :port, @port)
    timestamping = Keyword.get(opts, :timestamping, @timestamping)
    batch_window_size = Keyword.get(opts, :batch_window_size, @batch_window_size)
    hostname = Keyword.get(opts, :hostname, "")
    create_items = Keyword.get(opts, :create_items, false)

    {:ok, %__MODULE__{  host: host,
                        port: port,
                        hostname: hostname,
                        timestamping: timestamping,
                        batch_window_size: batch_window_size,
                        data: [],
			create_items: create_items
                      }}
  end

  @doc """
  Exometer callback where values will be sent
  """
  @spec exometer_report(:exometer_report.metric,
                        :exometer_report.datapoint,
                        :exometer_report.extra,
                        value :: term,
                        __MODULE__.t
                        ) :: {:ok, __MODULE__.t}
  def exometer_report(metric, datapoint, _extra, value,
                      %__MODULE__{batch_window_size: 0, timestamping: ts,
                                  hostname: hostname, host: host, port: port} = state) do

    key = Utils.key(metric, datapoint)

    [Server.entry(hostname, key, value, ts)] |>
    Server.send(host, port)

    {:ok, state}
  end

  def exometer_report(metric, datapoint, _extra, value,
                      %__MODULE__{batch_window_size: bws, timestamping: ts,
                                  hostname: hostname, data: data} = state) do

    key = Utils.key(metric, datapoint)
    obj = Server.entry(hostname, key, value, ts)

    batch_send(bws, data)

    {:ok, %__MODULE__{ state | data: [ obj | data ] } }
  end

  @doc """
  Exometer callback for generic messages
  """
  @spec exometer_info(msg :: term, __MODULE__.t) :: {:ok, __MODULE__.t}
  def exometer_info({:zabbix, :send}, %__MODULE__{host: host, port: port, data: data} = state) do
    data |>
      Server.send(host, port)

    {:ok, %__MODULE__{ state | data: []} }
  end
  def exometer_info(_, state), do: {:noreply, state}

  @doc """
  Exometer callback for handling new subscription
  """
  @spec exometer_subscribe(:exometer_report.metric,
                           :exometer_report.datapoint,
                           :exometer_report.interval,
                           :exometer_report.extra,
                           __MODULE__.t
                        ) :: {:ok, __MODULE__.t}
  def exometer_subscribe(_metric, _datapoint, _interval, _extra, %__MODULE__{create_items: false} = state) do
    {:ok, state}
  end
  def exometer_subscribe(metric, datapoint, interval, extra, %__MODULE__{host: host, port: port} = state) do
    key = Utils.key(metric, datapoint)
    #:ok = zbx_ensure_tmpl(zbx_tmpl(metric))
    IO.puts("### ZABBIX SUBSCRIBE (#{host}:#{port}): #{key} / #{interval} / #{extra}")
    {:ok, state}
  end

  # send_after when batch is empty
  defp batch_send(bws, []) do
    Process.send_after self(), {:zabbix, :send}, bws
  end
  defp batch_send(_, _), do: :ok
end
