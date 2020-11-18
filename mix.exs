defmodule ExometerZabbix.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exometer_zabbix,
      version: "0.1.0",
      elixir: "~> 1.8",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:exometer_core, "~> 1.5"},
      {:jason, "~> 1.0", runtime: false},
      {:earmark, "~> 1.2", only: :dev, runtime: false},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    A Zabbix reporter backend for exometer_core
    """
  end

  defp package do
    # These are the default files included in the package
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["Timmo Verlaan"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/tverlaan/exometer_zabbix"}
    ]
  end
end
