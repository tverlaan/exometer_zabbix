defmodule Exometer.Report.Zabbix.Utils do
  @moduledoc """
  Common utils for Zabbix server and RPC
  """
  alias :exometer, as: Exometer

  @doc """
  Generate Zabbix key from metric + datapoint
  """
  def key(metric, dp) do
    metric ++ [dp]
    |> Enum.join(".")
  end

  @doc """
  Generate Zabbix application name from metric
  """
  def application([ app | _ ]) do
    "#{app}"
  end

  @doc """
  Generate Zabbix template name from metric
  """
  def template([ app | _ ]) do
    "Template App #{app}"
  end

  @zbx_type_float     0
  @zbx_type_character 1
  @zbx_type_log       2
  @zbx_type_unsigned  3
  @zbx_type_text      4

  @doc """
  Infer value type, fetching the value from exometer.

  WARNING: if value is a positive integer, it is considered unsigned. If you want to register 
  the item as signed, you must return a float.
  """
  def infer_type(metric, dp) do
    case Exometer.get_value(metric, dp) do
      v when is_float(v) -> :zbx_type_float
      v when is_integer(v) and v >= 0 -> :zbx_type_unsigned
      v when is_integer(v) -> :zbx_type_float
      _ -> :zbx_type_text
    end
  end

  @doc """
  Convert atom to zabbix type
  """
  def to_zbx_type(:zbx_type_float),     do: @zbx_type_float
  def to_zbx_type(:zbx_type_character), do: @zbx_type_character
  def to_zbx_type(:zbx_type_log),       do: @zbx_type_log
  def to_zbx_type(:zbx_type_unsigned),  do: @zbx_type_unsigned
  def to_zbx_type(:zbx_type_text),      do: @zbx_type_text
end
