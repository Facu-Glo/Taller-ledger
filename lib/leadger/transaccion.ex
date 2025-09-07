defmodule Leadger.Transaccion do
  
  def imprimir_dic_row(dic) do
    Enum.each(dic, fn row -> IO.inspect(row) end)
  end

  def filtrar_c1(dic, nil), do: dic
  def filtrar_c1(dic, cuenta) do
    Stream.filter(dic, fn row -> row["cuenta_origen"] == cuenta end)
  end

  def filtrar_c2(dic, nil), do: dic
  def filtrar_c2(dic, cuenta) do
    Stream.filter(dic, fn row -> row["cuenta_destino"] == cuenta end)
  end

  def guardar_csv(data, filename) do
    headers = ["id_transaccion", "timestamp", "moneda_origen", "moneda_destino", 
               "monto", "cuenta_origen", "cuenta_destino", "tipo"]
    
    ([headers | Enum.map(data, fn row ->
      Enum.map(headers, fn header -> row[header] || "" end)
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
