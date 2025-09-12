defmodule Ledger.TransactionReader do
  def read_and_validate_transactions(filename, map_coins) do
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

    transaction =
      File.stream!(filename)
      |> CSV.decode!(headers: list_headers, separator: ?;)
      |> Stream.with_index(1)
      |> Enum.reduce_while([], fn {row, line_number}, acc ->
        case Ledger.Validators.validate_transaction_row(row, line_number, map_coins) do
          {:ok, map} ->
            {:cont, [map | acc]}

          {:error, _} ->
            {:halt, {:error, line_number}}
        end
      end)

    case transaction do
      {:error, line_number} -> {:error, line_number}
      valid -> {:ok, Enum.reverse(valid)}
    end
  end

  def filter_origin_account(list_transaction, nil), do: list_transaction

  def filter_origin_account(list_transaction, cuenta_origen) do
    Enum.filter(list_transaction, fn transaction ->
      transaction.cuenta_origen == cuenta_origen
    end)
  end

  def filter_destination_account(list_transaction, nil), do: list_transaction

  def filter_destination_account(list_transaction, cuenta_destino) do
    Enum.filter(list_transaction, fn transaction ->
      transaction.cuenta_destino == cuenta_destino
    end)
  end

  def filter_transactions(list_transaction, opts) do
    list_transaction
    |> filter_origin_account(Map.get(opts, :cuenta_origen))
    |> filter_destination_account(Map.get(opts, :cuenta_destino))
  end
end
