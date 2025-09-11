defmodule Leadger do
  def main(args) do
    case Leadger.Parser.parser_args(args) do
      {:transacciones, config} -> Leadger.Parser.handle_transactions(config)
      {:balance, config} -> Leadger.Parser.handle_balance(config)
    end
  end
end
