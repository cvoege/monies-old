defmodule Monies do
  def main(_args) do
    CommandLine.write("Welcome!")
    FundList.fetch()
    run(load_initial_state())
  end

  def run(state) do
    command = read_command(state)

    result = execute_command(state, command)

    case result do
      {:continue, new_state} -> run(new_state)
      {:quit} -> {:done}
    end
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
    CommandLine.write("\nWhat would you like to do?")
    index = CommandLine.choose_one(commands())
    command = Enum.at(commands(), index)

    case command do
      nil -> read_command(state)
      _ -> command
    end
  end

  def choose_account(state) do
    state.accounts |> Enum.map(fn account -> account.name end) |> CommandLine.choose_one()
  end

  def commands do
    [
      "set balances",
      "contribute",
      "set target",
      "rebalance",
      "target stats",
      "current stats",
      "help",
      "init",
      "quit"
    ]
  end

  def apply_changes(state, account_index, changes) do
    accounts =
      state.accounts
      |> List.update_at(account_index, fn account -> Account.apply_changes(account, changes) end)

    %{state | accounts: accounts}
  end

  def execute_command(_, "quit") do
    CommandLine.write("Goodbye!")
    {:quit}
  end

  def execute_command(state, "exit"), do: execute_command(state, "quit")

  def execute_command(state, "help") do
    CommandLine.write("Commands: #{Enum.join(commands(), ", ")}")
    {:continue, state}
  end

  def execute_command(state, "rebalance") do
    changes = Account.divergence(state.accounts, state.target)
    CommandLine.write(Account.pretty_divergence(changes))

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

  def execute_command(state, "contribute") do
    CommandLine.write("How much?")

    changes =
      Account.calculate_contributions(state.accounts, state.target, CommandLine.read_dollar())

    CommandLine.write(Account.pretty_divergence(changes))

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

  def execute_command(_, "init") do
    {:continue, init()}
  end

  def execute_command(state, "backup") do
    name = Persist.backup(state)
    CommandLine.write("Backup created! (#{name})")
    {:continue, state}
  end

  def execute_command(state, "target stats") do
    state.target |> stats()
    {:continue, state}
  end

  def execute_command(state, "current stats") do
    state.accounts |> Account.total_allocations() |> stats()
    {:continue, state}
  end

  def execute_command(state, "set target") do
    new_target = Target.read_target()

    prompt_result = CommandLine.confirm("Would you like to commit these changes?")

    if prompt_result == :yes do
      new_state = Persist.write_state(%{state | target: new_target})

      CommandLine.write("Done!")
      {:continue, new_state}
    else
      {:continue, state}
    end
  end

  def execute_command(_, "set balances") do
    # TODO
  end

  def init do
    CommandLine.write("Creating a new monies file.")
    new_state = %{target: Target.read_target(), accounts: Account.read_accounts()}
    Persist.write_state(new_state)
    CommandLine.write("Initial monies file created!")
    new_state
  end

  def stats(full_allocations) do
    # fund_list = FundList.list()
    fund_map = FundList.map()

    filter_stocks = fn {ticker, _} -> Map.get(fund_map, ticker).asset_type == "stock" end
    filter_bonds = fn {ticker, _} -> Map.get(fund_map, ticker).asset_type == "bond" end
    filter_cash = fn {ticker, _} -> Map.get(fund_map, ticker).asset_type == "cash" end

    filter_real_estate = fn {ticker, _} ->
      Map.get(fund_map, ticker).asset_type == "real_estate"
    end

    filter_domestic = fn {ticker, _} -> Map.get(fund_map, ticker).location == "domestic" end

    filter_international = fn {ticker, _} ->
      Map.get(fund_map, ticker).location == "international"
    end

    sum_allocations = fn allocations ->
      Enum.map(allocations, fn {_, value} -> value end) |> Enum.sum()
    end

    format_percentage = fn value -> "#{Float.round(value, 2)}%" end

    total_value = sum_allocations.(full_allocations)
    total_stock_value = sum_allocations.(full_allocations |> Enum.filter(filter_stocks))
    total_bond_value = sum_allocations.(full_allocations |> Enum.filter(filter_bonds))

    percentage_results = [
      {"Stocks", sum_allocations.(full_allocations |> Enum.filter(filter_stocks)) / total_value},
      {"Bonds", sum_allocations.(full_allocations |> Enum.filter(filter_bonds)) / total_value},
      {"Cash", sum_allocations.(full_allocations |> Enum.filter(filter_cash)) / total_value},
      {"Real Estate",
       sum_allocations.(full_allocations |> Enum.filter(filter_real_estate)) / total_value},
      {"Domsetic",
       sum_allocations.(full_allocations |> Enum.filter(filter_domestic)) / total_value},
      {"International",
       sum_allocations.(full_allocations |> Enum.filter(filter_international)) / total_value},
      {"Percentage Domestic Of Stocks",
       sum_allocations.(
         full_allocations
         |> Enum.filter(filter_domestic)
         |> Enum.filter(filter_stocks)
       ) / total_stock_value},
      {"Percentage International Of Stocks",
       sum_allocations.(
         full_allocations
         |> Enum.filter(filter_international)
         |> Enum.filter(filter_stocks)
       ) / total_stock_value},
      {"Precentage Domestic Of Bonds",
       sum_allocations.(
         full_allocations
         |> Enum.filter(filter_domestic)
         |> Enum.filter(filter_bonds)
       ) / total_bond_value},
      {"Percentage International Of Bonds",
       sum_allocations.(
         full_allocations
         |> Enum.filter(filter_international)
         |> Enum.filter(filter_bonds)
       ) / total_bond_value}
    ]

    percentage_results
    |> Enum.map(fn {label, value} -> "#{label}: #{format_percentage.(100 * value)}" end)
    |> Enum.join("\n")
    |> CommandLine.write()
  end
end
