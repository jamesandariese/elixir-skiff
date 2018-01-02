# Skiff

A [Raft][1] implementation in Elixir.

## Trying it out

```bash
% iex -S mix
{:ok, pid} = GenServer.start_link(Skiff, nil)
GenServer.call(pid, {:requestVote, 0, 2, 0, 0})
GenServer.call(pid, {:requestVote, 0, 2, 1, 0})
GenServer.call(pid, {:requestVote, 0, 2, 0, 2})
log = [
    %{:index => 9, :term => 3, :value => 32},
    %{:index => 8, :term => 3, :value => 31},
    %{:index => 7, :term => 3, :value => 30},
    %{:index => 6, :term => 3, :value => 29},
    %{:index => 5, :term => 3, :value => 28},
    %{:index => 4, :term => 3, :value => 27},
    %{:index => 3, :term => 3, :value => 26},
    %{:index => 2, :term => 3, :value => 25},
    %{:index => 1, :term => 3, :value => 24},
    %{:index => 13, :term => 2, :value => 23},
    %{:index => 12, :term => 2, :value => 22},
    %{:index => 11, :term => 2, :value => 21},
    %{:index => 10, :term => 2, :value => 20},
    %{:index => 9, :term => 2, :value => 19},
    %{:index => 8, :term => 2, :value => 18},
    %{:index => 7, :term => 2, :value => 17},
    %{:index => 6, :term => 2, :value => 16},
    %{:index => 5, :term => 2, :value => 15},
    %{:index => 4, :term => 2, :value => 14},
    %{:index => 3, :term => 2, :value => 13},
    %{:index => 2, :term => 2, :value => 12},
    %{:index => 1, :term => 2, :value => 11},
    %{:index => 10, :term => 1, :value => 10},
    %{:index => 9, :term => 1, :value => 9},
    %{:index => 8, :term => 1, :value => 8},
    %{:index => 7, :term => 1, :value => 7},
    %{:index => 6, :term => 1, :value => 6},
    %{:index => 5, :term => 1, :value => 5},
    %{:index => 4, :term => 1, :value => 4},
    %{:index => 3, :term => 1, :value => 3},
    %{:index => 2, :term => 1, :value => 2},
    %{:index => 1, :term => 1, :value => 1},
]
Skiff.find_log_entry(log, 4, 4)
Skiff.find_log_entry(log, 3, 3)
Skiff.find_log_entry(log, 0, 0)
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
