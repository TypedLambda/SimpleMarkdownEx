defmodule SimpleMarkdown.Mixfile do
    use Mix.Project

    def project do
        [
            app: :simple_markdown,
            description: "A simple and extendable Markdown converter",
            version: "0.5.4",
            elixir: "~> 1.3",
            build_embedded: Mix.env == :prod,
            start_permanent: Mix.env == :prod,
            consolidate_protocols: Mix.env != :test,
            deps: deps(),
            dialyzer: [plt_add_deps: true],
            package: package()
        ]
    end

    # Configuration for the OTP application
    #
    # Type `mix help compile.app` for more information
    def application do
        [applications: [:parsey, :html_entities, :logger]]
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
            { :parsey, "~> 0.0.3" },
            { :html_entities, "~> 0.3" }
        ] ++ if(Version.compare(System.version, "1.7.0") == :lt, do: [{ :earmark, "~> 0.1", only: :dev }, { :ex_doc, "~> 0.7", only: :dev }], else: [{ :ex_doc, "~> 0.19", only: :dev, runtime: false }])
    end

    defp package do
        [
            maintainers: ["Stefan Johnson"],
            licenses: ["BSD 2-Clause"],
            links: %{ "GitHub" => "https://github.com/ScrimpyCat/SimpleMarkdownEx" }
        ]
    end
end
