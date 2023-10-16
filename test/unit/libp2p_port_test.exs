defmodule Unit.Libp2pPortTest do
  use ExUnit.Case
  alias LambdaEthereumConsensus.Libp2pPort

  doctest Libp2pPort

  defp start_port(name \\ Libp2pPort, init_args \\ []) do
    start_link_supervised!({Libp2pPort, [opts: [name: name]] ++ init_args}, id: name)
  end

  test "start port", do: start_port()

  test "start multiple ports" do
    start_port()
    start_port(:host1)
    start_port(:host2)
    start_port(:host3)
  end

  test "set stream handler" do
    start_port()
    :ok = Libp2pPort.set_handler("/my-app/amazing-protocol/1.0.1")
  end

  test "start two hosts, and play one round of ping-pong" do
    # Setup sender
    start_port(:sender, listen_addr: ["/ip4/127.0.0.1/tcp/48787"])

    # Setup receiver
    recver_addr = ["/ip4/127.0.0.1/tcp/48789"]
    start_port(:recver, listen_addr: recver_addr)

    id = Libp2pPort.get_id(:recver)
    protocol_id = "/pong"
    pid = self()

    spawn_link(fn ->
      # (recver) Set stream handler
      :ok = Libp2pPort.set_handler(:recver, protocol_id)

      send(pid, :handler_set)

      # (recver) Read the "ping" message
      assert {^protocol_id, id, "ping"} = Libp2pPort.handle_request()
      :ok = Libp2pPort.send_response(:recver, id, "pong")

      send(pid, :message_received)
    end)

    # (sender) Wait for handler to be set
    assert_receive :handler_set, 1000

    # (sender) Add recver peer
    :ok = Libp2pPort.add_peer(:sender, id, recver_addr, 999_999_999_999)

    # (sender) Send "ping" to recver and receive "pong"
    assert {:ok, "pong"} = Libp2pPort.send_request(:sender, id, protocol_id, "ping")
    assert_receive :message_received, 1000
  end
end