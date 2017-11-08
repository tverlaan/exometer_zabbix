defmodule Zabbix do
  @moduledoc """
  Zabbix JSON-RPC wrapper
  """
  use GenServer
  require Logger

  @type t :: %__MODULE__{
    url: String.t,
    token: String.t | nil
  }
  defstruct url: '', token: nil

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  ###
  ### GenServer callbacks
  ###
  def init(_) do
    Logger.info("Start Zabbix client")
    user = Application.get_env(:exometer_zabbix, :rpcuser)
    password = Application.get_env(:exometer_zabbix, :rpcpassword)
    url = '#{Application.get_env(:exometer_zabbix, :rpcurl)}'

    do_connect(user, password, %__MODULE__{ url: url })
  end

  ###
  ### Priv
  ###
  defp do_connect(user, password, s) do
    Logger.debug("[ZBX] Authentication")
    case rpc_call("user.login", %{ "user" => user, "password" => password }, s) do
      {:ok, token} ->
	Logger.debug("[ZBX] login succesful")
	{:ok, %{ s | token: token }}
      {:error, reason} ->
	Logger.debug("[ZBX] login failed: #{inspect reason}")
	{:error, reason}
    end
  end

  defp rpc_call(method, params, %__MODULE__{ url: url, token: token }) do
    ct = 'application/json-rpc'
    opts = []
    case :httpc.request(:post, {url, [{'content-type', 'application/json-rpc'}], ct, rpc_encode(method, params, token)}, [], opts) do
      {:ok, {{_vsn, 200, _reason}, _headers, body}} ->
	rpc_decode(body)

      {:ok, {{_vsn, status_code, _reason}, headers, body}} ->
	{:error, {:http_request_failed, status_code, headers, body}}

      {:error, reason} ->
	{:error, reason}
    end
  end

  defp rpc_encode(method, params, auth) do
    Poison.encode!(
      %{
	"jsonrpc" => "2.0",
	"method" => method,
	"id" => 1,
	"auth" => auth,
	"params" => params
      })
  end

  defp rpc_decode(body) do
    case Poison.decode(body) do
      {:ok, %{"jsonrpc" => "2.0", "id" => _id, "result" => result}} ->
  	{:ok, result}
	
      {:ok, %{"jsonrpc" => "2.0", "id" => _id, "error" => error}} ->
  	{:error, {error["code"], error["message"], error["data"]}}

      {:ok, response} ->
  	{:error, {:invalid_response, response}}

      {:error, error} ->
  	{:error, error}
    end
  end
end
