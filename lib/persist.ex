defmodule Persist do
  @save_file_name "monies.json"
  def save_file_name, do: @save_file_name

  def exists? do
    File.exists?(save_file_name())
  end

  def read_state do
    {:ok, str} = File.read(save_file_name())
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
  end

  def write_state(state, file_name) do
    json = Jason.encode!(state, pretty: true)
    File.write(file_name, json)
    state
  end

  def write_state(state) do
    write_state(state, save_file_name())
  end

  def backup(state) do
    {:ok, time} = DateTime.now("Etc/UTC")
    File.mkdir_p!("backups/")
    name = "monies-#{time}.json"
    path = "backups/#{name}"
    write_state(state, path)
    name
  end
end
