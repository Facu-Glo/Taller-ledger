defmodule Leadger.Parser do

  def parser_args([], _) do
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


  def handle_transactions(config) do
    filename = Map.get(config, :archivo_transacciones, "transacciones.csv")

    coins = load_monedas()

    case read_and_validate_transactions(filename, coins) do
      {:ok, map} ->
        filter = filter_transactions(map, config)
        output_results_transaction(filter, config)

      {:error, line_number} ->
        IO.puts("Error en la línea #{line_number} del archivo de transacciones.")
        IO.inspect({:error, line_number})
    end
  end

  def read_and_validate_transactions(filename, map_coins) do
    list_headers = [
      :id_transaccion,
      :timestamp,
      :moneda_origen,
      :moneda_destino,
      :monto,
      :cuenta_origen,
      :cuenta_destino,
      :tipo
    ]

    transaction =
      File.stream!(filename)
      |> CSV.decode!(headers: list_headers, separator: ?;)
      |> Stream.with_index(1)
      |> Enum.reduce_while([], fn {row, line_number}, acc ->
        case validate_transaction_row(row, line_number, map_coins) do
          {:ok, map} ->
            {:cont, [map | acc]}

          {:error, _} ->
            {:halt, {:error, line_number}}
        end
      end)

    case transaction do
      {:error, line_number} -> {:error, line_number}
      valid -> {:ok, Enum.reverse(valid)}
    end
  end

  def load_monedas(path \\ "monedas.csv") do
    headers = [:moneda, :valor]

    File.stream!(path)
    |> CSV.decode!(headers: headers, separator: ?;)
    |> Enum.reduce(%{}, fn row, acc ->
      case parse_float(row[:valor]) do
        {:ok, value} -> Map.put(acc, row[:moneda], value)
        _ -> acc
      end
    end)
  end


  def validate_transaction_row(row, line_number, map_coins) do
    with {:ok, id} <- parse_integer(row[:id_transaccion]),
         {:ok, money} <- parse_float(row[:monto]),
         :ok <- validate_transaction_type(row[:tipo]),
         :ok <- validate_coins(row, map_coins) do
      {:ok,
       %{
         id: id,
         timestamp: row[:timestamp],
         moneda_origen: row[:moneda_origen],
         moneda_destino: row[:moneda_destino],
         monto: money,
         cuenta_origen: row[:cuenta_origen],
         cuenta_destino: row[:cuenta_destino],
         tipo: row[:tipo]
       }}
    else
      _ -> {:error, line_number}
    end
  end

  def parse_integer(nil), do: {:error, nil}
  def parse_integer(""), do: {:error, nil}

  def parse_integer(str) do
    case Integer.parse(str) do
      {int, ""} when int >= 0 -> {:ok, int}
      _ -> {:error, nil}
    end
  end

  def parse_float(string) do
    case Float.parse(string) do
      {number, ""} when number >= 0.0 -> {:ok, number}
      _ -> {:error, nil}
    end
  end

  def validate_transaction_type(transaction_type)
      when transaction_type in ["swap", "transferencia", "alta_cuenta"],
      do: :ok

  def validate_transaction_type(_), do: {:error, :invalid_type}

  def validate_coins(%{tipo: "swap", moneda_origen: origen, moneda_destino: destino}, map_coins)
      when origen != destino do
    if Map.has_key?(map_coins, origen) and Map.has_key?(map_coins, destino) do
      :ok
    else
      {:error, :invalid_coin}
    end
  end

  def validate_coins(
        %{tipo: "transferencia", moneda_origen: moneda, moneda_destino: moneda},
        map_coins
      ) do
    if Map.has_key?(map_coins, moneda), do: :ok, else: {:error, :invalid_coin}
  end

  def validate_coins(%{tipo: "alta_cuenta", moneda_origen: origen, moneda_destino: ""}, map_coins) do
    if Map.has_key?(map_coins, origen), do: :ok, else: {:error, :invalid_coin}
  end

  def validate_coins(_, _), do: {:error, :invalid_type}


  def write_to_file_transaction(data, filename) do
    content =
      Enum.map(data, fn transaction ->
        [
          transaction.id,
          transaction.timestamp,
          transaction.moneda_origen,
          transaction.moneda_destino,
          transaction.monto,
          transaction.cuenta_origen,
          transaction.cuenta_destino,
          transaction.tipo
        ]
      end)

    File.open!(filename, [:write], fn file ->
      content
      |> CSV.encode(separator: ?;)
      |> Enum.each(fn line -> IO.write(file, line) end)
    end)
  end

  def console_output_transaction(data) do
    Enum.map(data, fn transaction ->
      IO.puts(
        "#{transaction.id};#{transaction.timestamp};#{transaction.moneda_origen};#{transaction.moneda_destino};#{transaction.monto};#{transaction.cuenta_origen};#{transaction.cuenta_destino};#{transaction.tipo}"
      )
    end)
  end

  def output_results_transaction(lis_transaction, opts) do
    case Map.get(opts, :archivo_salida) do
      nil -> console_output_transaction(lis_transaction)
      filename -> write_to_file_transaction(lis_transaction, filename)
    end
  end

  def write_to_file_balance(data, filename) do
    IO.inspect(data)

    content =
      Enum.map(data, fn {currency, amount} ->
        "#{currency};#{amount}\n"
      end)

    File.write!(filename, content)
  end

  def console_output_balance(data) do
    Enum.each(data, fn {currency, amount} ->
      IO.puts("#{currency}=#{amount}")
    end)
  end

  def output_results_balance(balance, opts) do
    case Map.get(opts, :archivo_salida) do
      nil -> console_output_balance(balance)
      filename -> write_to_file_balance(balance, filename)
    end
  end


  def filter_origin_account(list_transaction, nil), do: list_transaction

  def filter_origin_account(list_transaction, cuenta_origen) do
    Enum.filter(list_transaction, fn transaction ->
      transaction.cuenta_origen == cuenta_origen
    end)
  end

  def filter_destination_account(list_transaction, nil), do: list_transaction

  def filter_destination_account(list_transaction, cuenta_destino) do
    Enum.filter(list_transaction, fn transaction ->
      transaction.cuenta_destino == cuenta_destino
    end)
  end

  def filter_transactions(list_transaction, opts) do
    list_transaction
    |> filter_origin_account(Map.get(opts, :cuenta_origen))
    |> filter_destination_account(Map.get(opts, :cuenta_destino))
  end


  def handle_balance(config) do
    coins = load_monedas()

    case Map.get(config, :cuenta_origen) do
      nil ->
        IO.puts("Debe especificar una cuenta de origen con -c1")

      origin_account ->
        filename = Map.get(config, :archivo_transacciones, "transacciones.csv")

        case calculate_balance(filename, origin_account, coins, config) do
          {:ok, balance} ->
            output_results_balance(balance, config)

          {:error, line_number} ->
            IO.puts("Error en la línea #{line_number} del archivo de transacciones.")
        end
    end
  end

  def calculate_balance(filename, origin_account, coins, opts) do
    case read_and_validate_transactions(filename, coins) do
      {:ok, list_transaction} ->
        account = filter_transactions(list_transaction, %{cuenta_origen: origin_account})
        balances = compute_balance(account, origin_account, coins)

        case Map.get(opts, :moneda) do
          nil ->
            {:ok, balances}

          target_currency ->
            convert_to_currency(balances, target_currency, coins)
        end

      {:error, line_number} ->
        {:error, line_number}
    end
  end

  def compute_balance(accounts, origin_account, coins) do
    Enum.reduce(accounts, %{}, fn transaction, acc ->
      apply_transaction(acc, transaction, origin_account, coins)
    end)
  end

  def update_balance(acc, currency, amount) do
    Map.update(acc, currency, amount, fn current_value -> current_value + amount end)
  end

  def apply_transaction(
        acc,
        %{
          tipo: "alta_cuenta",
          moneda_origen: moneda,
          monto: monto
        },
        _origin_account,
        _coins
      ) do
    currency = if moneda != "", do: moneda, else: "USD"
    update_balance(acc, currency, monto)
  end

  def apply_transaction(acc, %{tipo: "transferencia"} = map, origin_account, _coins) do
    cond do
      map.cuenta_origen == origin_account -> update_balance(acc, map.moneda_origen, -map.monto)
      map.cuenta_destino == origin_account -> update_balance(acc, map.moneda_origen, map.monto)
      true -> acc
    end
  end

  def apply_transaction(
        acc,
        %{
          tipo: "swap",
          moneda_origen: moneda_origen,
          moneda_destino: moneda_destino,
          monto: monto
        },
        _origin_account,
        coins
      ) do
    converted_amount =
      get_converted_amount(
        %{moneda_origen: moneda_origen, moneda_destino: moneda_destino, monto: monto},
        coins
      )

    acc
    |> update_balance(moneda_origen, -monto)
    |> update_balance(moneda_destino, converted_amount)
  end

  def get_converted_amount(map, coins) do
    origin_coin = Map.get(coins, map.moneda_origen)
    destiny_coin = Map.get(coins, map.moneda_destino)

    if destiny_coin > 0 do
      map.monto * origin_coin / destiny_coin
    else
      0.0
    end
  end

  def convert_to_currency(balances, target_currency, coins) do
    if Map.has_key?(coins, target_currency) do
      target_value = Map.get(coins, target_currency)

      total =
        Enum.reduce(balances, 0.0, fn {currency, amount}, acc ->
          currency_value = Map.get(coins, currency)

          if target_value > 0 do
            acc + amount * currency_value / target_value
          else
            acc
          end
        end)

      {:ok, %{target_currency => total}}
    else
      {:error, :invalid_target_currency}
    end
  end
end
