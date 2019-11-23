# Monies

My *famous* monies spreadsheet, in Elixir CLI form!

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `monies` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:monies, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/monies](https://hexdocs.pm/monies).


Format, compile, build, and run:

```
e() { mix format && mix compile && mix escript.build && ./monies; }
```

Do all those same things, but also start with a backup for easier debugging:

```
e() { cp monies-backup.json monies.json && mix format && mix compile && mix escript.build && ./monies; }
```