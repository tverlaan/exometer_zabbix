defmodule ExometerZabbix.Mixfile do
  use Mix.Project

  def project do
    [app: :exometer_zabbix,
     version: "0.0.3",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :exometer_core]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:exometer_core, github: "Feuerlabs/exometer_core", ref: "5fdd9426713a3c26cae32f644a3120711b1cdb64" },
      {:poison, "~> 1.5 or ~> 2.0"},
      {:meck, "~> 0.8.2", override: true },
      {:edown, "~> 0.7", override: true },

      {:earmark, "~> 0.2", only: :docs},
      {:ex_doc, "~> 0.11", only: :docs},
    ]
  end

  defp description do
    """
    A Zabbix reporter backend for exometer_core
    """
  end

  defp package do
    [# These are the default files included in the package
      files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["Timmo Verlaan"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/tverlaan/exometer_zabbix"}
    ]
  end

end
