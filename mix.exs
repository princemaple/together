defmodule Together.Mixfile do
  use Mix.Project

  def project do
    [app: :together,
     version: "0.2.1",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     package: package()]
  end

  def application do
    [applications: [:logger, :shards]]
  end

  defp deps do
    [{:shards, "~> 0.3.1"},
     {:ex_doc, ">= 0.0.0", only: :dev}]
  end

  defp package do
    [description: "Group actions that need to be performed later together",
     licenses: ["MIT"],
     maintainers: ["Po Chen"],
     links: %{"GitHub": "https://github.com/princemaple/together"}]
  end
end
