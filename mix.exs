defmodule Together.Mixfile do
  use Mix.Project

  def project do
    [app: :together,
     version: "0.5.1",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     package: package()]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:ex_shards, "~> 0.2"},
     {:ex_doc, ">= 0.0.0", only: :dev}]
  end

  defp package do
    [description: "Group actions that need to be performed later together",
     licenses: ["MIT"],
     maintainers: ["Po Chen"],
     links: %{"GitHub": "https://github.com/princemaple/together"}]
  end
end
