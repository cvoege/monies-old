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
end
