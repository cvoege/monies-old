defmodule FundList do
  use Agent

  def fund_file_name() do
    "funds.json"
  end

  def fetch do
    start_fn = fn ->
      {:ok, str} = File.read(fund_file_name())
      hash = Jason.decode!(str)

      fund_list =
        hash
        |> Map.get("funds", [])
        |> Enum.map(fn fund_hash -> Fund.deserialize(fund_hash) end)

      fund_map = fund_list |> Enum.map(fn fund -> {fund.ticker, fund} end) |> Map.new()

      %{fund_list: fund_list, fund_map: fund_map}
    end

    Agent.start_link(start_fn, name: __MODULE__)
  end

  def list do
    Agent.get(__MODULE__, fn %{fund_list: fund_list} -> fund_list end)
  end

  def map do
    Agent.get(__MODULE__, fn %{fund_map: fund_map} -> fund_map end)
  end
end
