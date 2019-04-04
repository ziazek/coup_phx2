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

  @spec draw_top_card([card()]) :: {:ok, card(), [card()]}
  def draw_top_card([head | tail] = _deck) do
    {:ok, head, tail}
  end
end
