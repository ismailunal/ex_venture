defmodule Game.Command.Whisper do
  @moduledoc """
  The "whisper" command
  """

  use Game.Command

  alias Game.Character
  alias Game.Utility

  commands(["whisper"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Whipser"
  def help(:short), do: "Whisper to someone in the same room as you"

  def help(:full) do
    """
    #{help(:short)}.

    Example:
    [ ] > {command}whisper player hello{/command}
    """
  end

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Whisper.parse("whisper player text")
      {:whisper, "player text"}

      iex> Game.Command.Whisper.parse("whisper")
      {:error, :bad_parse, "whisper"}

      iex> Game.Command.Whisper.parse("unknown hi")
      {:error, :bad_parse, "unknown hi"}
  """
  @spec parse(String.t()) :: {atom}
  def parse(command)
  def parse("whisper " <> text), do: {:whisper, text}

  @impl Game.Command
  @doc """
  Send to all connected players
  """
  def run(command, state)

  def run({:whisper, who_and_message}, state = %{user: user, save: save}) do
    room = @room.look(save.room_id)

    case find_character(room, who_and_message) do
      {:error, :not_found} ->
        state.socket |> @socket.echo("No character could be found matching your text.")

      character ->
        message = Utility.strip_name(elem(character, 1), who_and_message)
        state.socket |> @socket.echo(Format.send_whisper(character, message))
        Character.notify(character, {"room/whisper", Message.whisper(user, message)})

        room.id
        |> @room.notify(
          {:user, user},
          {"room/overheard", [{:user, user}, character], Format.whisper_overheard({:user, user}, character)}
        )
    end

    :ok
  end

  @doc """
  Find a character in a room by name.
  """
  @spec find_character(Room.t(), String.t()) ::
          {:error, :not_found}
          | {:npc, NPC.t()}
          | {:user, User.t()}

  def find_character(room, who_and_message) do
    case room.players |> Enum.find(&Utility.name_matches?(&1, who_and_message)) do
      nil ->
        case room.npcs |> Enum.find(&Utility.name_matches?(&1, who_and_message)) do
          nil ->
            {:error, :not_found}

          npc ->
            {:npc, npc}
        end

      player ->
        {:user, player}
    end
  end
end
