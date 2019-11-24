defmodule Monies do
  def main(_args) do
    CommandLine.write("Welcome!")
    run(load_initial_state())
  end

  def run(state) do
    read_command(state)
  end

  def load_initial_state do
    if Persist.exists?() do
      Persist.read_state()
    else
      CommandLine.write("No monies file detected, time to create one!")
      init()
    end
  end

  def read_command(state) do
    CommandLine.write("What would you like to do?")

    [command | args] =
      CommandLine.read()
      |> String.downcase()
      |> String.split(" ")

    result = execute_command(state, command, args)

    case result do
      {:continue, new_state} -> read_command(new_state)
      {:quit} -> {:done}
    end
  end

  def choose_account(state) do
    state.accounts
    |> Enum.with_index()
    |> Enum.map(fn {account, index} -> "#{index + 1}: #{account.name}\n" end)
    |> CommandLine.write()

    CommandLine.read_integer() - 1
  end

  def commands do
    ["help", "init", "update balances", "rebalance", "contribute", "quit"]
  end

  def apply_changes(state, account_index, changes) do
    accounts =
      state.accounts
      |> List.update_at(account_index, fn account -> Account.apply_changes(account, changes) end)

    %{state | accounts: accounts}
  end

  def execute_command(_, "quit", []) do
    CommandLine.write("Goodbye!")
    {:quit}
  end

  def execute_command(state, "exit", []), do: execute_command(state, "quit", [])

  def execute_command(state, "help", []) do
    CommandLine.write("Commands: #{Enum.join(commands(), ", ")}")
    {:continue, state}
  end

  def execute_command(state, "rebalance", []) do
    changes = Account.divergence(state.accounts, state.target)
    IO.inspect(changes)

    prompt_result = CommandLine.confirm("Would you like to commit these changes?")

    if prompt_result == :yes do
      CommandLine.write("Which account would you like to rebalance with?")

      account_index = choose_account(state)
      new_state = Persist.write_state(apply_changes(state, account_index, changes))

      CommandLine.write("Done!")
      {:continue, new_state}
    else
      {:continue, state}
    end
  end

  def execute_command(state, "contribute", []) do
    CommandLine.write("How much?")

    changes =
      Account.calculate_contributions(state.accounts, state.target, CommandLine.read_dollar())

    IO.inspect(changes)

    prompt_result = CommandLine.confirm("Would you like to commit these changes?")

    if prompt_result == :yes do
      CommandLine.write("Which account would you like to contribue to?")

      account_index = choose_account(state)
      new_state = Persist.write_state(apply_changes(state, account_index, changes))

      CommandLine.write("Done!")
      {:continue, new_state}
    else
      {:continue, state}
    end
  end

  def execute_command(_, "init", []) do
    {:continue, init()}
  end

  def execute_command(state, "backup", []) do
    name = Persist.backup(state)
    CommandLine.write("Backup created! (#{name})")
    {:continue, state}
  end

  def execute_command(_, "update balances", []) do
    # TODO
  end

  def execute_command(_, "update target", []) do
    # TODO
  end

  def init do
    CommandLine.write("Creating a new monies file.")
    new_state = %{target: Target.read_target(), accounts: Account.read_accounts()}
    Persist.write_state(new_state)
    CommandLine.write("Initial monies file created!")
    new_state
  end
end
