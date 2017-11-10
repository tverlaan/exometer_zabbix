defmodule Exometer.Report.Zabbix.Server do
  @moduledoc """
  Wrapper for Zabbix server
  """
  require Logger
  
  # Zabbix protocol definitions
  @zbx_header "ZBXD"
  @zbx_protocol_version 1

  @doc """
  Create a zabbix entry
  """
  def entry(hostname, key, value, false) do
    %{host: hostname, key: key, value: "#{value}"}
  end
  def entry(hostname, key, value, true) do
    entry(hostname, key, value, false)
    |> Map.put(:clock, :erlang.system_time(:seconds))
  end

  @doc """
  Send given entries to server
  """
  def send(entries, host, port) do
    entries |>
      construct_message() |>
      prepend_header() |>
      do_send(host, port)
  end

  ###
  ### Priv
  ###
  # construct a zabbix message
  defp construct_message(data) do
    %{  request: "sender data",
        data: data,
        clock: :erlang.system_time(:seconds)
      }
    |> Poison.encode!
  end

  # add zabbix specific header to the message
  defp prepend_header(msg) do
    <<@zbx_header :: binary,
      @zbx_protocol_version,
      byte_size(msg) :: little-integer-size(64),
      msg :: binary>>
  end

  # send a message to zabbix, we connect for each send action since the server doesn't allow
  # to keep the connection open
  defp do_send(msg, host, port) do
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
