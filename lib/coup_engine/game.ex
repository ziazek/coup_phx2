defmodule CoupEngine.Game do
  @moduledoc """
  This Genserver encapsulates a single game of Coup.
  """
  use GenServer
  alias CoupEngine.Rules

  @spec init(binary()) :: {:ok, map()}
  def init(name) do
    {:ok, %{players: [%{name: name, role: "creator"}], deck: [], discard: [], rules: %Rules{}}}
  end

  @spec handle_call({:add_player, binary()}, any(), map()) :: {:reply, :ok | :error, map()}
  def handle_call({:add_player, name}, _from, %{players: players} = state_data) do
    updated_players = players ++ [%{name: name, role: "player"}]

    state_data
    |> Map.put(:players, updated_players)
    |> reply_success(:ok)
  end

  defp reply_success(state_data, reply) do
    {:reply, reply, state_data}
  end
end
