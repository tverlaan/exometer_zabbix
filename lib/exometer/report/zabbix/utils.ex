defmodule Exometer.Report.Zabbix.Utils do
  @moduledoc """
  Common utils for Zabbix server and RPC
  """

  @doc """
  Generate Zabbix key from metric + datapoint
  """
  def key(metric, dp) do
    metric ++ [dp]
    |> Enum.join(".")
  end  
end
