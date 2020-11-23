defmodule ExometerZabbixTest do
  use ExUnit.Case, async: true
  alias Exometer.Report.Zabbix

  setup_all do
    {:ok, state} = Zabbix.exometer_init([])

    {:ok, state: state}
  end

  test "initialize zabbix reporter returns correct state" do
    assert Zabbix.exometer_init([]) ==
             {:ok,
              %Zabbix{
                batch_window_size: 1000,
                data: [],
                host: "127.0.0.1",
                hostname: "",
                port: 10051,
                timestamping: true
              }}
  end

  test "reporting adds to batch", %{state: state} do
    {:ok, %Zabbix{data: data}} = Zabbix.exometer_report([:foo], 'bar', :extra, 1, state)
    assert %{clock: _, host: "", key: "foo.bar", value: "1"} = hd(data)
  end

  test "reporting with long metric works", %{state: state} do
    {:ok, %Zabbix{data: data}} =
      Zabbix.exometer_report([:my, :metric, :name], 'bar', :extra, 1, state)

    assert %{clock: _, host: "", key: "my.metric.name.bar", value: "1"} = hd(data)
  end

  test "reporting twice adds to batch", %{state: state} do
    {:ok, new_state} = Zabbix.exometer_report([:foo], 'bar', :extra, 1, state)

    {:ok, %Zabbix{data: data}} =
      Zabbix.exometer_report([:base], 'datapoint', :extra, 2, new_state)

    assert length(data) == 2

    [second, first] = data
    assert %{clock: _, host: "", key: "foo.bar", value: "1"} = first
    assert %{clock: _, host: "", key: "base.datapoint", value: "2"} = second
  end

  test "reporting without batch works", %{state: state} do
    zbx_server(10051)
    no_batch_state = %{state | batch_window_size: 0}

    {:ok, %Zabbix{data: data}} =
      Zabbix.exometer_report([:my, :metric, :name], 'bar', :extra, 1, no_batch_state)

    assert data == []

    <<header::binary-size(4), version::binary-size(1), msg_size::little-integer-size(64),
      rest::binary>> = assert_receive(_)

    assert header == "ZBXD"
    assert version == <<1>>
    assert msg_size == byte_size(rest)

    zbx_struct = Jason.decode!(rest)
    assert is_integer(zbx_struct["clock"])
    assert zbx_struct["request"] == "sender data"
    assert length(zbx_struct["data"]) == 1

    assert %{"clock" => _, "host" => "", "key" => "my.metric.name.bar", "value" => "1"} =
             hd(zbx_struct["data"])
  end

  test "reporting with batch works", %{state: state} do
    zbx_server(10052)
    state = %{state | port: 10052, batch_window_size: 50}

    {:ok, new_state} = Zabbix.exometer_report([:my, :metric, :name], 'bar', :extra, 1, state)

    {:ok, %Zabbix{data: data} = latest_state} =
      Zabbix.exometer_report([:my, :metric, :name], 'bar', :extra, 2, new_state)

    assert length(data) == 2
    zbx_batcher(latest_state)

    <<header::binary-size(4), version::binary-size(1), msg_size::little-integer-size(64),
      rest::binary>> = assert_receive(_)

    assert header == "ZBXD"
    assert version == <<1>>
    assert msg_size == byte_size(rest)

    zbx_struct = Jason.decode!(rest)
    assert is_integer(zbx_struct["clock"])
    assert zbx_struct["request"] == "sender data"
    assert length(zbx_struct["data"]) == 2

    [second, first] = zbx_struct["data"]
    assert %{"clock" => _, "host" => "", "key" => "my.metric.name.bar", "value" => "1"} = first
    assert %{"clock" => _, "host" => "", "key" => "my.metric.name.bar", "value" => "2"} = second
  end

  defp zbx_server(port) do
    test = self()

    spawn(fn ->
      {:ok, listen} = :gen_tcp.listen(port, [:binary, active: false, reuseaddr: true])
      {:ok, sock} = :gen_tcp.accept(listen)
      {:ok, packet} = :gen_tcp.recv(sock, 0, 5000)
      send(test, packet)
      :gen_tcp.close(listen)
    end)
  end

  defp zbx_batcher(state) do
    receive do
      {:zabbix, :send} -> Zabbix.exometer_info({:zabbix, :send}, state)
    end
  end
end
