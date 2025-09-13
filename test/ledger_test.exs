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
    1;1754937004;USDT;USDT;100.50;userA;userB;transferencia
    2;1755541804;BTC;USDT;0.1;userB;;swap
    3;1756751404;BTC;;50000;userC;;alta_cuenta
    4;1756851404;ETH;ETH;2.5;userA;userD;transferencia
    5;1756951404;USDT;;1000;userA;;alta_cuenta
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

  describe "main" do
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

    test "handles transactions subcommand" do
      output = capture_io(fn -> Ledger.main(["transacciones"]) end)
      assert output =~ "1;1754937004;USDT;USDT;100.50;userA;userB;transferencia"
    end
  end
end
