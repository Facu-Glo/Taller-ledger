defmodule Ledger.Parser do
  def parser_args([]) do
    {:error, :invalid_subcommand}
  end

  def parser_args(["transacciones" | flags]) do
    case parser_flags(flags) do
      {:ok, config} -> {:transacciones, config}
      error -> error
    end
  end

  def parser_args(["balance" | flags]) do
    case parser_flags(flags) do
      {:ok, config} -> {:balance, config}
      error -> error
    end
  end

  def parser_args(_) do
    {:error, :invalid_subcommand}
  end

  def parser_flags(flags) do
    Enum.reduce_while(flags, {:ok, %{}}, fn flag, {:ok, acc} ->
      case String.split(flag, "=", parts: 2) do
        ["-c1", value] ->
          {:cont, {:ok, Map.put(acc, :cuenta_origen, value)}}

        ["-c2", value] ->
          {:cont, {:ok, Map.put(acc, :cuenta_destino, value)}}

        ["-t", value] ->
          {:cont, {:ok, Map.put(acc, :archivo_transacciones, value)}}

        ["-m", value] ->
          {:cont, {:ok, Map.put(acc, :moneda, value)}}

        ["-o", value] ->
          {:cont, {:ok, Map.put(acc, :archivo_salida, value)}}

        _ ->
          {:halt, {:error, {:unknown_flag, flag}}}
      end
    end)
  end
end
