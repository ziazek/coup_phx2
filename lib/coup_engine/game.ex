defmodule CoupEngine.Game do
  @moduledoc """
  This Genserver encapsulates a single game of Coup.
  """
  use GenServer
  alias CoupEngine.Rules

  @spec init(String.t()) :: {:ok, map()}
  def init(name) do
    {:ok,
     %{
       players: [%{name: name, role: "creator"}],
       deck: [],
       discard: [],
       rules: %Rules{state: :adding_players}
     }}
  end

  @spec handle_call({:add_player, String.t()}, any(), map()) :: {:reply, :ok | :error, map()}
  def handle_call({:add_player, name}, _from, %{players: players} = state_data) do
    with {:ok, rules} <- Rules.check(state_data.rules, :add_player, length(players)) do
      updated_players = players ++ [%{name: name, role: "player"}]

      state_data
      |> Map.put(:players, updated_players)
      |> Map.put(:rules, rules)
      |> reply_success(:ok)
    else
      {:error, reason} -> {:reply, {:error, reason}, state_data}
    end
  end

  def handle_call(:start_game, _from, %{players: players} = state_data) do
    with {:ok, rules} <- Rules.check(state_data.rules, :start_game, length(players)) do
      # TODO: send to self
      # Process.send_after(self(), :shuffle_deck, 1_000)
      # then handle_info
      state_data
      |> Map.put(:rules, rules)
      |> reply_success(:ok)
    else
      {:error, reason} -> {:reply, {:error, reason}, state_data}
    end
  end

  defp reply_success(state_data, reply) do
    {:reply, reply, state_data}
  end
end
