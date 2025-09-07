defmodule Leadger.Transaccion do
  
  def imprimir_dic_row(dic) do
    Enum.each(dic, fn row -> IO.inspect(row) end)
  end

  def filtrar_cuentas(dic, c1, c2) do
    Stream.filter(dic, fn row ->
      (is_nil(c1) or row["cuenta_origen"] == c1) and
      (is_nil(c2) or row["cuenta_destino"] == c2)
    end)
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
