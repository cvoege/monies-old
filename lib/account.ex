defmodule Account do
  fields = [:name, :holdings, :tax_type]
  @enforce_keys fields
  @derive {Jason.Encoder, only: fields}
  defstruct fields

  def total(account) do
    account.holdings |> Enum.map(fn holding -> holding.value end) |> Enum.sum()
  end

  def allocations(account) do
    account.holdings
    |> Enum.map(fn holding -> {holding.ticker, holding.value} end)
    |> Map.new()
  end

  def apply_changes(account, changes) do
    all_tickers =
      Enum.concat(
        Map.keys(changes),
        account.holdings |> Enum.map(fn holding -> holding.ticker end)
      )
      |> Enum.uniq()

    current_holding_map =
      account.holdings |> Enum.map(fn holding -> {holding.ticker, holding.value} end) |> Map.new()

    map_holding = fn ticker ->
      %Holding{
        ticker: ticker,
        value: Map.get(current_holding_map, ticker, 0) + Map.get(changes, ticker, 0)
      }
    end

    holdings = all_tickers |> Enum.map(map_holding)

    %Account{account | holdings: holdings}
  end

  # def percentages(account) do
  #   total_value = total(account)
  #   allocations(account) |> Enum.map(fn {k, v} -> {k, v / total_value} end) |> Map.new()
  # end

  def total_allocations([]) do
    %{}
  end

  def total_allocations([account | rest]) do
    allocations(account)
    |> Map.merge(total_allocations(rest), fn _k, v1, v2 -> v1 + v2 end)
  end

  def total_percentages(accounts) do
    all_values = total_allocations(accounts)
    all_total = all_values |> Map.values() |> Enum.sum()

    all_values |> Enum.map(fn {k, v} -> {k, v / all_total} end) |> Map.new()
  end

  def divergence_helper(current_allocations, target_allocations) do
    all_tickers =
      Enum.concat(Map.keys(current_allocations), Map.keys(target_allocations)) |> Enum.uniq()

    mapper = fn ticker, acc ->
      Map.put(
        acc,
        ticker,
        Map.get(target_allocations, ticker, 0) - Map.get(current_allocations, ticker, 0)
      )
    end

    all_tickers
    |> Enum.reduce(%{}, mapper)
  end

  def percentage_divergence(accounts, target) do
    current_percentages = total_percentages(accounts)
    divergence_helper(current_percentages, target)
  end

  def divergence(accounts, target) do
    current_allocations = total_allocations(accounts)
    current_total = current_allocations |> Map.values() |> Enum.sum()
    target_allocations = target |> Enum.map(fn {k, v} -> {k, v * current_total} end) |> Map.new()
    divergence_helper(current_allocations, target_allocations)
  end

  def calculate_contributions(accounts, target, contribution) do
    current_allocations = total_allocations(accounts)
    current_total = current_allocations |> Map.values() |> Enum.sum()
    new_total = current_total + contribution
    target_allocations = target |> Enum.map(fn {k, v} -> {k, v * new_total} end) |> Map.new()

    ideal_allocations = divergence_helper(current_allocations, target_allocations)
    positive_allocations = ideal_allocations |> Enum.filter(fn {_, v} -> v > 0 end)
    total_positive = positive_allocations |> Enum.map(fn {_, v} -> v end) |> Enum.sum()

    positive_allocations
    |> Enum.map(fn {k, v} -> {k, contribution * (v / total_positive)} end)
    |> Map.new()
  end

  def read_accounts do
    if CommandLine.confirm("Would you like to add an account to track?") == :yes do
      account = read_account()
      [account | read_accounts()]
    else
      []
    end
  end

  def read_account do
    CommandLine.write("What's the name of this account?")
    name = CommandLine.read()
    CommandLine.write("What's the tax nature of this account? (taxable/roth/traditional)")
    tax_type = CommandLine.read()
    holdings = Holding.read_holdings()
    CommandLine.write("Account created!")
    %Account{name: name, tax_type: tax_type, holdings: holdings}
  end
end
