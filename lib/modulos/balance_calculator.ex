defmodule Leadger.BalanceCalculator do
  def calculate_balance(filename, origin_account, coins, opts) do
    case Leadger.TransactionReader.read_and_validate_transactions(filename, coins) do
      {:ok, list_transaction} ->
        account = Leadger.TransactionReader.filter_transactions(list_transaction, %{cuenta_origen: origin_account})
        balances = compute_balance(account, origin_account, coins)

        case Map.get(opts, :moneda) do
          nil ->
            {:ok, balances}

          target_currency ->
            convert_to_currency(balances, target_currency, coins)
        end

      {:error, line_number} ->
        {:error, line_number}
    end
  end

  def compute_balance(accounts, origin_account, coins) do
    Enum.reduce(accounts, %{}, fn transaction, acc ->
      apply_transaction(acc, transaction, origin_account, coins)
    end)
  end

  def update_balance(acc, currency, amount) do
    Map.update(acc, currency, amount, fn current_value -> current_value + amount end)
  end

  def apply_transaction(
        acc,
        %{
          tipo: "alta_cuenta",
          moneda_origen: moneda,
          monto: monto
        },
        _origin_account,
        _coins
      ) do
    currency = if moneda != "", do: moneda, else: "USD"
    update_balance(acc, currency, monto)
  end

  def apply_transaction(acc, %{tipo: "transferencia"} = map, origin_account, _coins) do
    cond do
      map.cuenta_origen == origin_account -> update_balance(acc, map.moneda_origen, -map.monto)
      map.cuenta_destino == origin_account -> update_balance(acc, map.moneda_origen, map.monto)
      true -> acc
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
    converted_amount =
      get_converted_amount(
        %{moneda_origen: moneda_origen, moneda_destino: moneda_destino, monto: monto},
        coins
      )

    acc
    |> update_balance(moneda_origen, -monto)
    |> update_balance(moneda_destino, converted_amount)
  end

  def get_converted_amount(map, coins) do
    origin_coin = Map.get(coins, map.moneda_origen)
    destiny_coin = Map.get(coins, map.moneda_destino)

    if destiny_coin > 0 do
      map.monto * origin_coin / destiny_coin
    else
      0.0
    end
  end

  def convert_to_currency(balances, target_currency, coins) do
    if Map.has_key?(coins, target_currency) do
      target_value = Map.get(coins, target_currency)

      total =
        Enum.reduce(balances, 0.0, fn {currency, amount}, acc ->
          currency_value = Map.get(coins, currency)

          if target_value > 0 do
            acc + amount * currency_value / target_value
          else
            acc
          end
        end)

      {:ok, %{target_currency => total}}
    else
      {:error, :invalid_target_currency}
    end
  end
end
