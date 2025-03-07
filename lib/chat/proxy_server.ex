defmodule Chat.ProxyServer do
  use GenServer

  # Start Link Proxy at 6666
  def start_link(port \\ 6666) do
    GenServer.start_link(__MODULE__, port, [])
  end

  # Init
  def init(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, active: false, reuseaddr: true])
    IO.puts("Proxy server listening on port #{port}")
    spawn(fn -> accept_connections(socket) end)
    {:ok, socket}
  end

  # accept Connections
  defp accept_connections(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    IO.puts("New client connected: #{inspect(client)}")
    spawn(fn -> handle_client(client) end)
    accept_connections(socket)
  end

  # Handle Clinet
  defp handle_client(socket) do
    client_pid = self()
    # Print new PID in Proxy Terminal (Where I will start the server)
    IO.puts("Handling client with PID: #{inspect(client_pid)}")
    
    # New Users receive a message
    send_message(socket, "Welcome! Set your nickname using /NICK <name>\n")
    
    # Start a message listener process
    listener_pid = spawn(fn -> listen_for_messages(socket, client_pid) end)
    IO.puts("Started message listener with PID: #{inspect(listener_pid)}") # Log after a new user joins 
    
    loop_client(socket, nil, listener_pid)
  end

  # Message Listener
  defp listen_for_messages(socket, client_pid) do
    IO.puts("Message listener for client #{inspect(client_pid)} waiting for messages..." ) # DEBUG listener
    
    receive do
      {:chat_message, sender, msg} ->
        IO.puts("RECEIVED MESSAGE: from #{sender}: #{msg}")
        send_message(socket, "#{sender}: #{msg}\n")
        listen_for_messages(socket, client_pid)

      {:error, error_msg} ->
        IO.puts("RECEIVED ERROR: #{error_msg}")
        send_message(socket, "Error: #{error_msg}\n")
        listen_for_messages(socket, client_pid)
        
      other ->
        IO.puts("RECEIVED UNKNOWN MESSAGE: #{inspect(other)}")
        listen_for_messages(socket, client_pid)

    after 2000 -> 
      
      IO.puts("Message listener for #{inspect(client_pid)} still waiting...") # DEBUG Log every 2 seconds that we're still alive
      listen_for_messages(socket, client_pid)
    end
  end

  # Loop Client
  defp loop_client(socket, nickname, listener_pid) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        trimmed_data = String.trim(data)
        IO.puts("Received command: #{trimmed_data}") # Log for Received Command
        nickname = handle_command(trimmed_data, socket, nickname, listener_pid)
        loop_client(socket, nickname, listener_pid)

      {:error, reason} ->
        IO.puts("Client disconnected with reason: #{inspect(reason)}")
        if nickname, do: Chat.Server.remove_user(self())
        Process.exit(listener_pid, :normal)
        :gen_tcp.close(socket)
    end
  end

  # Function Pattern Matching
  # /NICK 
  defp handle_command("/NICK " <> nick, socket, _old_nick, listener_pid) do
    nickname = String.split(nick) |> hd()
    IO.puts("Setting nickname to: #{nickname}") # Log after setting a nickname
    
    case Chat.Server.register_nickname(listener_pid, nickname) do
      {:ok, msg} -> 
        send_message(socket, "#{msg}\n")
        nickname
      
      {:error, msg} -> 
        send_message(socket, "#{msg}\n")
        nil
    end
  end

  # /LIST
  defp handle_command("/LIST", socket, nick, _listener_pid) do
    users = Chat.Server.list_users()
    send_message(socket, "Users: #{Enum.join(users, ", ")}\n")
    nick
  end

  # /MSG
  defp handle_command("/MSG " <> rest, socket, nick, listener_pid) when is_binary(nick) do
    case String.split(rest, " ", parts: 2) do
      [recipients, message] -> 
        IO.puts("Sending message to #{recipients}: #{message}")
        
        case Chat.Server.send_message(listener_pid, recipients, message) do
          {:ok, response} ->
            IO.puts("Message sent successfully: #{response}")
            send_message(socket, "#{response}\n")
          
          {:error, error_msg} ->
            IO.puts("Error sending message: #{error_msg}")
            send_message(socket, "Error: #{error_msg}\n")
        end

      _ -> 
        send_message(socket, "Invalid message format. Use: /MSG <recipient(s)> <message>\n")
    end
    nick
  end

  # /MSG but with Unset nicknanme
  defp handle_command("/MSG " <> _rest, socket, nil, _listener_pid) do
    send_message(socket, "You must set a nickname before sending messages. Use: /NICK <name>\n")
    nil
  end

  # _ unknown command
  defp handle_command(cmd, socket, nick, _listener_pid) do
    IO.puts("Invalid command: #{cmd}")
    send_message(socket, "Invalid command. Available: /NICK, /LIST, /MSG\n")
    nick
  end

  # send message using tcp to the passsed socket
  defp send_message(socket, msg) do
    :gen_tcp.send(socket, msg)
  end
end