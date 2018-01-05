defmodule ServerState do
  use GenStateMachine, callback_mode: [:handle_event_function,:state_enter]

  defmodule State do
    defstruct id: 0, current_term: 0, voted_for: nil, log: [], commit_index: 0, last_applied: 0, next_index: %{}, match_index: %{}, election_timeout: 3000, election_timeout_slop: 1000, nodes: [], new_nodes: []
  end
  defmodule AppendEntriesData do
    defstruct term: 0, leader_id: nil, prev_log_index: 0, prev_log_term: 0, entries: [], leader_commit: 0
  end
  defmodule RequestVoteData do
    defstruct term: 0, candidate_id: nil, last_log_index: 0, last_log_term: 0
  end

  #########################
  # index_and_term_gte_log

  # test if an index, term pair are >= a log's last entry
  # first, handle the easy cases
  defp index_and_term_gte_log(_index, term, [%{:term => log_term} | _rest]) when term > log_term, do: true
  defp index_and_term_gte_log(_index, term, [%{:term => log_term} | _rest]) when term < log_term, do: false
  # at this point, the terms must be equal.  test by index now.  if the log is more up to date...
  defp index_and_term_gte_log(index, _term, [%{:index => log_index} | _rest]) when index < log_index, do: false
  # finally, we've verified the log isn't *more* up to date (including when there's no log at all)
  defp index_and_term_gte_log(_index, _term, _), do: true

  #########################
  # random_election_timeout
  @doc """
  Generate a random election timeout time in ms averaging ~state.election_timeout.
  This is anywhere between timeout-slop..timeout+slop
  """
  def random_election_timeout(state) do
    :rand.uniform(state.election_timeout_slop * 2) + state.election_timeout - state.election_timeout_slop
  end

  def handle_event({:call, from}, {:append_entries, append_entries_data}, :leader, state) do
    if append_entries_data.term > state.current_term do
      {:next_state, :follower, %{state | current_term: append_entries_data.term}, [:postpone]}
    else
      {:keep_state, state, {:reply, from, {state.current_term, false}}}
    end
  end

  # {:ok, pid} = GenStateMachine.start_link(ServerState, nil)
  # GenStateMachine.call(pid, {:request_vote, %ServerState.RequestVoteData{term: 1, candidate_id: 2}})

  @doc """
  if the term in the RPC is lower than our current term, reject the RPC
  """
  def handle_event({:call, from}, event = {_, %{:term => rpc_term}}, _, state = %{:current_term => current_term}) when rpc_term < current_term do
    IO.inspect({"rejecting out of date term", current_term, rpc_term})
    {
      :keep_state, state, {:reply, from, {current_term, false}}
    }
  end

  @doc """
  if the term in the RPC is higher than our current term, convert to a follower and retry the RPC
  """
  def handle_event({:call, from}, event = {_, %{:term => rpc_term}}, _, state = %{:current_term => current_term}) when rpc_term > current_term do
    IO.inspect({"upgrading term", current_term, rpc_term})
    {
      :next_state, :follower, %{state | current_term: rpc_term},
      [{:next_event, {:call, from}, event}]
    }
  end

  # from here on, RPCs are valid and should be acted upon.

  @doc """
  We received a valid AppendEntriesRPC call.  Convert to follower since we must not be the leader
  and append the entries.
  """
  def handle_event({:call, from}, {:append_entries, append_entries_data}, _, state) do
    IO.inspect({"append_entries", append_entries_data})
    {:next_state, :follower, state, 
      [
        {:reply, from, {state.current_term, true}},
        {:state_timeout, random_election_timeout(state), :election_timeout},
      ]
    }
  end

  @doc """
  Entering follower state.  Start the election timeout.  Since we're not a candidate, clear our vote.
  """
  def handle_event(:enter, :follower, _, state) do
    {:keep_state, %{state | voted_for: nil},
      [
        {:state_timeout, random_election_timeout(state), :election_timeout},
        {{:timeout, :tick}, 10000, :tick},
      ]
    }
  end

  def handle_event({:timeout, :tick}, :tick, state_name, state) do
    IO.inspect({{:timeout, :tick}, :tick, state_name, state})
    {:keep_state, state,
      [
        {{:timeout, :tick}, 10000, :tick},
      ]
    }
  end

  @doc """
  Handle an election timeout as leader.  This shouldn't be possible because of state transition timeouts
  but putting this here just in case something breaks in the future.
  """
  def handle_event(:state_timeout, :election_timeout, :leader, state) do
    IO.inspect("Election timeout while leader.  This is a bug.")
    {:keep_state, %{state | voted_for: nil}}
  end

  def handle_event(:state_timeout, :election_timeout, cstate, state) do
    IO.inspect({"election_timeout", cstate})
    {:next_state, :candidate, %{state | voted_for: state.id, current_term: state.current_term + 1},
      [
        {:state_timeout, random_election_timeout(state), :election_timeout},
        {:next_event, :internal, :request_votes},
      ]
    }
  end

  @doc """
  Perform async request votes RPC call to all other nodes.
  Call this via `{:next_event, :internal, :request_votes}`
  """
  def handle_event(:internal, :request_votes, :candidate, state) do
    IO.inspect("TODO: REQUEST VOTES")
    {:keep_state, state}
  end

  @doc """
  Ignore request to request votes.  We're not a candidate so no one can vote for us.
  """
  def handle_event(:internal, :request_votes, _, state) do
    IO.inspect("received request votes instruction when not a candidate")
    {:keep_state, state}
  end

  @doc """
  We're a candidate.  Vote for ourselves.
  """
  def handle_event(:enter, :candidate, _, state) do
    {:keep_state, %{state | voted_for: state.id},
      [
        {:state_timeout, random_election_timeout(state), :election_timeout},
      ]
    }
  end

  @doc """
  We're a leader.  Tell the world by sending out some logs!
  """
  def handle_event(:enter, :leader, _, state) do
    {:keep_state, %{state | voted_for: nil},
      [
        {:state_timeout, 0, :heartbeat},
      ]
    }
  end

  @doc """
  Send out new entries.  When the match_index and next_index entries are initialized, this will
  send an empty AppendEntriesRPC.  These entries are intiailized when a leader is elected so
  this handler can be used for all uses of AppendEntriesRPC.

  Send immediately upon exit of another event via
  
      {:state_timeout, 0, :heartbeat}

  This must only be done while node type is :leader.
  """
  def handle_event(_, :heartbeat, :leader, state) do
    IO.inspect("TODO SEND HEARTBEAT")
    {:keep_state, state,
      [
        {:state_timeout, max(state.election_timeout - (state.election_timeout_slop * 2), state.election_timeout/3), :heartbeat},
      ]
  end

  @doc """
  We're not a candidate and we're not a follower.  Clear our vote.
  """
  def handle_event(:enter, _, _, state) do
    {:keep_state, %{state | voted_for: nil}}
  end

  def handle_event({:call, from}, {:request_vote, request_vote_data}, _, state) do
    IO.inspect({"request_vote", request_vote_data})

    with true <- (state.voted_for == nil or state.voted_for == request_vote_data.candidate_id),
         true <- index_and_term_gte_log(request_vote_data.last_log_index, request_vote_data.last_log_term, state.log)
    do
      {:keep_state, state, {:reply, from, {state.current_term, true}}}
    else
      _ -> {:keep_state, state, {:reply, from, {state.current_term, false}}}
    end
  end

  def handle_event(a, b, st, data) do
    IO.inspect({"Fallthrough event", a, b, st, data})
    {:keep_state, data}
  end

  def init(args) do
    {:ok, :follower, %State{}}
  end

  def candidate_up_to_date(rvd, state) do
    true
  end
end
