defmodule Leadger.Transaccion do
  defstruct [
    :id_transaccion,
    :timestamp,
    :moneda_origen,
    :moneda_destino,
    :monto,
    :cuenta_origen,
    :cuenta_destino,
    :tipo
  ]
  
  def imprimir_dic_row(dic) do
    Enum.each(dic, fn tupla ->
      IO.inspect(tupla)
    end)
  end

  def filtrar_cuentas(dic, c1, c2) do
    Stream.filter(dic, fn 
      {:ok, struct} ->
        origen = struct.cuenta_origen
        destino = struct.cuenta_destino

        ( is_nil(c1) or origen == c1 ) and
        ( is_nil(c2) or destino == c2 )

      {:error, _line} -> 
            true
    end)
  end

  def guardar_csv(dic, filename) do
    headers = ["id_transaccion", "timestamp", "moneda_origen", "moneda_destino", 
               "monto", "cuenta_origen", "cuenta_destino", "tipo"]

    maps =
      dic
      |> Enum.filter(fn
        {:ok, _struct} -> true
        {:error, _line} -> false
      end)
      |> Enum.map(fn {:ok, struct} -> Map.from_struct(struct) end)

    # Generar CSV
    ([headers | Enum.map(maps, fn map ->
      Enum.map(headers, fn header -> map[String.to_atom(header)] || "" end)
    end)])
    |> CSV.encode(separator: ?;)
    |> Enum.into(File.stream!(filename))

    IO.puts("Resultados guardados en: #{filename}")
  end
  
  def manejar_salida(data, nil), do: imprimir_dic_row(data)
  def manejar_salida(data, archivo_salida) do
    guardar_csv(data, archivo_salida)
  end

end
