defmodule Ledger.Validators do
  def parse_integer(nil), do: {:error, nil}
  def parse_integer(""), do: {:error, nil}

  def parse_integer(str) do
    case Integer.parse(str) do
      {int, ""} when int >= 0 -> {:ok, int}
      _ -> {:error, nil}
    end
  end

  def parse_decimal(nil), do: {:error, nil}
  def parse_decimal(""), do: {:error, nil}

  def parse_decimal(string) do
    case Decimal.parse(string) do
      {decimal, ""} ->
        zero = Decimal.new(0)

        if Decimal.compare(decimal, zero) != :lt do
          {:ok, decimal}
        else
          {:error, nil}
        end

      _ ->
        {:error, nil}
    end
  end

  def validate_transaction_type(transaction_type)
      when transaction_type in ["swap", "transferencia", "alta_cuenta"],
      do: :ok

  def validate_transaction_type(_), do: {:error, :invalid_type}

  def validate_transaction_currencies(
        %{tipo: "swap", moneda_origen: origen, moneda_destino: destino},
        map_coins
      )
      when origen != destino do
    if Map.has_key?(map_coins, origen) and Map.has_key?(map_coins, destino) do
      :ok
    else
      {:error, :invalid_coin}
    end
  end

  def validate_transaction_currencies(
        %{tipo: "transferencia", moneda_origen: moneda, moneda_destino: moneda},
        map_coins
      ) do
    if Map.has_key?(map_coins, moneda), do: :ok, else: {:error, :invalid_coin}
  end

  def validate_transaction_currencies(
        %{tipo: "alta_cuenta", moneda_origen: origen, moneda_destino: ""},
        map_coins
      ) do
    if Map.has_key?(map_coins, origen), do: :ok, else: {:error, :invalid_coin}
  end

  def validate_transaction_currencies(_, _), do: {:error, :invalid_type}

  def validate_transaction_row(row, line_number, map_coins) do
    with {:ok, id} <- parse_integer(row[:id_transaccion]),
         {:ok, money} <- parse_decimal(row[:monto]),
         :ok <- validate_transaction_type(row[:tipo]),
         :ok <- validate_transaction_currencies(row, map_coins) do
      {:ok,
       %{
         id: id,
         timestamp: row[:timestamp],
         moneda_origen: row[:moneda_origen],
         moneda_destino: row[:moneda_destino],
         monto: money,
         cuenta_origen: row[:cuenta_origen],
         cuenta_destino: row[:cuenta_destino],
         tipo: row[:tipo]
       }}
    else
      _ -> {:error, line_number}
    end
  end

  def validate_transactions_accounts(transactions) do
    sorted_transactions = Enum.sort_by(transactions, fn transaction -> transaction.timestamp end)
    set = MapSet.new()
    validate_account_creation(sorted_transactions, set)
  end

  def validate_account_creation([], _account_set), do: :ok

  def validate_account_creation([transaction | rest], account_set) do
    case transaction.tipo do
      "alta_cuenta" ->
        new_account_set = MapSet.put(account_set, transaction.cuenta_origen)
        validate_account_creation(rest, new_account_set)

      "transferencia" ->
        if MapSet.member?(account_set, transaction.cuenta_origen) and
             MapSet.member?(account_set, transaction.cuenta_destino) do
          validate_account_creation(rest, account_set)
        else
          {:error, "account not created before transfer"}
        end

      "swap" ->
        if MapSet.member?(account_set, transaction.cuenta_origen) do
          validate_account_creation(rest, account_set)
        else
          {:error, "account not created before swap"}
        end

      _ ->
        validate_account_creation(rest, account_set)
    end
  end

  def validate_positive_balances(balances) do
    Enum.reduce_while(balances, :ok, fn {account, account_balances}, _acc ->
      case Enum.find(account_balances, fn {_currency, amount} ->
             Decimal.compare(amount, 0) == :lt
           end) do
        nil -> {:cont, :ok}
        {currency, _} -> {:halt, {:error, {account, currency}}}
      end
    end)
  end

  def validate_balances(transactions, map_coins) do
    balances =
      Enum.reduce(transactions, %{}, fn tx, acc ->
        account = tx.cuenta_origen || tx.cuenta_destino
        current_balance = Map.get(acc, account, %{})

        updated_balance =
          Ledger.BalanceCalculator.apply_transaction(current_balance, tx, account, map_coins)

        Map.put(acc, account, updated_balance)
      end)

    case validate_positive_balances(balances) do
      :ok ->
        {:ok, balances}

      {:error, {account, _}} ->
        {:error, "Se detectó un balance negativo en la cuenta de #{account}"}
    end
  end
end
