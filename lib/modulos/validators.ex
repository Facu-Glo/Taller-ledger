defmodule Leadger.Validators do
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

  def validate_coins(%{tipo: "swap", moneda_origen: origen, moneda_destino: destino}, map_coins)
      when origen != destino do
    if Map.has_key?(map_coins, origen) and Map.has_key?(map_coins, destino) do
      :ok
    else
      {:error, :invalid_coin}
    end
  end

  def validate_coins(
        %{tipo: "transferencia", moneda_origen: moneda, moneda_destino: moneda},
        map_coins
      ) do
    if Map.has_key?(map_coins, moneda), do: :ok, else: {:error, :invalid_coin}
  end

  def validate_coins(%{tipo: "alta_cuenta", moneda_origen: origen, moneda_destino: ""}, map_coins) do
    if Map.has_key?(map_coins, origen), do: :ok, else: {:error, :invalid_coin}
  end

  def validate_coins(_, _), do: {:error, :invalid_type}

  def validate_transaction_row(row, line_number, map_coins) do
    with {:ok, id} <- parse_integer(row[:id_transaccion]),
         {:ok, money} <- parse_float(row[:monto]),
         :ok <- validate_transaction_type(row[:tipo]),
         :ok <- validate_coins(row, map_coins) do
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
end
