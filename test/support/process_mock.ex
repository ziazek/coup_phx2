defmodule ProcessMock do
  @moduledoc """
  Mock for Process
  """

  def send_after(_pid, message, milliseconds) do
    send(self(), {message, milliseconds})
  end
end
