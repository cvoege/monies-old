import Fund

funds =
  Enum.map(
    [
      %Fund{
        ticker: "VTSAX",
        etf_ticker: "VTI",
        name: "Total US Stock",
        asset_type: "stock",
        location: "domestic",
        expense_ratio: 0.04,
        tax_efficiency: "medium"
      },
      %Fund{
        ticker: "VTIAX",
        etf_ticker: "VXUS",
        name: "Total International Stock",
        asset_type: "stock",
        location: "international",
        expense_ratio: 0.11,
        tax_efficiency: "medium"
      },
      %Fund{
        ticker: "VBTLX",
        etf_ticker: "BND",
        name: "Total US Bond",
        asset_type: "bond",
        location: "domestic",
        expense_ratio: 0.05,
        tax_efficiency: "low"
      },
      %Fund{
        ticker: "VTABX",
        etf_ticker: "BNDX",
        name: "Total International Bond",
        asset_type: "bond",
        location: "international",
        expense_ratio: 0.11,
        tax_efficiency: "low"
      },
      %Fund{
        ticker: "VGSLX",
        etf_ticker: "VNQ",
        name: "US Real Estate Investment Trusts",
        asset_type: "real_estate",
        location: "domestic",
        expense_ratio: 0.12,
        tax_efficiency: "medium"
      },
      %Fund{
        ticker: "VMFXX",
        name: "Money Market",
        asset_type: "cash",
        location: "domestic",
        expense_ratio: 0.11,
        tax_efficiency: "high"
      }
    ],
    fn fund -> {fund.ticker, fund} end
  )
  |> Map.new()

defmodule FundList do
  @funds funds
  @fund_order [
    "VTSAX",
    "VTIAX",
    "VBTLX",
    "VTABX",
    "VGSLX",
    "VMFXX"
  ]
  def all, do: @funds
  def fund_order, do: @fund_order

  def map(fun) do
    fund_order()
    |> Enum.map(fn ticker ->
      fund_details = FundList.all() |> Map.get(ticker)
      fun.(fund_details)
    end)
  end
end
