defmodule Ledger.HandleBalance do
  def handle_balance(config) do
    config
    |> validate_balance_config()
    |> load_currencies_if_valid()
    |> calculate_balance_if_valid()
    |> output_balance_result()
  end

  def validate_balance_config(config) do
    case Map.get(config, :cuenta_origen) do
      nil ->
        {:error, "Debe especificar una cuenta de origen con -c1", config}

      origin_account ->
        {:ok, Map.put(config, :validated_account, origin_account)}
    end
  end

  def load_currencies_if_valid({:error, message, config}) do
    {:error, message, config}
  end

  def load_currencies_if_valid({:ok, config}) do
    case Ledger.CurrencyLoader.load_monedas() do
      {:ok, currencies} ->
        {:ok, Map.put(config, :currencies, currencies)}

      {:error, reason} ->
        {:error, reason, config}
    end
  end

  def calculate_balance_if_valid({:error, message, config}) do
    {:error, message, config}
  end

  def calculate_balance_if_valid({:ok, config}) do
    filename = Map.get(config, :archivo_transacciones, "transacciones.csv")
    origin_account = config.validated_account
    currencies = config.currencies

    case Ledger.BalanceCalculator.calculate_balance(filename, origin_account, currencies, config) do
      {:ok, balance} ->
        {:ok, balance, config}

      {:error, line_number} when is_integer(line_number) ->
        {:error, "Error en la línea #{line_number} del archivo de transacciones", config}

      {:error, message} when is_binary(message) ->
        {:error, message, config}
    end
  end

  def output_balance_result({:ok, balance, config}) do
    Ledger.OutputWriter.output_results_balance(balance, config)
    :ok
  end

  def output_balance_result({:error, message, _config}) do
    IO.puts("Error: #{message}")
    :error
  end
end
