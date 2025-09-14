defmodule Ledger.CurrencyLoader do
  def load_monedas(path \\ "monedas.csv") do
    with {:ok, :file_exists} <- validate_file_exists(path),
         {:ok, rows} <- parse_csv_file(path),
         {:ok, currencies} <- process_currency_rows(rows) do
      {:ok, currencies}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def validate_file_exists(path) do
    if File.exists?(path) do
      {:ok, :file_exists}
    else
      {:error, "File not found: #{path}"}
    end
  end

  def parse_csv_file(path) do
    headers = [:moneda, :valor]

    rows =
      File.stream!(path)
      |> CSV.decode!(headers: headers, separator: ?;)
      |> Enum.to_list()

    {:ok, rows}
  end

  def process_currency_rows(rows) do
    Enum.reduce_while(rows, {:ok, %{}}, fn row, {:ok, acc} ->
      case Ledger.Validators.parse_decimal(row[:valor]) do
        {:ok, value} ->
          {:cont, {:ok, Map.put(acc, row[:moneda], value)}}

        _ ->
          {:halt, {:error, "Invalid currency value for #{row[:moneda]}"}}
      end
    end)
  end
end
