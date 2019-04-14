defmodule CoupEngine.Toast do
  @moduledoc """
  A Toast to display the current game happenings
  """
  defstruct body: nil

  alias __MODULE__

  @spec initialize(String.t()) :: %__MODULE__{}
  def initialize(body) do
    %__MODULE__{body: body}
  end
end
