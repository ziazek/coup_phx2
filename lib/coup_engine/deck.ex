defmodule CoupEngine.Deck do
  @moduledoc """
  Generates a deck
  """

  alias CoupEngine.Card

  @spec build(number_of_each_type :: pos_integer()) :: [%Card{}]
  def build(number_of_each_type) do
    for type <- ["Captain", "Duke", "Ambassador", "Assassin", "Contessa"],
        _n <- 1..number_of_each_type do
      %Card{type: type}
    end
  end

  @spec draw_top_card([%Card{}]) :: {:ok, %Card{}, [%Card{}]}
  def draw_top_card([head | tail] = _deck) do
    {:ok, head, tail}
  end
end
