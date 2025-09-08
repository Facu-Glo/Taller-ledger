defmodule Leadger.Parser do
  alias Leadger.Transaccion
  
  def decode_transacciones(path, separator) do
    File.stream!(path)
    |> CSV.decode!(headers: true, separator: separator)
    |> Stream.with_index(2)
    |> Stream.map(fn {row, line} ->
      parse_transaccion(row, line)
    end)
  end
  
  def parse_transaccion(row, line) do
    try do
      with {:ok, monto} <- validar_monto(row["monto"], line),
           {:ok, tipo} <- validar_tipo(row["tipo"], line) do

        {:ok, %Transaccion{
          id_transaccion: row["id_transaccion"],
          timestamp: row["timestamp"],
          moneda_origen: row["moneda_origen"],
          moneda_destino: row["moneda_destino"],
          monto: monto,
          cuenta_origen: row["cuenta_origen"],
          cuenta_destino: row["cuenta_destino"],
          tipo: tipo
        }}
      end

    rescue
      _ -> {:error, line}
    end
  end
  
  def validar_monto(nil, line), do: {:error, line}
  def validar_monto("", line), do: {:error, line}
  def validar_monto(monto_str, line) do
    case Float.parse(monto_str) do
      {monto, ""} when monto >= 0 -> {:ok, monto}
      _ -> {:error, line}
    end
  end
  
  def validar_tipo(nil, line), do: {:error, line}
  def validar_tipo("", line), do: {:error, line}
  def validar_tipo(tipo, line) do
    (tipo in ["transferencia", "swap", "alta_cuenta"] && {:ok, tipo}) || {:error, line}
  end

end
