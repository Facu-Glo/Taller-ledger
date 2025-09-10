defmodule Leadger.Parser do
  def parser_args([]) do
    {:error, "Debe especificar un subcomando: transacciones o balance"}
  end

  def parser_args(["transacciones" | flags]) do
    config = parser_flags(flags)
    {:transacciones, config}
  end

  def parser_args(["balance" | flags]) do
    config = parser_flags(flags)
    {:balance, config}
  end

  def parser_flags(flags) do
    Enum.reduce(flags, %{}, fn flag, acc ->
      case String.split(flag, "=", parts: 2) do
        ["-c1", value] -> Map.put(acc, :cuenta_origen, value)
        ["-c2", value] -> Map.put(acc, :cuenta_destino, value)
        ["-t", value] -> Map.put(acc, :archivo_transacciones, value)
        ["-m", value] -> Map.put(acc, :moneda, value)
        ["-o", value] -> Map.put(acc, :archivo_salida, value)
        _ -> acc
      end
    end)
  end

  def handle_transactions(config) do
    filename = Map.get(config, :archivo_transacciones, "transacciones.csv")

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

    case read_and_validate_transactions(filename, list_headers) do
      {:ok, map} ->
        IO.inspect(map)
        IO.puts("Transacciones procesadas exitosamente")

      {:error, line_number} ->
        IO.puts("Error en la línea #{line_number} del archivo de transacciones.")
        IO.inspect({:error, line_number})
    end
  end

  def read_and_validate_transactions(filename, list_headers) do
    transaction =
      File.stream!(filename)
      |> CSV.decode!(headers: list_headers, separator: ?;)
      |> Stream.with_index(1)
      |> Enum.reduce_while([], fn {row, line_number}, acc ->
        case validate_transaction_row(row, line_number) do
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

  # ---------------------- ---------- ----------------------
  # ---------------------- Validation ----------------------
  # ---------------------- ---------- ----------------------

  def validate_transaction_row(row, line_number) do
    with {:ok, id} <- parse_integer(row[:id_transaccion]),
         {:ok, money} <- parse_float(row[:monto]),
         :ok <- validate_transaction_type(row[:tipo]),
         :ok <- validate_coins([row[:moneda_origen], row[:moneda_destino]]) do
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

  def parse_integer(nil), do: {:error, nil}
  def parse_integer(""), do: {:error, nil}

  def parse_integer(str) do
    case Integer.parse(str) do
      {int, ""} when int >= 0 -> {:ok, int}
      _ -> {:error, nil}
    end
  end

  def parse_float(string) do
    case Float.parse(string) do
      {number, ""} when number >= 0.0 -> {:ok, number}
      _ -> {:error, nil}
    end
  end

  def validate_transaction_type(transaction_type)
      when transaction_type in ["swap", "transferencia", "alta_cuenta"],
      do: :ok

  def validate_transaction_type(_), do: {:error, :invalid_type}

  def validate_coins(coins) do

    :ok
  end
end
