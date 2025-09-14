# Ledger

Un sistema de libro contable que registra transacciones de diferentes monedas entre usuarios, utilizando archivos CSV como base de datos.

## Estructura del Proyecto

``` bash
ledger/
├── lib/
│   ├── ledger.ex                 # Módulo principal y parser de argumentos
│   └── modulos/
│      ├── balance_calculator.ex  # Lógica de cálculo de balances
│      ├── currency_loader.ex     # Carga de monedas desde CSV
│      ├── handle_balance.ex      # Manejo del subcomando balance
│      ├── handle_transactions.ex # Manejo del subcomando transacciones
│      ├── output_writer.ex       # Escritura de resultados
│      ├── transaction_reader.ex  # Lectura y filtrado de transacciones
│      └── validators.ex          # Validaciones de datos
├── mix.exs   
├── test/
│   └── ...
├── monedas.csv
├── transacciones.csv
└── README.md
```

El sistema está compuesto por dos archivos CSV principales:
### monedas.csv

Registro maestro de monedas disponibles y su valor de referencia en USD.

**Formato:**
```csv
nombre_moneda;precio_usd
```
**Ejemplo**
```csv
BTC;55000
ETH;3000
ARS;0.0012
USDT;1
EUR;1.18
```
### transacciones.csv

Registro inmutable de toda la actividad financiera del sistema.

**Formato:**
```csv
id_transaccion;timestamp;moneda_origen;moneda_destino;monto;cuenta_origen;cuenta_destino;tipo
```
**Tipos de transacciones:**

- `transferencia`: Transfiere un monto de una cuenta a otra
- `swap`: Convierte un monto de una moneda a otra
- `alta_cuenta`: Crea una cuenta y fija su valor inicial

**Ejemplo:**
```csv
1;1754937004;USDT;USDT;100.50;userA;userB;transferencia
2;1755541804;BTC;USDT;0.1;userB;;swap
3;1756751404;BTC;;50000;userC;;alta_cuenta
```

## Compilación y Ejecución

### Compilación

1. Instalar dependencias

```bash
mix deps.get
```

2. Compilar el proyecto

```bash
mix compile
```

3. Generar el ejecutable

```bash
mix escript.build
```

Esto generará un archivo ejecutable llamado `ledger` en el directorio del proyecto.

### Ejecución

Una vez compilado, el programa se ejecuta con:

```bash
./ledger <subcomando> [flags]
```

## Uso

### Sintaxis General

```bash
./ledger <subcomando> [flags]
```
### Subcomandos

**1. transacciones**
Lista transacciones que cumplen con los filtros especificados.

**2. balance**
Calcula el balance de una cuenta específica.


### Flags Disponibles

| Flag  | Descripción                                             | Obligatorio    |
| ----- | ------------------------------------------------------- | -------------- |
| `-c1` | Cuenta origen                                           | Para `balance` |
| `-c2` | Cuenta destino                                          | No             |
| `-t`  | Archivo de transacciones (default: `transacciones.csv`) | No             |
| `-m`  | Moneda para cálculo de balances                         | No             |
| `-o`  | Archivo de salida (default: terminal)                   | No             |
## Ejemplos de Uso

### Listar Transacciones
```bash
# Listar todas las transacciones
./ledger transacciones

# Listar transacciones de un archivo específico desde cuenta 345
./ledger transacciones -t=transac.csv -c1=345 -o=result.csv

# Listar transacciones entre cuentas específicas
./ledger transacciones -c1=userA -c2=userB
```

### Consultar Balances
```bash
# Balance de todas las monedas de la cuenta 867
./ledger balance -c1=867

# Balance de la cuenta 867 convertido a BTC
./ledger balance -c1=867 -m=BTC

# Guardar balance en archivo
./ledger balance -c1=userA -o=balance_output.csv
```

## Manejo de Errores

El sistema maneja los siguientes tipos de errores:

### Errores de Formato

- **Líneas malformadas**: `{:error, <nro_linea>}`
- **IDs de transacción inválidos**: Deben ser números enteros no negativos
- **Montos inválidos**: Deben ser números decimales no negativos
- **Tipos de transacción inválidos**: Solo se permiten `transferencia`, `swap`, `alta_cuenta`

### Errores de Validación de Negocio

- **Monedas inexistentes**: Las monedas usadas en transacciones deben existir en `monedas.csv`
- **Cuentas no creadas**: Las cuentas deben ser creadas con `alta_cuenta` antes de usarse
- **Swaps inválidos**: En swaps, `moneda_origen` y `moneda_destino` deben ser diferentes

### Errores de Archivos

- **Archivo no encontrado**: Cuando el archivo de transacciones o monedas no existe
- **Errores de formato CSV**: Problemas al parsear los archivos CSV

### Errores de Comandos

- **Subcomando faltante**: Se debe especificar `transacciones` o `balance`
- **Flags inválidos**: Flags no reconocidos o con formato incorrecto
- **Cuenta origen faltante**: Para el subcomando `balance` es obligatorio especificar `-c1`

## Tests
#### Ejecutar Tests

```bash
mix coveralls
```
