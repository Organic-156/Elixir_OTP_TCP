defmodule ChatClient do

  # Start Host at 6666
  def start(host \\ ~c"localhost", port \\ 6666) do
    case :gen_tcp.connect(host, port, [:binary, active: false]) do
      {:ok, socket} ->
        spawn(fn -> listen_for_messages(socket) end)
        loop_send(socket)

      {:error, reason} ->
        IO.puts("Error connecting to chat server: #{inspect(reason)}")
    end
  end

  # Client Listening for MEssage
  defp listen_for_messages(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, message} ->
        IO.puts(message)
        listen_for_messages(socket)  # Keep listening loop

      {:error, :closed} ->
        IO.puts("Disconnected from server.")
        exit(:normal)

      {:error, reason} ->
        IO.puts("Error receiving message: #{inspect(reason)}")
        listen_for_messages(socket)
    end
  end

  # Close 
  defp loop_send(socket) do
    input = IO.gets("> ")

    if input == :eof do
      IO.puts("Exiting chat...")
      :gen_tcp.close(socket)
      exit(:normal)
    else
      :gen_tcp.send(socket, input)
      loop_send(socket)  # Keep waiting for new input
    end
  end
end

ChatClient.start()
