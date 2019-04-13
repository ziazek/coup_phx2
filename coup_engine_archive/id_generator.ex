defmodule CoupEngineArchive.IdGenerator do
  @moduledoc """
  Generates a random string of any length.
  """
  @alphabet Enum.concat([?0..?9, ?A..?Z, ?a..?z])

  def randstring(count) do
    Stream.repeatedly(fn -> Enum.random(@alphabet) end)
    |> Enum.take(count)
    |> List.to_string()
  end
end
