defmodule Skiff do
  @moduledoc """
  Documentation for Skiff.
  """

  use GenServer

  def init(_args) do
    Process.register(self(), :skiff)
    {:ok, %{
      :currentTerm => 0,
      :votedFor => nil,
      :log => [%{:term => 1, :index => 2}],
      :commitIndex => 0,
      :lastApplied => 0,
      :nextIndex => %{},
      :matchIndex => %{},
    }}
  end

  
  # test if an index, term pair are >= a log's last entry
  # first, handle the easy cases
  defp index_and_term_gte_log(_index, term, [%{:term => log_term} | _rest]) when term > log_term, do: true
  defp index_and_term_gte_log(_index, term, [%{:term => log_term} | _rest]) when term < log_term, do: false
  # at this point, the terms must be equal.  test by index now.  if the log is more up to date...
  defp index_and_term_gte_log(index, _term, [%{:index => log_index} | _rest]) when index < log_index, do: false
  # finally, we've verified the log isn't *more* up to date (including when there's no log at all)
  defp index_and_term_gte_log(_index, _term, _), do: true

  @doc """
    Reject a vote request when the candidate's term is less than our current term.
  """
  def handle_call({:requestVote, term, _candidateId, _lastLogIndex, _lastLogTerm}, _from, state = %{:currentTerm => ct}) when term < ct do
    {:reply, {state[:currentTerm], false}, state}
  end

  @doc """
    ...or accept a vote request when we've note voted yet and that candidate's log is at least as up to date as ours
  """
  def handle_call({:requestVote, _term, candidateId, lastLogIndex, lastLogTerm}, _from, state = %{:votedFor => nil}) do
    if index_and_term_gte_log(lastLogIndex, lastLogTerm, state[:log]) do
      {:reply, {state[:currentTerm], true}, Map.put(state, :votedFor, candidateId)}
    else
      {:reply, {state[:currentTerm], false}, state}
    end
  end

  @doc """
    ...or accept a vote if the candidate requesting the vote is still our chosen candidate
  """
  def handle_call({:requestVote, _term, candidateId, _lastLogIndex, _lastLogTerm}, _from, state = %{:votedFor => vf}) when vf == candidateId do
    {:reply, {state[:currentTerm], true}, state}
  end

  @doc """
     ...otherwise, reject the vote request.
  """
  def handle_call({:requestVote, _term, _candidateId, _lastLogIndex, _lastLogTerm}, _from, state) do
    {:reply, {state[:currentTerm], false}, state}
  end
end
