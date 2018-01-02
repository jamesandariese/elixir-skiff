# Skiff

A [Raft][1] implementation in Elixir.

## Trying it out

```bash
% iex -S mix
{:ok, pid} = GenServer.start_link(Skiff, nil)
GenServer.call(pid, {:requestVote, 0, 2, 0, 0})
GenServer.call(pid, {:requestVote, 0, 2, 1, 0})
GenServer.call(pid, {:requestVote, 0, 2, 0, 2})
```


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `skiff` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:skiff, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/skiff](https://hexdocs.pm/skiff).

[1]: https://raft.github.io/raft.pdf
