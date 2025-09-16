defmodule Ledger.HandleTransactions do
  def handle_transactions(config) do
    filename = Map.get(config, :archivo_transacciones, "transacciones.csv")

    filename
    |> load_coins_and_transactions()
    |> filter_transactions(config)
    |> output_transactions(config)
  end

  def load_coins_and_transactions(filename) do
    with {:ok, coins} <- Ledger.CurrencyLoader.load_monedas(),
         {:ok, transactions, _balances} <- Ledger.TransactionReader.read_and_validate_transactions(filename, coins) do
      {:ok, %{coins: coins, transactions: transactions}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def filter_transactions({:ok, %{transactions: transactions}}, config) do
    filtered = Ledger.TransactionReader.filter_transactions(transactions, config)
    {:ok, filtered}
  end

  def filter_transactions(error = {:error, _}, _config), do: error

  def output_transactions({:ok, filtered}, config) do
    Ledger.OutputWriter.output_results_transaction(filtered, config)
  end

  def output_transactions({:error, reason}, _config) when is_binary(reason) do
    IO.puts("Error: #{reason}")
  end

  def output_transactions({:error, line_number}, _config) when is_integer(line_number) do
    IO.puts("Error en la línea #{line_number} del archivo de transacciones.")
    IO.inspect({:error, line_number})
  end
end
