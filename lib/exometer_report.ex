defmodule Exometer.Report do
  @moduledoc """
  Behaviour module for exometer_report in Elixir
  """

  @type state :: term
  @type callback_result :: {:ok, state} | :ignore

  @doc """
  Invoked when exometer reporter is started
  """
  @callback exometer_init(opts :: term) :: callback_result

  @doc """
  Invoked when a metric is being reported as part of a subscription
  """
  @callback exometer_report(  :exometer_report.metric(),
                              :exometer_report.datapoint(),
                              :exometer_report.extra(),
                              value :: term,
                              state
                            ) :: callback_result

  @doc """
  Invoked when reporter is being subscribed to a metric
  """
  @callback exometer_subscribe( :exometer_report.metric(),
                                :exometer_report.datapoint(),
                                :exometer_report.interval(),
                                :exometer_report.extra(),
                                state
                              ) :: callback_result

  @doc """
  Invoked when reporter is being unsubscribed from a metric
  """
  @callback exometer_unsubscribe( :exometer_report.metric(),
                                  :exometer_report.datapoint(),
                                  :exometer_report.extra(),
                                  state
                                ) :: callback_result

  @doc false
  @callback exometer_call(  msg :: term,
                            pid,
                            state
                          ) :: callback_result

  @doc false
  @callback exometer_cast(  msg :: term,
                            state
                          ) :: callback_result

  @doc false
  @callback exometer_info(  msg :: term,
                            state
                          ) :: callback_result

  @doc false
  @callback exometer_newentry(  :exometer.entry(),
                                state ) :: callback_result

  @doc false
  @callback exometer_setopts( :exometer_report.metric(),
                              opts :: term
                            ) :: callback_result
  @doc false
  @callback exometer_terminate( opts :: term,
                                state
                              ) :: callback_result

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour :exometer_report

      @doc false
      def exometer_subscribe(_metric, _datapoint, _interval, _opts, state) do
        {:ok, state}
      end

      @doc false
      def exometer_unsubscribe(_metric, _datapoint, _extra, state) do
        {:ok, state}
      end

      @doc false
      def exometer_call(_msg, _from, state) do
        {:ok, state}
      end

      @doc false
      def exometer_cast(_msg, state) do
        {:ok, state}
      end

      @doc false
      def exometer_info(_msg, state) do
        {:ok, state}
      end

      @doc false
      def exometer_newentry(_entry, state) do
        {:ok, state}
      end

      @doc false
      def exometer_setopts(_metric, _options, _status, state) do
        {:ok, state}
      end

      @doc false
      def exometer_terminate(_reason, _state) do
        :ignore
      end

      defoverridable [exometer_call: 3, exometer_cast: 2, exometer_info: 2,
                      exometer_newentry: 2, exometer_setopts: 4,
                      exometer_terminate: 2, exometer_subscribe: 5,
                      exometer_unsubscribe: 4]
    end
  end

end
