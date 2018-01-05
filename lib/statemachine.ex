defmodule ServerState do
  use GenStateMachine, callback_mode: [:handle_event_function,:state_enter]

  defmodule State do
    defstruct id: 0, current_term: 0, voted_for: nil, log: [], commit_index: 0, last_applied: 0, next_index: %{}, matchIndex: %{}, election_timeout: 3000
  end
  defmodule AppendEntriesData do
    defstruct term: 0, leader_id: nil, prev_log_index: 0, prev_log_term: 0, entries: [], leader_commit: 0
  end
  defmodule RequestVoteData do
    defstruct term: 0, candidate_id: nil, last_log_index: 0, last_log_term: 0
  end

  def handle_event({:call, from}, {:append_entries, append_entries_data}, :leader, state) do
    if append_entries_data.term > state.current_term do
      {:next_state, :follower, %{state | current_term: append_entries_data.term}, [:postpone]}
    else
      {:keep_state, state, {:reply, from, {state.current_term, false}}}
    end
  end


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

  def handle_event({:call, from}, {:append_entries, append_entries_data}, _, state) do
    IO.inspect({"append_entries", append_entries_data})
    {:next_state, :follower, state, 
      [
        {:reply, from, {state.current_term, true}},
        {:state_timeout, state.election_timeout, :election_timeout},
      ]
    }
  end

  def handle_event(:enter, :follower, _, state) do
    {:keep_state, state,
      [
        {:state_timeout, state.election_timeout, :election_timeout},
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

  def handle_event(:state_timeout, :election_timeout, :leader, state) do
    {:keep_state, %{state | voted_for: nil}}
  end

  def handle_event(:state_timeout, :election_timeout, cstate, state) do
    IO.inspect({"election_timeout", cstate})
    {:next_state, :candidate, %{state | voted_for: state.id, current_term: state.current_term + 1},
      [
        {:state_timeout, state.election_timeout, :election_timeout},
        {:next_event, :internal, :request_votes},
      ]
    }
  end

  def handle_event(:internal, :request_votes, :candidate, state) do
    IO.inspect("TODO: REQUEST VOTES")
    {:keep_state, state}
  end

  def handle_event(:internal, :request_votes, _, state) do
    IO.inspect("received request votes instruction when not a candidate")
    {:keep_state, state}
  end

  def handle_event(:enter, :candidate, _, state) do
    {:keep_state, state,
      [
        {:state_timeout, state.election_timeout, :election_timeout},
      ]
    }
  end

  def handle_event({:call, from}, {:request_vote, request_vote_data}, _, state) do
    IO.inspect({"request_vote", request_vote_data})

    yesno = (
    if state.current_term > request_vote_data.term do
      false
    else
      if state.voted_for == nil and candidate_up_to_date(request_vote_data, state) do
        true
      else
        false
      end
    end
    )
    {:keep_state, state, {:reply, from, {state.current_term, yesno}}}
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
