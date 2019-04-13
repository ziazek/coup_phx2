defmodule CoupEngineArchive.Response do
  @moduledoc """
  Opponent response in a Turn
  """
  defstruct player: nil, response: :pending, claimed_character: nil
end
