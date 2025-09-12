defmodule Ledger.Parser do
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

  def parser_args(_) do
    {:error, "Debe especificar un subcomando: transacciones o balance"}
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
end
