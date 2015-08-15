defmodule Nativegen.Mixfile do
  use Mix.Project

  def project do
    [app: :nativegen,
     version: "0.1.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     description: description,
     package: package,
     test_coverage: [tool: Coverex.Task, coveralls: true]
   ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  defp description do
    """
    Accessible REST API code generator for native app.
    """
  end

  defp package do
    [contributors: ["Takuma Yoshida"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/yoavlt/nativegen"},
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:earmark, ">= 0.0.0", only: :dev},
      {:ex_doc, "~> 0.8", only: :dev},
      {:coverex, "~> 1.4.1", only: :test}
    ]
  end
end
