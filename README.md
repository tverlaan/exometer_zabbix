# Exometer Zabbix Reporter

[![Hex.pm Version](https://img.shields.io/hexpm/v/exometer_zabbix.svg?style=flat)](https://hex.pm/packages/exometer_zabbix) [![CI Status](https://github.com/tverlaan/exometer_zabbix/workflows/CI/badge.svg)](https://github.com/tverlaan/exometer_zabbix/actions)

A [Zabbix](http://www.zabbix.com) reporter backend for exometer_core. This repo also contains an Elixir behaviour for reporters to have less boilerplate in the actual reporter.

## Installation

The package can be installed as:

  1. Add exometer_zabbix to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exometer_zabbix, "~> 0.1"} # see Hex version at the top
  ]
end
```

  2. Configure exometer_zabbix

```elixir
config :exometer_core,
  report: [
    reporters: [
      'Elixir.Exometer.Report.Zabbix': [
        host: "127.0.0.1", # zabbix host
        hostname: "my-hostname-in-zabbix" # hostname of the machine in zabbix
      ]
    ]
  ]
```

## Usage

The zabbix hostname is taken from the configuration. Each metric will be sent as if it belongs to that host.

Metrics in exometer are noted by a list of atoms. Each metric has one or more datapoints. Zabbix keys are generated using the metric name and each individual datapoint.
Eg. `[:erlang, :memory]` with datapoints `[:atom, :total]` becomes `erlang.memory.atom` and `erlang.memory.total`.

Add items to zabbix with type `trapper`. More info [here](https://www.zabbix.com/documentation/2.4/manual/config/items/itemtypes/trapper).

## Configuration example

```elixir
config :exometer_core,
  predefined: [
    { [:erlang, :memory], {:function, :erlang, :memory, [], :proplist, [:atom, :binary, :ets, :processes, :total]}, [] },
    { [:erlang, :statistics], {:function, :erlang, :statistics, [:'$dp'], :value, [:run_queue]}, [] },
    { [:erlang, :system_info], {:function, :erlang, :system_info, [:'$dp'], :value, [:port_count, :process_count, :thread_pool_size]}, [] },
  ],
  report: [
    reporters: [
      'Elixir.Exometer.Report.Zabbix': [
        host: "127.0.0.1",
        port: 10051,
        timestamping: true,
        batch_window_size: 1000,
        hostname: "my-hostname-in-zabbix"
      ]
    ],
    subscribers: [
      {Exometer.Report.Zabbix, [:erlang, :memory], [:atom, :binary, :ets, :processes, :total], 5000, true, []},
      {Exometer.Report.Zabbix, [:erlang, :statistics], :run_queue, 5000, true, []},
      {Exometer.Report.Zabbix, [:erlang, :system_info], [:port_count, :process_count, :thread_pool_size], 5000, true, []}
    ]
  ]
```
