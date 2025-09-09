defmodule Leadger.Parser do

  # Transacciones
  # -----------------------------------------------------------#
  alias Leadger.Transaccion
  
  def parse_transaccion(row, line, monedas) do
    try do
      with {:ok, monto} <- validar_monto(row["monto"], line),
           {:ok, tipo_transferencia} <- validar_tipo(row["tipo"], line),
           {:ok, moneda_origen} <- validar_moneda_origen(row["moneda_origen"],line, monedas),
           {:ok, moneda_destino} <- validar_moneda_destino(row["moneda_destino"],line, monedas, tipo_transferencia) do

        {:ok, %Transaccion{
          id_transaccion: row["id_transaccion"],
          timestamp: row["timestamp"],
          moneda_origen: moneda_origen,
          moneda_destino: moneda_destino,
          monto: monto,
          cuenta_origen: row["cuenta_origen"],
          cuenta_destino: row["cuenta_destino"],
          tipo: tipo_transferencia
        }}
      end

    rescue
      _ -> {:error, line}
    end
  end
  
  def validar_tipo_moneda(tipo_moneda, line, monedas_disponible) do
    if Map.has_key?(monedas_disponible, tipo_moneda) do
      {:ok, tipo_moneda}
    else
      {:error, line}
    end
  end

  def validar_moneda_origen(tipo_moneda, line, monedas), do: validar_tipo_moneda(tipo_moneda, line, monedas)

  def validar_moneda_destino("", _line, _monedas, "alta_cuenta"), do: {:ok, ""}
  def validar_moneda_destino(tipo_moneda, line, monedas, tipo_transferencia) when tipo_transferencia
    in ["transferencia", "swap"] do
    validar_tipo_moneda(tipo_moneda, line, monedas)
  end

  def validar_monto(nil, line), do: {:error, line}
  def validar_monto("", line), do: {:error, line}
    def validar_monto(monto_str, line) do
      result = Float.parse(monto_str)
      case result do
        {monto, ""} when monto >= 0 -> {:ok, monto}
        _ -> {:error, line}
      end
    end
  
  def validar_tipo(nil, line), do: {:error, line}
  def validar_tipo("", line), do: {:error, line}
  def validar_tipo(tipo, line) do
    (tipo in ["transferencia", "swap", "alta_cuenta"] && {:ok, tipo}) || {:error, line}
  end

  def decode_transacciones(path, separator, monedas) do
    File.stream!(path)
    |> CSV.decode!(headers: true, separator: separator)
    |> Stream.with_index(2)
    |> Stream.map(fn {row, line} ->
      parse_transaccion(row, line, monedas)
    end)
  end
  
  # -----------------------------------------------------------#
  # monedas

  def validar_monedas(row, line) do
    nombre = row["nombre_moneda"]
    precio_str = row["precio_usd"]

    cond do 
      is_nil(nombre) || nombre == "" ->
        {:error, line}
      is_nil(precio_str) || precio_str == "" ->
        {:error, line}
      true -> 
        result = Float.parse(precio_str)
        case result do
          {precio, ""} when precio >= 0 -> 
            {:ok, %{nombre_moneda: nombre, precio_usd: precio}}
          _ -> {:error, line}
        end
    end
  end

def decode_monedas(path, separator) do
  File.stream!(path)
  |> CSV.decode!(headers: true, separator: separator)
  |> Stream.with_index(2)
  |> Stream.map(fn {row, line} -> 
      validar_monedas(row, line) 
    end)
  |> Stream.filter(fn
      {:ok, _ } -> true
      {:error, _line} -> false
    end)
  |> Stream.map(fn {:ok, map} -> 
      {map.nombre_moneda, map.precio_usd}
    end)
  |> Enum.into(%{})
end

end
