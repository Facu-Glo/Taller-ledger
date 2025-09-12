defmodule Ledger.HandleBalance do
  def handle_balance(config) do
    coins = Ledger.CurrencyLoader.load_monedas()

    case Map.get(config, :cuenta_origen) do
      nil ->
        IO.puts("Debe especificar una cuenta de origen con -c1")

      origin_account ->
        filename = Map.get(config, :archivo_transacciones, "transacciones.csv")

        case Ledger.BalanceCalculator.calculate_balance(filename, origin_account, coins, config) do
          {:ok, balance} ->
            Ledger.OutputWriter.output_results_balance(balance, config)

          {:error, line_number} ->
            IO.puts("Error en la línea #{line_number} del archivo de transacciones.")
        end
    end
  end
end
