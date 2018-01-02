# Skiff

A [Raft][1] implementation in Elixir.

## Trying it out

```bash
% iex -S mix
{:ok, pid} = GenServer.start_link(Skiff, nil)
GenServer.call(pid, {:appendEntries, 2, 1, 1, 1, [], 1})
GenServer.call(pid, {:requestVote, 0, 2, 0, 0})
GenServer.call(pid, {:requestVote, 0, 2, 1, 0})
GenServer.call(pid, {:requestVote, 0, 2, 0, 2})
log = [
    %{:index => 32, :term => 3, :value => "32"},
    %{:index => 31, :term => 3, :value => "31"},
    %{:index => 30, :term => 3, :value => "30"},
    %{:index => 29, :term => 3, :value => "29"},
    %{:index => 28, :term => 3, :value => "28"},
    %{:index => 27, :term => 3, :value => "27"},
    %{:index => 26, :term => 3, :value => "26"},
    %{:index => 25, :term => 3, :value => "25"},
    %{:index => 24, :term => 3, :value => "24"},
    %{:index => 23, :term => 2, :value => "23"},
    %{:index => 22, :term => 2, :value => "22"},
    %{:index => 21, :term => 2, :value => "21"},
    %{:index => 20, :term => 2, :value => "20"},
    %{:index => 19, :term => 2, :value => "19"},
    %{:index => 18, :term => 2, :value => "18"},
    %{:index => 17, :term => 2, :value => "17"},
    %{:index => 16, :term => 2, :value => "16"},
    %{:index => 15, :term => 2, :value => "15"},
    %{:index => 14, :term => 2, :value => "14"},
    %{:index => 13, :term => 2, :value => "13"},
    %{:index => 12, :term => 2, :value => "12"},
    %{:index => 11, :term => 2, :value => "11"},
    %{:index => 10, :term => 1, :value => "10"},
    %{:index => 9, :term => 1, :value => "9"},
    %{:index => 8, :term => 1, :value => "8"},
    %{:index => 7, :term => 1, :value => "7"},
    %{:index => 6, :term => 1, :value => "6"},
    %{:index => 5, :term => 1, :value => "5"},
    %{:index => 4, :term => 1, :value => "4"},
    %{:index => 3, :term => 1, :value => "3"},
    %{:index => 2, :term => 1, :value => "2"},
    %{:index => 1, :term => 1, :value => "1"},
]
nil = Skiff.find_log_entry(log, 4, 4)
nil = Skiff.find_log_entry(log, 3, 3)
%{:index => 25, :term => 3, :value => "25"} = Skiff.find_log_entry(log, 3, 25)
nil = Skiff.find_log_entry(log, 0, 0)

tl = [%Skiff.LogEntry{term: 2, index: 2, value: "a"}, %Skiff.LogEntry{term: 1, index: 1, value: "b"}, %Skiff.LogEntry{term: 4, index: 1, value: "failed test"}]
nil = Skiff.find_log_entry(tl, 4, 1)
nil = Skiff.find_log_entry(tl, 2, 3)
%{term: 1, index: 1, value: "b"} = Skiff.find_log_entry(tl, 1, 1)
  #   search for 4,1
  #   expected result is nil because the term of the first item is too low to have a term of 4 come after
  #   search for 2,2
  #   expected result is nil because the terms match and the index is already too low.

ol1 = [%Skiff.LogEntry{term: 3, index: 3, value: "3"}, %Skiff.LogEntry{term: 2, index: 2, value: "2"}, %Skiff.LogEntry{term: 1, index: 1, value: "1"}]
nl1 = [%Skiff.LogEntry{term: 4, index: 4, value: "4"}, %Skiff.LogEntry{term: 3, index: 3, value: "3"}, %Skiff.LogEntry{term: 2, index: 2, value: "2"}]
el1 = [%Skiff.LogEntry{term: 4, index: 4, value: "4"}, %Skiff.LogEntry{term: 3, index: 3, value: "3"}, %Skiff.LogEntry{term: 2, index: 2, value: "2"}, %Skiff.LogEntry{term: 1, index: 1, value: "1"}]
^el1 = Skiff.merge_logs(nl1, ol1)

# it's possible to skip an entire term.
ol2 = [%Skiff.LogEntry{term: 3, index: 3, value: "3"}, %Skiff.LogEntry{term: 1, index: 2, value: "2"}, %Skiff.LogEntry{term: 1, index: 1, value: "1"}]
nl2 = [%Skiff.LogEntry{term: 4, index: 4, value: "4"}, %Skiff.LogEntry{term: 3, index: 3, value: "3"}, %Skiff.LogEntry{term: 2, index: 2, value: "2"}]
el2 = [%Skiff.LogEntry{term: 4, index: 4, value: "4"}, %Skiff.LogEntry{term: 3, index: 3, value: "3"}, %Skiff.LogEntry{term: 2, index: 2, value: "2"}, %Skiff.LogEntry{term: 1, index: 1, value: "1"}]
^el2 = Skiff.merge_logs(nl2, ol2)

GenServer.call(pid, {:appendEntries, 2, 1, 2, 1, [%Skiff.LogEntry{index: 3, term: 2, value: "3"}], 1})
2 = length(GenServer.call(pid, :state).log)
GenServer.call(pid, {:appendEntries, 2, 1, 2, 1, [%Skiff.LogEntry{index: 3, term: 3, value: "3"}], 1})
2 = length(GenServer.call(pid, :state).log)
false = GenServer.call(pid, {:appendEntries, 2, 1, 5, 5, [], 1})


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
