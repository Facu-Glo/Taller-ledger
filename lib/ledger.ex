defmodule Ledger do
  def main(args) do
    case Ledger.Parser.parser_args(args) do
      {:transacciones, config} -> Ledger.HandleTransactions.handle_transactions(config)
      {:balance, config} -> Ledger.HandleBalance.handle_balance(config)
      {:error, msg} -> IO.puts("Error: #{msg}")
    end
  end
end
