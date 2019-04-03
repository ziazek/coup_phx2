defmodule CoupEngine.Deck do
  @moduledoc """
  Generates a deck
  """

  @type card :: %{type: String.t()}
  @spec build(number_of_each_type :: pos_integer()) :: [card()]
  def build(number_of_each_type) do
    for type <- ["Captain", "Duke", "Ambassador", "Assassin", "Contessa"],
        _n <- 1..number_of_each_type do
      %{type: type}
    end
  end
end
