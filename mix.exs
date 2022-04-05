defmodule Noizu.KitchenSink.Mixfile do
  use Mix.Project

  def project do
    [app: :noizu_kitchen_sink,
      version: "0.3.10",
      elixir: "~> 1.13",
      package: package(),
      deps: deps(),
      description: "Noizu Kitchen Sink",
      docs: docs(),
      xref: [exclude: [UUID]],
      elixirc_paths: elixirc_paths(Mix.env),
    ]
  end # end project

  defp package do
    [
      maintainers: ["noizu"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/noizu/KitchenSink"}
    ]
  end # end package

  def application do
    [

      applications: [:logger],
      extra_applications: [
        :timex, :sendgrid, :amnesia, :fastglobal, :semaphore, :noizu_mnesia_versioning,
        :noizu_core, :noizu_scaffolding, :noizu_simple_pool,
        :noizu_rule_engine, :poison, :markdown]

    ]
  end # end application

  defp deps do
    [
      {:ex_doc, "~> 0.28.3", only: [:dev], optional: true}, # Documentation Provider
      {:markdown, github: "devinus/markdown", optional: false}, # Markdown processor for ex_doc
      {:noizu_simple_pool, github: "noizu/SimplePool", tag: "2.2.2"},
      {:noizu_rule_engine, github: "noizu/RuleEngine", tag: "0.2.1"},
      {:fastglobal, "~> 1.0"}, # https://github.com/discordapp/fastglobal
      {:semaphore, "~> 1.0"}, # https://github.com/discordapp/semaphore
      {:tzdata, "~> 1.1"},
      {:timex, "~> 3.7"},
      {:sendgrid, github: "Noizu/sendgrid_elixir", branch: "master"},
      {:mock, "~> 0.3.1", optional: true},
      {:poison, "~> 3.1.0", optional: true},
      {:plug, "~> 1.0", optional: true},
      {:elixir_uuid, "~> 1.2", optional: true},
      {:redix, github: "whatyouhide/redix", tag: "v0.7.0", optional: true},
    ]
  end # end deps

  defp docs do
    [
      source_url_pattern: "https://github.com/noizu/KitchenSink/blob/master/%{path}#L%{line}",
      extras: ["README.md"]
    ]
  end # end docs


  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

end # end defmodule
