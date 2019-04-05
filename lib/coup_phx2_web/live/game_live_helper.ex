defmodule CoupPhx2Web.GameLive.Helper do
  def is_player_turn(%{turn: turn} = data, session_id) when not is_nil(turn) do
    turn.player.session_id == session_id
  end

  def is_player_turn(_, _), do: false
end
