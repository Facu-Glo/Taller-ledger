defmodule LedgerTest do
  import ExUnit.CaptureIO
  use ExUnit.Case

  # https://hexdocs.pm/ex_unit/main/ExUnit.Case.html#module-tags
  # https://hexdocs.pm/ex_unit/ExUnit.Case.html#module-tmp-dir
  @moduletag :tmp_dir
  setup context do
    currencies_content = """
    BTC;55000
    ETH;3000
    ARS;0.0012
    USDT;1
    EUR;1.18
    """

    transactions_content = """
    1;1756700000;BTC;;50000;userC;;alta_cuenta
    2;1756710000;USDT;;1000;userA;;alta_cuenta
    3;1756720000;ETH;;10;userD;;alta_cuenta
    4;1756730000;USDT;;500;userB;;alta_cuenta
    5;1756740000;USDT;USDT;100.50;userA;userB;transferencia
    6;1756750000;BTC;USDT;0.1;userC;;swap
    7;1756760000;ETH;ETH;2.5;userD;userA;transferencia
    8;1756770000;USDT;USDT;50;userA;userD;transferencia
    """

    monedas_file = Path.join(context.tmp_dir, "monedas.csv")
    transacciones_file = Path.join(context.tmp_dir, "transacciones.csv")

    File.write!(monedas_file, currencies_content)
    File.write!(transacciones_file, transactions_content)

    original_wd = File.cwd!()
    File.cd!(context.tmp_dir)

    on_exit(fn -> File.cd!(original_wd) end)

    %{
      monedas_file: monedas_file,
      transacciones_file: transacciones_file,
      tmp_dir: context.tmp_dir
    }
  end

  describe "main argument parsing" do
    test "handles empty arguments" do
      output = capture_io(fn -> Ledger.main([]) end)
      assert output =~ "Debe especificar un subcomando: transacciones o balance"
    end

    test "handles invalid subcommand" do
      output = capture_io(fn -> Ledger.main(["invalid"]) end)
      assert output =~ "Debe especificar un subcomando: transacciones o balance"
    end

    test "handles balance subcommand without -c1 flag" do
      output = capture_io(fn -> Ledger.main(["balance"]) end)
      assert output =~ "Debe especificar una cuenta de origen con -c1"
    end

    test "handles flag unknow transactions" do
      output = capture_io(fn -> Ledger.main(["transacciones", "-unknown=val"]) end)
      assert output =~ "Flag desconocida: -unknown=val"
    end

    test "handles flag unknow balance" do
      output = capture_io(fn -> Ledger.main(["balance", "-unknown=val"]) end)
      assert output =~ "Flag desconocida: -unknown=val"
    end
  end

  describe "transaction" do
    test "handles transactions subcommand" do
      output = capture_io(fn -> Ledger.main(["transacciones"]) end)
      assert output =~ "1;1756700000;BTC;;50000;userC;;alta_cuenta"
      assert output =~ "2;1756710000;USDT;;1000;userA;;alta_cuenta"
      assert output =~ "3;1756720000;ETH;;10;userD;;alta_cuenta"
      assert output =~ "4;1756730000;USDT;;500;userB;;alta_cuenta"
      assert output =~ "5;1756740000;USDT;USDT;100.50;userA;userB;transferencia"
      assert output =~ "6;1756750000;BTC;USDT;0.1;userC;;swap"
      assert output =~ "7;1756760000;ETH;ETH;2.5;userD;userA;transferencia"
      assert output =~ "8;1756770000;USDT;USDT;50;userA;userD;transferencia"
    end

    test "reads transactions from a custom file with -t flag", context do
      other_file = Path.join(context.tmp_dir, "otras_transacciones.csv")

      custom_content = """
      97;1756990000;BTC;;30000;userX;;alta_cuenta
      98;1756995000;ETH;;5;userY;;alta_cuenta
      99;1757000000;BTC;BTC;500;userX;userY;transferencia
      """

      File.write!(other_file, custom_content)

      output =
        capture_io(fn ->
          Ledger.main(["transacciones", "-t=#{other_file}"])
        end)

      assert output ==
               "97;1756990000;BTC;;30000;userX;;alta_cuenta\n" <>
                 "98;1756995000;ETH;;5;userY;;alta_cuenta\n" <>
                 "99;1757000000;BTC;BTC;500;userX;userY;transferencia\n"
    end

    test "filters by origin account with -c1 flag" do
      output =
        capture_io(fn ->
          Ledger.main(["transacciones", "-c1=userA"])
        end)

      assert output ==
               "2;1756710000;USDT;;1000;userA;;alta_cuenta\n" <>
                 "5;1756740000;USDT;USDT;100.50;userA;userB;transferencia\n" <>
                 "8;1756770000;USDT;USDT;50;userA;userD;transferencia\n"
    end

    test "filters by origin account with -c1 flag when no matches" do
      output =
        capture_io(fn ->
          Ledger.main(["transacciones", "-c1=nonexistentUser"])
        end)

      assert output == ""
    end

    test "filters by destination account with -c2 flag" do
      output =
        capture_io(fn ->
          Ledger.main(["transacciones", "-c2=userB"])
        end)

      assert output ==
               "5;1756740000;USDT;USDT;100.50;userA;userB;transferencia\n"
    end

    test "filters by origin account with -c2 flag when no matches" do
      output =
        capture_io(fn ->
          Ledger.main(["transacciones", "-c2=nonexistentUser"])
        end)

      assert output == ""
    end

    test "filters by both origin and destination accounts with -c1 and -c2 flags" do
      output =
        capture_io(fn ->
          Ledger.main(["transacciones", "-c1=userA", "-c2=userD"])
        end)

      assert output ==
               "8;1756770000;USDT;USDT;50;userA;userD;transferencia\n"
    end

    test "filters by both origin and destination accounts with -c1 and -c2 flags when no matches" do
      output =
        capture_io(fn ->
          Ledger.main(["transacciones", "-c1=userA", "-c2=nonexistentUser"])
        end)

      assert output == ""
    end

    test "handles invalid transaction file" do
      output =
        capture_io(fn ->
          Ledger.main(["transacciones", "-t=nonexistent.csv"])
        end)

      assert output =~ "Error: Archivo no encontrado."
    end

    test "outputs to a file with -o flag", context do
      output_file = Path.join(context.tmp_dir, "outputTest.csv")

      capture_io(fn ->
        Ledger.main(["transacciones", "-o=#{output_file}"])
      end)

      assert File.exists?(output_file)
      content = File.read!(output_file)
      assert content == File.read!(context.transacciones_file)
    end
  end

  describe "balance" do
    test "calculates balance for an account" do
      output =
        capture_io(fn ->
          Ledger.main(["balance", "-c1=userA"])
        end)

      assert output =~ "USDT=849.500000\n"
    end

    test "handles -m flag with non-existent currency" do
      output =
        capture_io(fn ->
          Ledger.main(["balance", "-c1=userA", "-m=NONEXISTENT"])
        end)

      assert output =~ "Error: Moneda inválida."
    end

    test "calculates balance for an account with -m flag" do
      output =
        capture_io(fn ->
          Ledger.main(["balance", "-c1=userA", "-m=EUR"])
        end)

      assert output =~ "EUR=719.915254\n"
    end

    test "handles account with swap transaction" do
      output =
        capture_io(fn ->
          Ledger.main(["balance", "-c1=userC"])
        end)

      assert output =~ "BTC=49999.900000\n"
      assert output =~ "USDT=5500.000000"
    end

    test "outputs balance to file when -o flag is used", context do
      output_file = Path.join(context.tmp_dir, "balance_output.csv")

      capture_io(fn ->
        Ledger.main(["balance", "-c1=userA", "-o=#{output_file}"])
      end)

      assert File.exists?(output_file)
      content = File.read!(output_file)
      assert content =~ "USDT;849.500000\n"
    end

    test "returns error if transaction file cannot be read" do
      filename = "nonexistent.csv"
      coins = %{"USD" => Decimal.new(1)}

      assert Ledger.BalanceCalculator.calculate_balance(filename, "userA", coins, %{}) ==
               {:error, :file_not_found}
    end

    test "apply_transaction leaves acc unchanged if transaction is irrelevant to account" do
      acc = %{"USD" => Decimal.new(100)}

      transaction = %{
        tipo: "transferencia",
        cuenta_origen: "userB",
        cuenta_destino: "userC",
        moneda_origen: "USD",
        monto: Decimal.new(50)
      }

      result =
        Ledger.BalanceCalculator.apply_transaction(acc, transaction, "userA", %{
          "USD" => Decimal.new(1)
        })

      assert result == acc
    end

    test "apply_transaction updates balance when account is the destination" do
      acc = %{"USD" => Decimal.new(100)}

      transaction = %{
        tipo: "transferencia",
        cuenta_origen: "userB",
        cuenta_destino: "userA",
        moneda_origen: "USD",
        monto: Decimal.new(50)
      }

      result =
        Ledger.BalanceCalculator.apply_transaction(acc, transaction, "userA", %{
          "USD" => Decimal.new(1)
        })

      assert result["USD"] == Decimal.new(150)
    end

    test "get_converted_amount returns zero if destiny coin is zero" do
      coins = %{"USD" => Decimal.new(1), "BTC" => Decimal.new(0)}
      transaction = %{moneda_origen: "USD", moneda_destino: "BTC", monto: Decimal.new(100)}

      assert Ledger.BalanceCalculator.get_converted_amount(transaction, coins) == Decimal.new(0)
    end

    test "convert_to_currency returns zero if target currency value is zero" do
      balances = %{"USD" => Decimal.new(100)}
      coins = %{"USD" => Decimal.new(1), "ZERO" => Decimal.new(0)}

      assert Ledger.BalanceCalculator.convert_to_currency(balances, "ZERO", coins) ==
               {:ok, %{"ZERO" => Decimal.new(0)}}
    end
  end

  describe "error handling" do
    test "handles invalid transaction format" do
      invalid_content = """
      1;1754937004;USDT;100.50;userA;transferencia
      2;1755541804;BTC;USDT;0.1;userB;;swap
      """

      File.write!("transacciones.csv", invalid_content)

      output = capture_io(fn -> Ledger.main(["transacciones"]) end)
      assert output =~ "Error:"
    end

    test "handles negative amounts" do
      invalid_content = """
      1;1756700000;BTC;;-50000;userC;;alta_cuenta
      """

      File.write!("transacciones.csv", invalid_content)

      output = capture_io(fn -> Ledger.main(["transacciones"]) end)
      assert output =~ "Error: monto negativo en la línea 1."
    end

    test "handles invalid currency in transactions" do
      invalid_content = """
      1;1756700000;INVALID;;50000;userC;;alta_cuenta
      """

      File.write!("transacciones.csv", invalid_content)

      output = capture_io(fn -> Ledger.main(["transacciones"]) end)
      assert output =~ "Error: moneda inválida en la línea 1."
    end

    test "hanles invalid transaction type" do
      invalid_content = """
      1;1756700000;BTC;;50000;userC;;invalid_type
      """

      File.write!("transacciones.csv", invalid_content)

      output = capture_io(fn -> Ledger.main(["transacciones"]) end)
      assert output =~ "Error: tipo de transacción inválido en la línea 1."
    end

    test "handle without account for transfer" do
      invalid_content = """
      1;1754937004;USDT;USDT;100.50;userA;;transferencia
      """

      File.write!("transacciones.csv", invalid_content)

      output = capture_io(fn -> Ledger.main(["transacciones"]) end)
      assert output =~ "Error: se intentó transferir desde/hacia una cuenta no creada"
    end

    test "handles empty account" do
      invalid_content = """
      1;1754937004;USDT;USDT;100.50;;;transferencia
      """

      File.write!("transacciones.csv", invalid_content)
      output = capture_io(fn -> Ledger.main(["transacciones"]) end)
      assert output =~ "Error: se intentó transferir desde/hacia una cuenta no creada"
    end
  end

  describe "csv files" do
    test "handles missing currencies file" do
      File.rm!("monedas.csv")

      output = capture_io(fn -> Ledger.main(["balance", "-c1=userA"]) end)
      assert output =~ "Error: Archivo no encontrado: monedas.csv"
    end

    test "handles missing transactions file" do
      File.rm!("transacciones.csv")
      output = capture_io(fn -> Ledger.main(["transacciones"]) end)
      assert output =~ "Error: Archivo no encontrado."
    end

    test "returns error when file does not exist" do
      assert {:error, _} = Ledger.CurrencyLoader.load_monedas("nonexistent.csv")
    end

    test "returns error when currency value is not decimal", context do
      bad_file = Path.join(context.tmp_dir, "bad_monedas.csv")
      File.write!(bad_file, "BTC;ABC\nUSDT;1")
      assert {:error, _} = Ledger.CurrencyLoader.load_monedas(bad_file)
    end

    test "fails if monedas.csv cannot be parsed" do
      bad_file = "bad_monedas.csv"
      File.write!(bad_file, "BTC;ABC\nUSDT;1")

      assert Ledger.CurrencyLoader.load_monedas(bad_file) ==
               {:error, {:invalid_currency_value, "BTC"}}
    end

    test "fails if csv is invalid" do
      invalid_content = "1 no es un csv valido"
      File.write!("monedas_invalida.csv", invalid_content)

      assert {:error, {:invalid_currency_value, "1 no es un csv valido"}} =
               Ledger.CurrencyLoader.load_monedas("monedas_invalida.csv")
    end

    test "operations id is nil" do
      invalid_content = ";1756700000;BTC;;50000;userC;;alta_cuenta"
      File.write!("transacciones.csv", invalid_content)
      output = capture_io(fn -> Ledger.main(["transacciones"]) end)
      assert output =~ "Error: ID de transacción inválido en la línea 1."
    end

    test "returns error for invalid transaction type" do
      tx = %{tipo: "compra", moneda_origen: "BTC", moneda_destino: "USDT"}

      assert Ledger.Validators.validate_transaction_currencies(tx, %{"BTC" => 1, "USDT" => 1}) ==
               {:error, :invalid_type}
    end

    test "returns error for completely invalid structure" do
      assert Ledger.Validators.validate_transaction_currencies(%{}, %{}) ==
               {:error, :invalid_type}
    end

    test "returns error for nil" do
      assert Ledger.Validators.parse_integer(nil) == {:error, :invalid_integer}
    end

    test "returns error for empty string integer" do
      assert Ledger.Validators.parse_integer("") == {:error, :invalid_integer}
    end

    test "returns error for empty string decimal" do
      assert Ledger.Validators.parse_decimal("") == {:error, :invalid_decimal}
    end

    test "returns error for non-numeric string" do
      assert Ledger.Validators.parse_integer("abc") == {:error, :invalid_integer}
    end
  end

  describe "HandleError full coverage via CSVs and arguments" do
    @csv_errors_dir "tmp_csv_errors"

    setup do
      File.mkdir_p!(@csv_errors_dir)
      :ok
    end

    test "invalid_integer transaction ID" do
      file = Path.join(@csv_errors_dir, "invalid_id.csv")
      File.write!(file, ";1756700000;BTC;;50000;userC;;alta_cuenta")

      output = capture_io(fn -> Ledger.main(["transacciones", "-t=#{file}"]) end)
      assert output =~ "Error: ID de transacción inválido en la línea 1."
    end

    test "negative amount" do
      file = Path.join(@csv_errors_dir, "negative_amount.csv")
      File.write!(file, "1;1756700000;BTC;;-50000;userC;;alta_cuenta")

      output = capture_io(fn -> Ledger.main(["transacciones", "-t=#{file}"]) end)
      assert output =~ "Error: monto negativo en la línea 1."
    end

    test "invalid decimal amount" do
      file = Path.join(@csv_errors_dir, "invalid_decimal.csv")
      File.write!(file, "1;1756700000;BTC;;ABC;userC;;alta_cuenta")

      output = capture_io(fn -> Ledger.main(["transacciones", "-t=#{file}"]) end)
      assert output =~ "Error: monto inválido en la línea 1."
    end

    test "invalid transaction type" do
      file = Path.join(@csv_errors_dir, "invalid_type.csv")
      File.write!(file, "1;1756700000;BTC;;50000;userC;;invalid_type")

      output = capture_io(fn -> Ledger.main(["transacciones", "-t=#{file}"]) end)
      assert output =~ "Error: tipo de transacción inválido en la línea 1."
    end

    test "invalid coin in transaction" do
      file = Path.join(@csv_errors_dir, "invalid_coin.csv")
      File.write!(file, "1;1756700000;XYZ;;50000;userC;;alta_cuenta")

      output = capture_io(fn -> Ledger.main(["transacciones", "-t=#{file}"]) end)
      assert output =~ "Error: moneda inválida en la línea 1."
    end

    test "transfer from non-existent account" do
      file = Path.join(@csv_errors_dir, "missing_origin.csv")
      File.write!(file, "1;1756700000;USDT;USDT;100;userA;;transferencia")

      output = capture_io(fn -> Ledger.main(["transacciones", "-t=#{file}"]) end)
      assert output =~ "Error: se intentó transferir desde/hacia una cuenta no creada"
    end

    test "swap from non-existent account" do
      file = Path.join(@csv_errors_dir, "swap_missing.csv")
      File.write!(file, "1;1756700000;BTC;USDT;0.1;userX;;swap")

      output = capture_io(fn -> Ledger.main(["transacciones", "-t=#{file}"]) end)
      assert output =~ "Error: se intentó hacer un swap desde una cuenta no creada"
    end

    test "transaction file not found" do
      output = capture_io(fn -> Ledger.main(["transacciones", "-t=nonexistent.csv"]) end)
      assert output =~ "Error: Archivo no encontrado."
    end

    test "currencies file not found" do
      output =
        capture_io(fn ->
          Ledger.main(["balance", "-c1=userA", "-m=BTC", "-t=nonexistent.csv"])
        end)

      assert output =~ "Error: Archivo no encontrado"
    end

    test "invalid currency value in monedas.csv" do
      file = Path.join(@csv_errors_dir, "bad_monedas.csv")
      File.write!(file, "BTC;ABC\nUSDT;1")

      output =
        capture_io(fn ->
          Ledger.main(["balance", "-c1=userA", "-m=BTC", "-t=bad.csv"])
        end)

      assert output =~ "Error"
    end

    test "invalid subcommand" do
      output = capture_io(fn -> Ledger.main(["invalid_subcommand"]) end)
      assert output =~ "Debe especificar un subcomando"
    end

    test "unknown flag" do
      output = capture_io(fn -> Ledger.main(["transacciones", "-x=1"]) end)
      assert output =~ "Flag desconocida"
    end

    test "negative balance error" do
      content = """
      1;1756700000;USDT;;1000;userA;;alta_cuenta
      2;1756701000;USDT;;2000;userB;;alta_cuenta
      3;1756702000;USDT;USDT;1001;userA;userB;transferencia
      """

      File.write!("transacciones.csv", content)

      output = capture_io(fn -> Ledger.main(["balance", "-c1=userA"]) end)
      assert output =~ "Error: la cuenta userA tiene balance negativo en USDT."
    end

    test "invalid currency value error" do
      File.write!("monedas.csv", "BTC;ABC\nUSDT;1")

      output = capture_io(fn -> Ledger.main(["balance", "-c1=userA"]) end)
      assert output =~ "Error: Valor de moneda inválido para BTC."
    end
  end
end
