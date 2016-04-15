defmodule Exometer.Report.Zabbix do
  @moduledoc """
  Exometer reporter for Zabbix. It does batch sending every second by default.
  The reason for this is that the zabbix server closes the connection after
  your data is being sent.
  """
  use Exometer.Report

  # Zabbix protocol definitions
  @zbx_header "ZBXD"
  @zbx_protocol_version 1

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
    data: List.t
  }
  defstruct [:host, :port, :hostname, :timestamping, :batch_window_size, :data]

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

    {:ok, %__MODULE__{  host: host,
                        port: port,
                        hostname: hostname,
                        timestamping: timestamping,
                        batch_window_size: batch_window_size,
                        data: []
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
                                  hostname: hostname} = state) do

    key = zbx_key(metric, datapoint)

    [zbx_object(hostname, key, value, ts)]
    |> zbx_construct_message
    |> zbx_prepend_header
    |> zbx_send(state)

    {:ok, state}
  end

  def exometer_report(metric, datapoint, _extra, value,
                      %__MODULE__{batch_window_size: bws, timestamping: ts,
                                  hostname: hostname, data: data} = state) do

    key = zbx_key(metric, datapoint)
    obj = zbx_object(hostname, key, value, ts)

    batch_send(bws, data)

    {:ok, %__MODULE__{ state | data: [ obj | data ] } }
  end

  @doc """
  Exometer callback for generic messages
  """
  @spec exometer_info(msg :: term, __MODULE__.t) :: {:ok, __MODULE__.t}
  def exometer_info({:zabbix, :send}, %__MODULE__{data: data} = state) do
    data
    |> zbx_construct_message
    |> zbx_prepend_header
    |> zbx_send(state)

    {:ok, %__MODULE__{ state | data: []} }
  end
  def exometer_info(_, state), do: {:noreply, state}

  # send_after when batch is empty
  defp batch_send(bws, []) do
    Process.send_after self(), {:zabbix, :send}, bws
  end
  defp batch_send(_, _), do: :ok

  # generate zabbix key from metric + datapoint
  defp zbx_key(metric, dp) do
    metric ++ [dp]
    |> Enum.join(".")
  end

  # create a zabbix entry without a timestamp
  defp zbx_object(hostname, key, value, false) do
    %{hostname: hostname, key: key, value: "#{value}"}
  end

  # create a zabbix entry with a timestamp
  defp zbx_object(hostname, key, value, true) do
    zbx_object(hostname, key, value, false)
    |> Map.put(:clock, :erlang.system_time(:seconds))
  end

  # construct a zabbix message
  defp zbx_construct_message(data) do
    %{  request: "sender data",
        data: data,
        clock: :erlang.system_time(:seconds)
      }
    |> Poison.encode!
  end

  # add zabbix specific header to the message
  defp zbx_prepend_header(msg) do
    <<@zbx_header :: binary,
      @zbx_protocol_version,
      byte_size(msg) :: little-integer-size(64),
      msg :: binary>>
  end

  # send a message to zabbix, we connect for each send action since the server doesn't allow
  # to keep the connection open
  defp zbx_send(msg, %__MODULE__{host: host, port: port}) do
    {:ok, sock} = :gen_tcp.connect('#{host}', port, [active: false])
    :ok = :gen_tcp.send sock, msg

    # we need to add some error validation
    :gen_tcp.recv(sock, 0)
    |> case do
        {:ok, resp} -> resp
        _ = err -> err
      end

    :gen_tcp.close sock
  end

end
