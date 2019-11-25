defmodule Fund do
  @enforce_keys [:ticker, :name, :asset_type, :location, :expense_ratio, :tax_efficiency]
  defstruct [
    :ticker,
    :name,
    :asset_type,
    :location,
    :expense_ratio,
    :tax_efficiency,
    etf_ticker: ''
  ]

  def deserialize(fund_hash) do
    %Fund{
      ticker: Map.get(fund_hash, "ticker"),
      name: Map.get(fund_hash, "name"),
      asset_type: Map.get(fund_hash, "asset_type"),
      location: Map.get(fund_hash, "location"),
      expense_ratio: Map.get(fund_hash, "expense_ratio"),
      tax_efficiency: Map.get(fund_hash, "tax_efficiency"),
      etf_ticker: Map.get(fund_hash, "etf_ticker")
    }
  end
end
