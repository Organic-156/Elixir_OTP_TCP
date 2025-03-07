# Chat - Elixir OTP & TCP Chat Server

A lightweight, multi-user chat server built with Elixir using OTP supervision and TCP sockets. This application demonstrates the principles of distributed systems, process management, and network communication in Elixir.

## Overview

This project implements a chat system with the following components:

- **Chat.Server**: An OTP GenServer that manages user registrations and message routing
- **Chat.ProxyServer**: A TCP server that handles client connections and command processing
- **ChatClient**: A simple TCP client for connecting to the chat server

## Features

- Nickname registration with validation
- Public broadcast messaging to all users
- Private messaging to specific users
- User listing
- Real-time message delivery 
- Connection management

## Commands

Once connected, users can interact with the chat server using the following commands:

- **/NICK \<nickname\>**: Set or change your nickname
- **/LIST**: Show all connected users
- **/MSG \<recipient(s)\> \<message\>**: Send a message to specific users (comma-separated) 
- **/MSG * \<message\>**: Broadcast a message to all connected users

## Installation

Add `chat` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:chat, "~> 0.1.0"}
  ]
end
```

## Usage

### Starting the Server

Open a Terminal in the Project Directory

Paste this command to start the Server

```
iex -S mix
# This command start a host at PORT 6666
# To change 
# 1. goto /lib/elixir_client.exs and change the port number
# 2. goto /lib/proxy_server.exs and change the port number in the start link to which server you want it to listen to 
# 3. goto /lib/application.ex and in the children change the port number for the Chat.ProxyServer
```

### Connecting as a Client

Open a separate Terminal in the Project Directory (same as above)

```
elixir client/elixir_client.exs
```

### Example Session

Note: All client must set a nickname before sending a message using /NICK 

```
Welcome! Set your nickname using /NICK <name>
> /NICK alice
Nickname set to alice
> /LIST
Users: alice, bob, charlie
> /MSG bob Hello there!
Message sent successfully.
> /MSG *,bob Welcome everyone and especially Bob!
Message broadcast to all users.
```

### Session Commands

Set or Change nickname
```
/NICK <name here>
```

Get a list of all connected users
```
/LIST
```

Broadcast a message to all users
```
/MSG * <message here>
```
Broadcast to a user/users (for users must be separated by commas ie: aa,bb,cc,dd with no space)
```
/MSG alice <message here>
```
```
/MSG alice, bob <message here>
```



## Architecture

The system is built on Elixir's OTP principles:

- **GenServer**: For state management and concurrency
- **ETS Tables**: For efficient user data storage
- **TCP Sockets**: For client communication
- **Process-based Message Passing**: For real-time message delivery

## Development

### Prerequisites

- Elixir 1.12 or later
- Erlang/OTP 24 or later

### Building

```bash
mix deps.get
mix compile
```

### Running Tests

Non Implemented YET
```bash
mix test
```


## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.