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
        {:error, :missing_origin_account}

      origin_account ->
        {:ok, Map.put(config, :validated_account, origin_account)}
    end
  end

  def load_currencies_if_valid({:error, _} = error), do: error

  def load_currencies_if_valid({:ok, config}) do
    case Ledger.CurrencyLoader.load_monedas() do
      {:ok, currencies} ->
        {:ok, Map.put(config, :currencies, currencies)}

      error ->
        error
    end
  end

  def calculate_balance_if_valid({:error, _} = error), do: error

  def calculate_balance_if_valid({:ok, config}) do
    filename = Map.get(config, :archivo_transacciones, "transacciones.csv")
    origin_account = config.validated_account
    currencies = config.currencies

    case Ledger.BalanceCalculator.calculate_balance(filename, origin_account, currencies, config) do
      {:ok, balance} ->
        {:ok, balance, config}

      error ->
        error
    end
  end

  def output_balance_result({:ok, balance, config}) do
    Ledger.OutputWriter.output_results_balance(balance, config)
    :ok
  end

  def output_balance_result(error = {:error, _}) do
    Ledger.HandleError.handle(error)
    :error
  end
end
