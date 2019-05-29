defmodule CoupEngine.Toast do
  @moduledoc """
  A Toast to display the current game happenings
  """
  defstruct body: nil, timestamp: nil

  # alias __MODULE__

  @spec initialize(String.t()) :: %__MODULE__{}
  def initialize(body) do
    %__MODULE__{body: body, timestamp: DateTime.utc_now() |> DateTime.to_unix()}
  end

  @spec add([%__MODULE__{}], String.t()) :: [%__MODULE__{}]
  def add(toast_list, body) do
    toast_list ++ [initialize(body)]
    # |> Enum.take(2)
  end
end
