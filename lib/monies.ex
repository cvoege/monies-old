defmodule Monies do
  @file_name "monies.json"
  def file_name, do: @file_name

  def main(_args) do
    IO.puts("Welcome!")
    run(read_state())
  end

  def read_state do
    if File.exists?(file_name()) do
      {:ok, str} = File.read(file_name())
      hash = Jason.decode!(str)
      target = Map.get(hash, "target", %{})

      map_holding = fn %{"ticker" => ticker, "value" => value} ->
        %Holding{ticker: ticker, value: value}
      end

      map_account = fn %{"name" => name, "tax_type" => tax_type, "holdings" => holdings_hashes} ->
        %Account{
          name: name,
          tax_type: tax_type,
          holdings: holdings_hashes |> Enum.map(map_holding)
        }
      end

      accounts =
        Map.get(hash, "accounts", [])
        |> Enum.map(map_account)

      %{
        target: target,
        accounts: accounts
      }
    else
      IO.puts("No monies file detected, time to create one!")
      init()
    end
  end

  def write_state(state) do
    json = Jason.encode!(state, pretty: true)
    File.write(file_name(), json)
    state
  end

  def read_command(state) do
    IO.puts("What would you like to do?")

    [command | args] =
      get_input()
      |> String.downcase()
      |> String.split(" ")

    result = execute_command(state, command, args)

    case result do
      {:continue, new_state} -> read_command(new_state)
      {:quit} -> {:done}
    end
  end

  def choose_account(state) do
    IO.puts(
      state.accounts
      |> Enum.with_index()
      |> Enum.map(fn {account, index} -> "#{index + 1}: #{account.name}\n" end)
    )

    {account_selection, _} = Integer.parse(get_input())
    account_selection - 1
  end

  def commands do
    ["help", "rebalance", "contribute", "quit"]
  end

  def apply_changes(state, account_index, changes) do
    accounts =
      state.accounts
      |> List.update_at(account_index, fn account -> Account.apply_changes(account, changes) end)

    %{state | accounts: accounts}
  end

  def get_input do
    IO.gets("> ") |> String.trim()
  end

  def get_dollar_input do
    {amount, _} = Float.parse(get_input() |> String.replace(",", "") |> String.replace("$", ""))
    amount
  end

  def confirm(prompt) do
    IO.puts(prompt)
    str = get_input()

    case str do
      "yes" -> :yes
      "y" -> :yes
      "no" -> :no
      "n" -> :no
    end
  end

  def execute_command(_, "quit", []) do
    IO.puts("Goodbye!")
    {:quit}
  end

  def execute_command(state, "exit", []), do: execute_command(state, "quit", [])

  def execute_command(state, "help", []) do
    IO.puts("Commands: #{Enum.join(commands(), ", ")}")
    {:continue, state}
  end

  def execute_command(state, "rebalance", []) do
    changes = Account.divergence(state.accounts, state.target)
    IO.inspect(changes)

    prompt_result = confirm("Would you like to commit these changes?")

    if prompt_result == :yes do
      IO.puts("Which account would you like to rebalance with?")

      account_index = choose_account(state)
      new_state = apply_changes(state, account_index, changes)

      IO.puts("Done!")
      write_state(new_state)
      {:continue, new_state}
    else
      {:continue, state}
    end
  end

  def execute_command(state, "contribute", []) do
    IO.puts("How much?")
    changes = Account.calculate_contributions(state.accounts, state.target, get_dollar_input())
    IO.inspect(changes)

    prompt_result = confirm("Would you like to commit these changes?")

    if prompt_result == :yes do
      IO.puts("Which account would you like to contribue to?")

      account_index = choose_account(state)
      new_state = apply_changes(state, account_index, changes)

      IO.puts("Done!")
      write_state(new_state)
      {:continue, new_state}
    else
      {:continue, state}
    end
  end

  def execute_command(_, "init", []) do
    {:continue, init()}
  end

  def init do
    IO.puts("Creating a new monies file.")
    new_state = %{target: read_target(), accounts: read_accounts()}
    write_state(new_state)
    IO.puts("Initial monies file created!")
    new_state
  end

  def read_target do
    target =
      FundList.map(fn fund_details ->
        IO.puts("What is your target for #{fund_details.ticker}, #{fund_details.name}?")
        {alloc, _} = get_input() |> String.replace("%", "") |> Float.parse()
        {fund_details.ticker, alloc / 100.0}
      end)
      |> Enum.filter(fn {_, percent} -> percent > 0 end)
      |> Map.new()

    total_alloc = target |> Enum.map(fn {_, v} -> v end) |> Enum.sum()

    if total_alloc == 1.0 do
      target
    else
      IO.puts("That didn't add up to 100, try again.")
      read_target()
    end
  end

  def read_accounts do
    if confirm("Would you like to add an account to track?") == :yes do
      account = read_account()
      [account | read_accounts()]
    else
      []
    end
  end

  def read_account do
    IO.puts("What's the name of this account?")
    name = get_input()
    IO.puts("What's the tax nature of this account? (taxable/roth/traditional)")
    tax_type = get_input()
    holdings = read_holdings()
    IO.puts("Account created!")
    %Account{name: name, tax_type: tax_type, holdings: holdings}
  end

  def read_holdings do
    FundList.map(fn fund_details ->
      IO.puts(
        "What is your holding (in dollars) for #{fund_details.ticker} #{fund_details.name}?"
      )

      %Holding{ticker: fund_details.ticker, value: get_dollar_input()}
    end)
  end

  def run(state) do
    read_command(state)
  end
end
