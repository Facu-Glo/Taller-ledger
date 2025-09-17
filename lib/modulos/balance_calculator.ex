defmodule Ledger.BalanceCalculator do
  def calculate_balance(filename, origin_account, coins, opts) do
    with {:ok, _transactions, balances} <-
           Ledger.TransactionReader.read_and_validate_transactions(filename, coins),
         account_balance <- Map.get(balances, origin_account, %{}) do
      convert_balance_if_needed(account_balance, opts, coins)
    end
  end

  defp convert_balance_if_needed(balances, opts, coins) do
    case Map.get(opts, :moneda) do
      nil -> {:ok, balances}
      target -> convert_to_currency(balances, target, coins)
    end
  end

  def update_balance(acc, currency, amount) do
    Map.update(acc, currency, amount, fn currency_value ->
      Decimal.add(currency_value, amount)
    end)
  end

  def apply_transaction(
        acc,
        %{tipo: "alta_cuenta", moneda_origen: moneda, monto: monto},
        _origin_account,
        _coins
      ) do
    currency = (moneda != "" && moneda) || "USD"
    update_balance(acc, currency, monto)
  end

  def apply_transaction(acc, %{tipo: "transferencia"} = map, origin_account, _coins) do
    cond do
      map.cuenta_origen == origin_account ->
        update_balance(acc, map.moneda_origen, Decimal.negate(map.monto))

      map.cuenta_destino == origin_account ->
        update_balance(acc, map.moneda_origen, map.monto)

      true ->
        acc
    end
  end

  def apply_transaction(
        acc,
        %{
          tipo: "swap",
          moneda_origen: moneda_origen,
          moneda_destino: moneda_destino,
          monto: monto
        },
        _origin_account,
        coins
      ) do
    converted =
      get_converted_amount(
        %{moneda_origen: moneda_origen, moneda_destino: moneda_destino, monto: monto},
        coins
      )

    acc
    |> update_balance(moneda_origen, Decimal.negate(monto))
    |> update_balance(moneda_destino, converted)
  end

  def get_converted_amount(
        %{moneda_origen: moneda_origen, moneda_destino: moneda_destino, monto: monto},
        coins
      ) do
    origin_value = Map.get(coins, moneda_origen)
    dest_value = Map.get(coins, moneda_destino)
    zero = Decimal.new(0)

    if Decimal.compare(dest_value, zero) == :gt do
      monto |> Decimal.mult(origin_value) |> Decimal.div(dest_value)
    else
      zero
    end
  end

  def convert_to_currency(balances, target_currency, coins) do
    with {:ok, target_value} <- Map.fetch(coins, target_currency) do
      zero = Decimal.new(0)
      total = calculate_total(balances, coins, target_value, zero)
      {:ok, %{target_currency => total}}
    else
      :error -> {:error, "Moneda inválida"}
    end
  end

  defp calculate_total(balances, coins, target_value, zero) do
    Enum.reduce(balances, zero, fn {currency, amount}, acc ->
      currency_value = Map.get(coins, currency)

      if Decimal.compare(target_value, zero) == :gt do
        converted =
          amount
          |> Decimal.mult(currency_value)
          |> Decimal.div(target_value)

        Decimal.add(acc, converted)
      else
        acc
      end
    end)
  end
end
