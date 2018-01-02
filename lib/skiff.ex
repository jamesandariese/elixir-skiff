defmodule Skiff do
  @moduledoc """
  Documentation for Skiff.
  """

  use GenServer

  defmodule State do
    defstruct currentTerm: 0, votedFor: nil, log: [%{:term => 1, :index => 2}], commitIndex: 0, lastApplied: 0, nextIndex: %{}, matchIndex: %{}
  end
  
  defmodule LogEntry do
    defstruct index: 0, term: 0, value: nil
  end

  def init(_args) do
    Process.register(self(), :skiff)
    {:ok, %State{}}
  end

  ########################
  # index_and_term_gte_log

  # test if an index, term pair are >= a log's last entry
  # first, handle the easy cases
  defp index_and_term_gte_log(_index, term, [%{:term => log_term} | _rest]) when term > log_term, do: true
  defp index_and_term_gte_log(_index, term, [%{:term => log_term} | _rest]) when term < log_term, do: false
  # at this point, the terms must be equal.  test by index now.  if the log is more up to date...
  defp index_and_term_gte_log(index, _term, [%{:index => log_index} | _rest]) when index < log_index, do: false
  # finally, we've verified the log isn't *more* up to date (including when there's no log at all)
  defp index_and_term_gte_log(_index, _term, _), do: true

  ########################
  # RequestVote

  @doc """
    Reject a vote request when the candidate's term is less than our current term.
  """
  def handle_call({:requestVote, term, _candidateId, _lastLogIndex, _lastLogTerm}, _from, state = %{:currentTerm => ct}) when term < ct do
    {:reply, {state.currentTerm, false}, state}
  end

  @doc """
    ...or accept a vote request when we've note voted yet or voted for this candidate and that candidate's log is at least as up to date as ours
    if we've gotten an update to our log since this candidate started their campaign tour, we will withdraw our vote
    """
    def handle_call({:requestVote, _term, candidateId, lastLogIndex, lastLogTerm}, _from, state = %{:votedFor => vf}) when vf == nil or vf == candidateId do
    # doing this `if` here instead of inside the guard only works because the fallthrough is what comes next.  if another test were to come after this,
    # it would break because the `if` here would short circuit any future tests.  this bit of messiness is because I don't know elixir yet.  sorry.
    if index_and_term_gte_log(lastLogIndex, lastLogTerm, state.log) do
      {:reply, {state.currentTerm, true}, %{state | votedFor: candidateId}}
    else
      {:reply, {state.currentTerm, false}, state}
    end
  end
  ############################################################################
  # if you're adding something here, check out the comment about 8 lines up. #
  ############################################################################
  @doc """
     ...otherwise, reject the vote request.
  """
  def handle_call({:requestVote, _term, _candidateId, _lastLogIndex, _lastLogTerm}, _from, state) do
    {:reply, {state.currentTerm, false}, state}
  end

  # find the log entry
  # testing for this should include terminating based on sorting
  # - have a log entry in the test at the end that is out of order and see if it finds it
  #   tl = [%LogEntry{term: 3, index: 3, value: "a"}, %LogEntry{term: 2, index: 1, value: "b"}, %LogEntry{term: 4, index: 1, value: "failed test"}]
  #   search for 4,1
  #   expected result is nil because the term of the first item is too low to have a term of 4 come after
  #   search for 2,2
  #   expected result is nil because the terms match and the index is already too low.
  def find_log_entry([], _term, _index), do: nil
  def find_log_entry([log = %{:term => log_term, :index => log_index} | _rest], term, index) when term == log_term and index == log_index, do: log
  def find_log_entry([%{:term => log_term, :index => log_index} | _rest], term, index) when term == log_term and index > log_index, do: nil
  def find_log_entry([%{:term => log_term} | _rest], term, _index) when term > log_term, do: nil
  def find_log_entry([_head | rest], term, index), do: find_log_entry(rest, term, index)

  ########################
  # AppendEntries
  @doc """
  """
  def handle_call({:appendEntries, term, leaderId, prevLogIndex, prevLogTerm, entries, leaderCommit}, _from, state) do
    if term < state.currentTerm do
      false
    else
    end
  end
end
