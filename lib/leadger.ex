defmodule Leadger do

########################################################################################
# FLAGS:
# -c1: especifica la cuenta origen (si no se completa, toma todas las cuentas)
# -c2: especifica la cuenta destino (si no se completa, toma todas las cuentas )
# -t: archivo transacciones input (si no se completa toma por default transacciones.csv )
# -m: moneda a utilizar para el cálculo de balances.
# -o: archivo output (si no se completa se imprimen por terminal)
#---------------------------------------------------------------------------------------
# opts es una keyword list con las opciones (flags) que reconoció
# positional Son los argumentos que no son flags, es decir, los "sueltos"
# invalid son los flags inválidos
#---------------------------------------------------------------------------------------

  def main(args) do
    {opts, positional, _invalid} =
      OptionParser.parse(args,
        switches: [c1: :string, c2: :string, t: :string, m: :string, o: :string]
      )

    monedas = ("monedas.csv")
    |> Leadger.Parser.decode_monedas(?;)

    case positional do
      ["transacciones"] ->
        dic = (opts[:t] || "transaccion.csv")
        |> Leadger.Parser.decode_transacciones(?;, monedas)
        |> Leadger.Transaccion.filtrar_cuentas(opts[:c1], opts[:c2])
        Leadger.Transaccion.manejar_salida(dic, opts[:o])

      ["balance"] -> 
        IO.puts("Proximamente: balance")

      _ -> IO.puts("Comando no reconocido. Use 'transaccion' o 'balance'")
    end
  end

end
