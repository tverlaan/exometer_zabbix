# Exometer Zabbix Reporter

[![Build Status](https://travis-ci.org/tverlaan/exometer_zabbix.svg?branch=master)](https://travis-ci.org/tverlaan/exometer_zabbix)
[![Hex.pm Version](http://img.shields.io/hexpm/v/exometer_zabbix.svg?style=flat)](https://hex.pm/packages/exometer_zabbix)

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

Items must be declared in zabbix, of type `trapper`. More info [here](https://www.zabbix.com/documentation/2.4/manual/config/items/itemtypes/trapper).

`exometer_zabbix` can creates the items for you. You must then add the following options in `exometer_zabbix` configuration:

```elixir
      'Elixir.Exometer.Report.Zabbix': [
		create_items: true,
        rpcurl: "http://127.0.0.1/api_jsonrpc.php",
		rpcuser: "Admin",
		rpcpassword: "zabbix"
      ]
```

Each item is associated with a template and an application associated with this template. 
Template and application names can be customized by specifying functions which takes as input 
the metric. Template must be associated with a parent template whose id can also be
customized.

```elixir
      'Elixir.Exometer.Report.Zabbix': [
	    tmpl_parent_id: 11,
		tmpl_formatter: &MyModule.template/1,
		app_formatter: &MyModule.application/1
      ]
```

Items can be customized with `extra` argument of subscriptions. For instance:
```elixir
      {Exometer.Report.Zabbix, [:erlang, :memory], :atom, 1_000, true, [
        type: :zbx_type_unsigned, name: "Erlang memory (atom #)"
      ]}
```

* `type` is one of Zabix value types: `:zbx_type_float`, `:zbx_type_character`, `:zbx_type_log`, 
`:zbx_type_unsigned` or `:zbx_type_text`.
* `name`: is the name of the item (default: "Exomeeter <key>")

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
