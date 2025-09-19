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
│      ├── handle_error.ex        # Manejo de errores
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

## Archivos CSV

El sistema está compuesto por dos archivos CSV principales con formato específico:
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
**IMPORTANTE:** El sistema únicamente acepta archivos en formato CSV con separador punto y coma (`;`). No se soportan otros formatos de archivo.
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
## Formato de Salida

### Balance

El formato de salida para balances es:
```bash
MONEDA=BALANCE
```
Donde BALANCE siempre se muestra con 6 decimales:
```bash
BTC=2.453445
ARS=234435345.000000
```
### Transacciones

Las transacciones se muestran en formato CSV con separador `;`:
```bash
id;timestamp;moneda_origen;moneda_destino;monto;cuenta_origen;cuenta_destino;tipo
```
**Salida por terminal:**
```bash
1;1754937004;USDT;USDT;100.50;userA;userB;transferencia
2;1755541804;BTC;USDT;0.1;userB;;swap
```
## Manejo de Errores

El sistema maneja los siguientes tipos de errores, mostrando tanto el formato de tupla requerido `{:error, <nro_linea>}` como mensajes descriptivos:

### Errores de Validación de Datos (con número de línea)

- **ID de transacción inválido** (`invalid_integer`): El ID debe ser un número entero no negativo
  ```
  {:error, nro_linea}
  Error: ID de transacción inválido en la línea nro_linea.
  ```

- **Monto inválido** (`invalid_decimal`): El monto debe ser un número decimal válido
  ```
  {:error, nro_linea}
  Error: monto inválido en la línea nro_linea.
  ```

- **Monto negativo** (`negative_decimal`): Los montos no pueden ser negativos
  ```
  {:error, nro_linea}
  Error: monto negativo en la línea nro_linea.
  ```

- **Tipo de transacción inválido** (`invalid_type`): Solo se permiten `transferencia`, `swap`, `alta_cuenta`
  ```
  {:error, nro_linea}
  Error: tipo de transacción inválido en la línea nro_linea.
  ```

- **Moneda inválida** (`invalid_coin`): La moneda no existe en monedas.csv
  ```
  {:error, nro_linea}
  Error: moneda inválida en la línea nro_linea.
  ```

- **Cuenta no creada antes de transferencia** (`account_not_created_before_transfer`): Las cuentas deben ser creadas con `alta_cuenta` antes de usarse en transferencias
  ```
  {:error, nro_linea}
  Error: se intentó transferir desde/hacia una cuenta no creada (línea nro_linea).
  ```

- **Cuenta no creada antes de swap** (`account_not_created_before_swap`): Las cuentas deben ser creadas antes de realizar swaps
  ```
  {:error, nro_linea}
  Error: se intentó hacer un swap desde una cuenta no creada (línea nro_linea).
  ```

### Errores de Sistema (sin número de línea)

- **Balance negativo**: Una cuenta no puede tener balance negativo
  ```
  Error: la cuenta userA tiene balance negativo en BTC.
  ```

- **Archivo no encontrado**: El archivo especificado no existe
  ```
  Error: Archivo no encontrado: transacciones.csv
  ```

- **Valor de moneda inválido**: Error al parsear el valor de una moneda en monedas.csv
  ```
  Error: Valor de moneda inválido para BTC.
  ```

- **Moneda inválida**: Moneda especificada en flag -m no existe
  ```
  Error: Moneda inválida.
  ```

### Errores de Comandos

- **Cuenta origen faltante**: Para el subcomando `balance` es obligatorio especificar `-c1`
  ```
  Error: Debe especificar una cuenta de origen con -c1.
  ```

- **Subcomando inválido**: Se debe especificar `transacciones` o `balance`
  ```
  Error: Debe especificar un subcomando: transacciones o balance
  ```

- **Flag desconocida**: Flag no reconocido
  ```
  Error: Flag desconocida: -x=valor
  ```

## Tests

### Ejecutar Tests
```bash
mix test
```

### Coverage de Tests
```bash
mix coveralls
```

El proyecto mantiene un coverage de al menos 90% como requerido.

### Coverage en HTML
```bash
mix coveralls.html
```
Los reportes se generan en `cover/excoveralls.html`

## Consideraciones Técnicas

- **Formato de archivos**: Solo se acepta formato CSV con separador punto y coma (`;`)
- **Inmutabilidad**: Las transacciones son inmutables una vez registradas
- **Precisión decimal**: Se utiliza la librería `Decimal` para cálculos precisos con monedas
- **Ordenamiento**: Las transacciones se procesan en orden cronológico para validar la creación de cuentas
