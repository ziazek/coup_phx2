defmodule CoupEngine.GameSupervisor do
  use Supervisor

  alias CoupEngine.Game

  def start_link(_options), do: Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def start_game({game_name, session_id, player_name}) do
    Supervisor.start_child(__MODULE__, [{game_name, session_id, player_name}])
  end

  def init(:ok), do: Supervisor.init([Game], strategy: :simple_one_for_one)

  # defp pid_from_name(name) do
  #   name
  #   |> Game.via_tuple()
  #   |> GenServer.whereis()
  # end
end
