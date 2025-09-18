defmodule Ledger.HandleError do
  def handle({:error, {:invalid_integer, line}}) do
    IO.puts("Error: ID de transacción inválido en la línea #{line}.")
  end

  def handle({:error, {:invalid_decimal, line}}) do
    IO.puts("Error: monto inválido en la línea #{line}.")
  end

  def handle({:error, {:negative_decimal, line}}) do
    IO.puts("Error: monto negativo en la línea #{line}.")
  end

  def handle({:error, {:invalid_type, line}}) do
    IO.puts("Error: tipo de transacción inválido en la línea #{line}.")
  end

  def handle({:error, {:invalid_coin, line}}) do
    IO.puts("Error: moneda inválida en la línea #{line}.")
  end

  def handle({:error, {:account_not_created_before_transfer, line}}) do
    IO.puts("Error: se intentó transferir desde/hacia una cuenta no creada (línea #{line}).")
  end

  def handle({:error, {:account_not_created_before_swap, line}}) do
    IO.puts("Error: se intentó hacer un swap desde una cuenta no creada (línea #{line}).")
  end

  def handle({:error, {:negative_balance, account, currency}}) do
    IO.puts("Error: la cuenta #{account} tiene balance negativo en #{currency}.")
  end

  def handle({:error, :file_not_found}) do
    IO.puts("Error: Archivo no encontrado.")
  end

  def handle({:error, {:file_not_found, path}}) do
    IO.puts("Error: Archivo no encontrado: #{path}")
  end

  def handle({:error, {:invalid_currency_value, currency}}) do
    IO.puts("Error: Valor de moneda inválido para #{currency}.")
  end

  def handle({:error, :invalid_currency}) do
    IO.puts("Error: Moneda inválida.")
  end

  def handle({:error, :missing_origin_account}) do
    IO.puts("Error: Debe especificar una cuenta de origen con -c1.")
  end

  def handle({:error, :invalid_subcommand}) do
    IO.puts("Error: Debe especificar un subcomando: transacciones o balance")
  end

  def handle({:error, {:unknown_flag, flag}}) do
    IO.puts("Error: Flag desconocida: #{flag}")
  end

  def handle({:error, {:validation_error, line}}) do
    IO.puts("Error: Error de validación en la línea #{line}.")
  end

  def handle({:error, reason}) do
    IO.puts("Error desconocido: #{inspect(reason)}")
  end

  def handle(error) do
    IO.puts("Error: #{inspect(error)}")
  end
end
