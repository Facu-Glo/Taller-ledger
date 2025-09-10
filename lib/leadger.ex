defmodule Leadger do
  def main(args) do
    case Leadger.Parser.parser_args(args) do
      {:transacciones, config} -> Leadger.Parser.handle_transactions(config)
      {:balance, _config} -> IO.puts("funciona")
      {:error, msg} -> IO.puts("Error: #{msg}")
    end
  end
end
