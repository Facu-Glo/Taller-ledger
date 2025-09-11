defmodule Leadger.OutputWriter do
  def write_to_file_transaction(data, filename) do
    content =
      Enum.map(data, fn transaction ->
        [
          transaction.id,
          transaction.timestamp,
          transaction.moneda_origen,
          transaction.moneda_destino,
          transaction.monto,
          transaction.cuenta_origen,
          transaction.cuenta_destino,
          transaction.tipo
        ]
      end)

    File.open!(filename, [:write], fn file ->
      content
      |> CSV.encode(separator: ?;)
      |> Enum.each(fn line -> IO.write(file, line) end)
    end)
  end

  def console_output_transaction(data) do
    Enum.map(data, fn transaction ->
      IO.puts(
        "#{transaction.id};#{transaction.timestamp};#{transaction.moneda_origen};#{transaction.moneda_destino};#{transaction.monto};#{transaction.cuenta_origen};#{transaction.cuenta_destino};#{transaction.tipo}"
      )
    end)
  end

  def output_results_transaction(lis_transaction, opts) do
    case Map.get(opts, :archivo_salida) do
      nil -> console_output_transaction(lis_transaction)
      filename -> write_to_file_transaction(lis_transaction, filename)
    end
  end

  def write_to_file_balance(data, filename) do
    IO.inspect(data)

    content =
      Enum.map(data, fn {currency, amount} ->
        "#{currency};#{Decimal.round(amount, 6)}\n"
      end)

    File.write!(filename, content)
  end

  def console_output_balance(data) do
    Enum.each(data, fn {currency, amount} ->
      IO.puts("#{currency}=#{Decimal.round(amount, 6)}")
    end)
  end

  def output_results_balance(balance, opts) do
    case Map.get(opts, :archivo_salida) do
      nil -> console_output_balance(balance)
      filename -> write_to_file_balance(balance, filename)
    end
  end
end
