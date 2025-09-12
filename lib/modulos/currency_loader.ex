defmodule Ledger.CurrencyLoader do
  def load_monedas(path \\ "monedas.csv") do
    headers = [:moneda, :valor]

    File.stream!(path)
    |> CSV.decode!(headers: headers, separator: ?;)
    |> Enum.reduce(%{}, fn row, acc ->
      case Ledger.Validators.parse_decimal(row[:valor]) do
        {:ok, value} -> Map.put(acc, row[:moneda], value)
        _ -> acc
      end
    end)
  end
end
