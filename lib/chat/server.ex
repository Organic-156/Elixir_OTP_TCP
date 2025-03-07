defmodule Chat.Server do
  use GenServer

  # Map: 
  @table :chat_users

  ## API - - - - - 

  # Start Link
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # Register Nickname
  def register_nickname(pid, nickname) do
    GenServer.call(__MODULE__, {:register_nickname, pid, nickname})
  end

  # List Users
  def list_users do
    GenServer.call(__MODULE__, :list_users)
  end

  # Send Message
  def send_message(sender_pid, recipients, message) do
    GenServer.call(__MODULE__, {:send_message, sender_pid, recipients, message})
  end

  # Remove User
  def remove_user(pid) do
    GenServer.cast(__MODULE__, {:remove_user, pid})
  end

  ## Callbacks - - - - - - 
  def init(state) do
    :ets.new(@table, [:set, :public, :named_table])
    {:ok, state}
  end

  # HANDLE CALL :register_nickname
  def handle_call({:register_nickname, pid, nickname}, _from, state) do
    IO.puts("Registering nickname: '#{nickname}' for PID: #{inspect(pid)}")
    
    # Remove any existing nickname for this PID first
    remove_existing_nickname(pid)
    
    if valid_nickname?(nickname) && !nickname_in_use?(nickname) do
      :ets.insert(@table, {nickname, pid})
      {:reply, {:ok, "Nickname set to #{nickname}"}, state}
    else
      {:reply, {:error, "Invalid or taken nickname"}, state}
    end
  end

  # HANDLE CALL :list_users
  def handle_call(:list_users, _from, state) do
    users = :ets.tab2list(@table) |> Enum.map(fn {nick, _} -> nick end)
    {:reply, users, state}
  end

  # HANDLE CALL :send_message
  def handle_call({:send_message, sender_pid, recipients, message}, _from, state) do
    sender_nick = find_nickname(sender_pid)
    IO.puts("Sending message from: #{sender_nick} (#{inspect(sender_pid)}) to: #{recipients}")
    
    
    IO.puts("Current users in table:") # Debug: print all users in the ETS table
    :ets.tab2list(@table) |> Enum.each(fn {nick, pid} -> 
      IO.puts("  #{nick}: #{inspect(pid)}") 
    end)

    result = case sender_nick do
      nil -> {:error, "You must set a nickname before sending messages."}
      _ ->
        if recipients == "*" do # Send to All
          broadcast(sender_nick, message) 
        else                    # Send to Selected Users
          send_to_users(sender_pid, sender_nick, recipients, message)
        end
    end

    {:reply, result, state}
  end

  # HANDLE CAST :remove_user
  def handle_cast({:remove_user, pid}, state) do
    IO.puts("Removing user with PID: #{inspect(pid)}")
    :ets.match_delete(@table, {:_, pid})
    {:noreply, state}
  end

  ## Helper Functions
  defp valid_nickname?(nickname) do
    Regex.match?(~r/^[a-zA-Z][a-zA-Z0-9_]{0,11}$/, nickname)
  end

  # check if nick is used
  defp nickname_in_use?(nickname) do
    :ets.lookup(@table, nickname) != []
  end

  # find nick name
  defp find_nickname(pid) do
    case :ets.match_object(@table, {:"$1", pid}) do
      [{nick, _}] -> nick
      [] -> nil
    end
  end

  # broadcast "*"
  defp broadcast(sender_nick, message) do
    IO.puts("Broadcasting message from #{sender_nick}: #{message}")
    
    users = :ets.tab2list(@table)
    IO.puts("Sending to #{length(users)} users")
    
    users |> Enum.each(fn {nick, pid} ->
      IO.puts("  Sending to #{nick} (#{inspect(pid)})")
      send(pid, {:chat_message, sender_nick, message})
    end)
    
    {:ok, "Message broadcast to all users."}
  end

  # Helper function to remove existing nickname for a PID
  defp remove_existing_nickname(pid) do
    case find_nickname(pid) do
      nil -> :ok  # No existing nickname
      old_nick ->
        IO.puts("Removing old nickname '#{old_nick}' for PID: #{inspect(pid)}")
        :ets.delete(@table, old_nick)
    end
  end

  # send to selected users
  defp send_to_users(_sender_pid, sender_nick, recipients, message) do
    recipients_list = String.split(recipients, ",") |> Enum.map(&String.trim/1)
    IO.puts("Parsed recipients: #{inspect(recipients_list)}")
    
    results = Enum.map(recipients_list, fn recipient ->
      IO.puts("Looking up recipient: #{recipient}")
      
      case :ets.lookup(@table, recipient) do
        [{^recipient, pid}] ->
          IO.puts("  Found recipient #{recipient} with PID: #{inspect(pid)}")
          send(pid, {:chat_message, sender_nick, message})
          {:ok, recipient}
        
        [] ->
          IO.puts("  Recipient not found: #{recipient}")
          {:error, "User #{recipient} does not exist."}
      end
    end)
  
    errors = for {:error, msg} <- results, do: msg
    
    if Enum.empty?(errors) do
      {:ok, "Message sent successfully."}
    else
      {:error, Enum.join(errors, ", ")}
    end
  end
end