#  UART_YModem_Updater

# (ENGLISH):

A small utility for flashing STM32 microcontrollers using either **UART** (YMODEM + TeraTerm) or **ST-LINK CLI**.

Based on: [STM32_F4_YModem_UART_bootloader](https://github.com/SeegmaEpsilon/STM32_F4_YModem_UART_bootloader).

## Project Structure
UART_YModem_Updater/
├── firmware/ # Firmware folder
├── stlink/ # ST-LINK CLI tool
├── teraterm/ # TeraTerm + ttpmacro.exe
├── firmware_combine.bat # Main flashing script
├── README.md # This file

## Requirements

- Windows 7/10/11
- PowerShell 2.0 and above
- [TeraTerm](https://github.com/TeraTermProject/teraterm) (included)
- [ST-LINK CLI](https://www.st.com/en/development-tools/stsw-link004.html) (included)
- USB drivers for your serial adapter and ST-LINK

## How to use

1. Run `firmware_combine.bat`
2. The script will:
   - show available COM ports;
   - list all `.bin` files in the `firmware/` folder.
3. Select the flashing method:
   - `1` — via ST-LINK CLI (JTAG/SWD)
   - `2` — via UART and TeraTerm (YMODEM)
4. Select firmware
5. If using UART — select COM port
6. Done! 

## How it works

The `.bat` script:
- auto-detects available COM ports via PowerShell
- auto-lists available firmware files from `firmware/`
- generates TeraTerm `.ttl` macro script for YMODEM UART flashing
- or runs `ST-LINK_CLI` to write the firmware
- prevents auto-close to display results

## Example
```
Available COM ports:
    1. USB-SERIAL CH340 (COM4)

Available firmwares:
    1. STM32_MAIN_v1.0.0.bin
    2. BOOTLOADER_v2.1.4.bin

Select flashing method:
    1. ST-LINK CLI (JTAG/SWD)
    2. UART + TeraTerm (YMODEM)

Enter flashing mode (1-2): 2
Enter firmware number (1-2): 1
Enter COM port number (1): 1

[UART] Generating TTL macro...
[SUCCESS] Flashing done.
```

## Credits

- Thanks to TeraTerm for macro automation support
- Thanks to STMicroelectronics for ST-LINK CLI tool

## License

This project is distributed under the MIT License.

# (RUSSIAN):

Небольшая утилита для прошивки микроконтроллеров STM32 с использованием либо **UART** (YMODEM + TeraTerm), либо **ST-LINK CLI**.

Основано на: [STM32_F4_YModem_UART_bootloader](https://github.com/SeegmaEpsilon/STM32_F4_YModem_UART_bootloader).

## Структура проекта
UART_YModem_Updater/
├── firmware/ # Папка прошивки
├── stlink/ # ST-LINK CLI tool
├── teraterm/ # TeraTerm + ttpmacro.exe
├── firmware_combine.bat # Основной скрипт прошивки
├── README.md # Этот файл

## Требования

- Windows 7/10/11
- PowerShell 2.0 и выше
- [TeraTerm](https://github.com/TeraTermProject/teraterm) (включено)
- [ST-LINK CLI](https://www.st.com/en/development-tools/stsw-link004.html) (включено)
- USB-драйверы для вашего преобразователя UART и ST-LINK 

## Как использовать

1. Запустите `firmware_combine.bat`
2. Скрипт:
    - покажет доступные COM-порты;
    - выведет список всех файлов `.bin` в папке `firmware/`.
3. Выберите метод прошивки:
    - `1` — через ST-LINK CLI (JTAG/SWD)
    - `2` — через UART и TeraTerm (YMODEM)
4. Выберите прошивку
5. Если используется UART — выберите COM-порт
6. Готово!

## Как это работает

Скрипт `.bat`:
- автоматически определяет доступные COM-порты через PowerShell
- автоматически выводит список доступных файлов прошивки из `firmware/`
- генерирует макрос-скрипт TeraTerm `.ttl` для прошивки YMODEM UART
- или запускает `ST-LINK_CLI` для записи прошивки
- предотвращает автоматическое закрытие для отображения результатов

## Пример
```
Доступные COM-порты:
    1. USB-SERIAL CH340 (COM4)

Доступные прошивки:
    1. STM32_MAIN_v1.0.0.bin
    2. BOOTLOADER_v2.1.4.bin

Выберите метод прошивки:
    1. ST-LINK CLI (JTAG/SWD)
    2. UART + TeraTerm (YMODEM)

Введите режим прошивки (1-2): 2
Введите номер прошивки (1-2): 1
Введите номер COM-порта (1): 1

[UART] Генерация макроса TTL...
[УСПЕХ] Прошивка выполнена.
```

## Благодарности

- Спасибо TeraTerm за поддержку автоматизации макросов
- Спасибо STMicroelectronics за инструмент ST-LINK CLI

## Лицензия

Этот проект распространяется по лицензии MIT.

