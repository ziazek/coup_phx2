defmodule CoupEngine.Game do
  @moduledoc """
  This Genserver encapsulates a single game of Coup.
  """

  use GenServer

  alias CoupEngine.{Deck, Player}

  ### SERVER ###

  @spec init({String.t(), String.t(), String.t()}) :: {:ok, map()}
  def init({game_name, session_id, player_name}) do
    {:ok,
     %{
       game_name: game_name,
       players: [
         Player.initialize(session_id, player_name, %{role: "creator"})
       ],
       deck: Deck.build(3),
       state: "init"
     }}
  end
end
