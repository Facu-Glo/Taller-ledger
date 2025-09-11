defmodule Leadger.HandleTransactions do
  
  def handle_transactions(config) do
    filename = Map.get(config, :archivo_transacciones, "transacciones.csv")

    coins = Leadger.CurrencyLoader.load_monedas()

    case Leadger.TransactionReader.read_and_validate_transactions(filename, coins) do
      {:ok, map} ->
        filter = Leadger.TransactionReader.filter_transactions(map, config)
        Leadger.OutputWriter.output_results_transaction(filter, config)

      {:error, line_number} ->
        IO.puts("Error en la línea #{line_number} del archivo de transacciones.")
        IO.inspect({:error, line_number})
    end
  end
end
