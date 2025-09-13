defmodule Ledger.HandleTransactions do
  def handle_transactions(config) do
    filename = Map.get(config, :archivo_transacciones, "transacciones.csv")

    coins = Ledger.CurrencyLoader.load_monedas()

    case Ledger.TransactionReader.read_and_validate_transactions(filename, coins) do
      {:ok, map} ->
        filter = Ledger.TransactionReader.filter_transactions(map, config)
        Ledger.OutputWriter.output_results_transaction(filter, config)

      {:error, line_number} when is_integer(line_number) ->
        IO.puts("Error en la línea #{line_number} del archivo de transacciones.")
        IO.inspect({:error, line_number})

      {:error, messege} when is_binary(messege)->
        IO.puts("Error: #{messege}")
    end
  end
end
