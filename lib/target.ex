defmodule Target do
  def read_target do
    target =
      FundList.map(fn fund_details ->
        CommandLine.write("What is your target for #{fund_details.ticker}, #{fund_details.name}?")
        alloc = CommandLine.read_percentage()
        {fund_details.ticker, alloc / 100.0}
      end)
      |> Enum.filter(fn {_, percent} -> percent > 0 end)
      |> Map.new()

    total_alloc = target |> Enum.map(fn {_, v} -> v end) |> Enum.sum()

    if total_alloc == 1.0 do
      target
    else
      CommandLine.write("That didn't add up to 100, try again.")
      read_target()
    end
  end
end
