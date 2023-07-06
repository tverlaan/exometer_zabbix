defmodule ExometerZabbix.Mixfile do
  use Mix.Project

  @version "1.0.0"
  @url "https://github.com/tverlaan/exometer_zabbix"

  def project do
    [
      app: :exometer_zabbix,
      version: @version,
      elixir: "~> 1.8",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: "A Zabbix reporter backend for exometer_core",
      package: package(),
      docs: docs(),
      deps: deps()
    ]
  end

  defp deps do
    [
      {:exometer_core, "~> 1.5"},
      {:jason, "~> 1.0", runtime: false},
      {:earmark, "~> 1.2", only: :dev, runtime: false},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end

  defp docs() do
    [
      main: "Exometer.Report.Zabbix",
      source_ref: "v#{@version}",
      source_url: @url
    ]
  end

  defp package do
    [
      maintainers: ["Timmo Verlaan"],
      licenses: ["MIT"],
      links: %{"GitHub" => @url}
    ]
  end
end
