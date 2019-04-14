defmodule PubSubMock do
  def broadcast(_pubsub_name, channel, message) do
    send(self(), {channel, message})
  end
end
