defmodule PubSubMock do
  @moduledoc """
  Mock for Phoenix.PubSub
  """
  def broadcast(_pubsub_name, channel, message) do
    send(self(), {channel, message})
  end
end
