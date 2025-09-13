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
      99;1757000000;USDT;USDT;500;userX;userY;transferencia
      """

      File.write!(other_file, custom_content)

      output =
        capture_io(fn ->
          Ledger.main(["transacciones", "-t=#{other_file}"])
        end)

      assert output =~ "99;1757000000;USDT;USDT;500;userX;userY;transferencia"
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

    test "handles invalid transaction file" do
      output =
        capture_io(fn ->
          Ledger.main(["transacciones", "-t=nonexistent.csv"])
        end)

      assert output =~ "Error: File not found"
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
    test "calculates balance for an account"do
      output =
        capture_io(fn ->
          Ledger.main(["balance", "-c1=userA"])
        end)

      assert output =~ "USDT=849.500000\n"
      assert output =~ "ETH=2.500000"
    end
  end
end
