defmodule CoupEngine.PlayAgain do
  @moduledoc """
  Handles players opting in to play again with the same group.
  """

  @spec init() :: {:ok, String.t()}
  def init() do
    {:ok, CoupEngine.IdGenerator.randstring(6)}
  end
end
