defmodule CommandLine do
  def read do
    IO.gets("> ") |> String.trim()
  end

  defp clean_number_string(str) do
    String.replace(str, ",", "")
  end

  def read_float do
    {amount, _} = read() |> clean_number_string() |> Float.parse()
    amount
  end

  def read_integer do
    {amount, _} = read() |> clean_number_string() |> Integer.parse()
    amount
  end

  def read_dollar do
    {amount, _} = read() |> clean_number_string() |> String.replace("$", "") |> Float.parse()
    amount
  end

  def read_percentage do
    {amount, _} = read() |> clean_number_string() |> String.replace("%", "") |> Float.parse()
    amount
  end

  def write(str) do
    IO.puts(str)
  end

  def confirm(prompt) do
    CommandLine.write(prompt)
    str = CommandLine.read()

    case str do
      "yes" -> :yes
      "y" -> :yes
      "no" -> :no
      "n" -> :no
    end
  end
end
