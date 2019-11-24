defmodule Holding do
  fields = [:ticker, :value]
  @enforce_keys fields
  @derive {Jason.Encoder, only: fields}
  defstruct fields

  def read_holdings do
    FundList.map(fn fund_details ->
      CommandLine.write(
        "What is your holding (in dollars) for #{fund_details.ticker} #{fund_details.name}?"
      )

      %Holding{ticker: fund_details.ticker, value: CommandLine.read_dollar()}
    end)
  end
end
