defmodule Ledger.TransactionReader do
  def read_and_validate_transactions(filename, map_coins) do
    if not File.exists?(filename) do
      {:error, "File not found"}
    else
      list_headers = [
        :id_transaccion,
        :timestamp,
        :moneda_origen,
        :moneda_destino,
        :monto,
        :cuenta_origen,
        :cuenta_destino,
        :tipo
      ]

      with {:ok, parsed_transactions} <-
             parse_and_validate_csv(filename, list_headers, map_coins),
           :ok <- Ledger.Validators.validate_transactions_accounts(parsed_transactions),
           {:ok, balances} <- Ledger.Validators.validate_balances(parsed_transactions, map_coins) do
        {:ok, parsed_transactions, balances}
      else
        error -> error
      end
    end
  end

  def parse_and_validate_csv(filename, list_headers, map_coins) do
    transaction_result =
      File.stream!(filename)
      |> CSV.decode!(headers: list_headers, separator: ?;)
      |> Stream.with_index(1)
      |> Enum.reduce_while([], fn {row, line_number}, acc ->
        case Ledger.Validators.validate_transaction_row(row, line_number, map_coins) do
          {:ok, map} -> {:cont, [map | acc]}
          error -> {:halt, error}
        end
      end)

    case transaction_result do
      {:error, _} = error -> error
      valid_transactions -> {:ok, Enum.reverse(valid_transactions)}
    end
  end

  def filter_origin_account(list_transaction, nil), do: list_transaction

  def filter_origin_account(list_transaction, cuenta_origen) do
    Enum.filter(list_transaction, fn {transaction, _line_number} ->
      transaction.cuenta_origen == cuenta_origen
    end)
  end

  def filter_destination_account(list_transaction, nil), do: list_transaction

  def filter_destination_account(list_transaction, cuenta_destino) do
    Enum.filter(list_transaction, fn {transaction, _line_number} ->
      transaction.cuenta_destino == cuenta_destino
    end)
  end

  def filter_transactions(list_transaction, opts) do
    list_transaction
    |> filter_origin_account(Map.get(opts, :cuenta_origen))
    |> filter_destination_account(Map.get(opts, :cuenta_destino))
  end
end
