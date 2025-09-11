defmodule Leadger do
  def main(args) do
    case Leadger.Parser.parser_args(args) do
      {:transacciones, config} -> Leadger.HandleTransactions.handle_transactions(config)
      {:balance, config} -> Leadger.HandleBalance.handle_balance(config)
      {:error, msg} -> IO.puts("Error: #{msg}")
    end
  end
end
