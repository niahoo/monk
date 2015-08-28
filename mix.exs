defmodule Monk.Mixfile do
  use Mix.Project

  def project do
    [app: :monk,
     version: "0.0.1",
     elixir: "~> 1.0",
     description: "Monk helps to distinguish good from evil with an simple ok/error monad",
     package: [
       contributors: ["Ludovic Demblans"],
       licenses: ["MIT"],
       links: %{"GitHub" => "https://github.com/niahoo/monk"}
     ],
     deps: deps]
  end

  def application do
    []
  end

  defp deps do
    []
  end
end
