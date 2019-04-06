defmodule Concept.GameSupervisor do
  @moduledoc """
  Game dynamic supervisor.
  """
  use DynamicSupervisor
  alias Concept.Game

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_game({game_name, session_id, player_name}) do
    child_spec = {Game, {game_name, session_id, player_name}}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  # Terminate a Player process and remove it from supervision
  def remove_game(game_pid) do
    DynamicSupervisor.terminate_child(__MODULE__, game_pid)
  end

  # Nice utility method to check which processes are under supervision
  def children do
    DynamicSupervisor.which_children(__MODULE__)
  end

  # Nice utility method to check which processes are under supervision
  def count_children do
    DynamicSupervisor.count_children(__MODULE__)
  end
end
