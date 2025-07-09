@echo off
setlocal EnableDelayedExpansion

:: === 1. Сканируем COM-порты ========================================
:scan_com
echo.
echo Доступные COM-порты:

set "pidx=0"
for /f "delims=" %%P in ('powershell -NoProfile -Command ^
    "Get-WmiObject Win32_PnPEntity | Where-Object { $_.Name -match '\(COM\d+\)' } | ForEach-Object { $_.Name }"' ) do (
    set /a pidx+=1
    set "PORTNAME!pidx!=%%P"
    echo   !pidx!. %%P
)
if %pidx%==0 (
    echo [ОШИБКА] COM-порты не найдены.
)
echo.

:: === 2. Сканируем прошивки =========================================
:scan_firmware
set "FIRMWARE_DIR=%~dp0firmware"
echo Доступные прошивки:

set "fw_index=0"
for /f "delims=" %%F in ('dir /b /a:-d "%FIRMWARE_DIR%\*.bin" 2^>nul') do (
    set /a fw_index+=1
    set "FIRMWARE_FILE!fw_index!=%%F"
    if !fw_index! LSS 10 (
        echo   !fw_index!. %%F
    ) else (
        echo  !fw_index!. %%F
    )
)
if !fw_index!==0 (
    echo [ОШИБКА] В папке firmware нет файлов *.bin
    goto the_end
)
echo.

:: === 3. Запрос режима прошивки =====================================
echo Какой способ прошивки использовать?
echo   1. Через ST-LINK CLI (SWD/JTAG)
echo   2. Через UART (TeraTerm + YMODEM)
echo.
:ask_mode
set /p FLASH_MODE=Введите номер режима (1-2): 

if not "%FLASH_MODE%"=="1" if not "%FLASH_MODE%"=="2" (
    echo Неверный выбор. Попробуйте ещё раз.
    echo.
    goto ask_mode
)

if "%FLASH_MODE%"=="1" (
    echo Выбран режим ST-LINK CLI (SWD/JTAG)
) 
if "%FLASH_MODE%"=="2" (
    echo Выбран режим UART (TeraTerm + YMODEM)
)

echo.

:: === 4. Запрос выбора прошивки =====================================
:ask_firmware
set /p CHOICE=Введите номер прошивки (1-!fw_index!): 
if not defined FIRMWARE_FILE%CHOICE% (
    echo Неверный выбор. Попробуйте ещё раз.
    echo.
    goto ask_firmware
)
set "SELECTED_FILE=!FIRMWARE_FILE%CHOICE%!"
for %%I in ("%FIRMWARE_DIR%\!SELECTED_FILE!") do set "FULL_PATH=%%~fI"
echo Выбрана прошивка: "!SELECTED_FILE!"
echo.

:: === 5. Выполнить прошивку ==========================================
if "%FLASH_MODE%"=="1" goto do_stlink
if "%FLASH_MODE%"=="2" goto do_uart

:: === STLINK: прошивка ==============================================
:do_stlink
set "STLINK_CLI=%~dp0stlink\ST-LINK_CLI.exe"
if not exist "%STLINK_CLI%" (
    echo [ОШИБКА] ST-LINK CLI не найден по пути: "%STLINK_CLI%"
    goto the_end
)
echo.
echo [ST-LINK] Начинаем загрузку...
"%STLINK_CLI%" -c SWD -OB RDP=0
"%STLINK_CLI%" -c SWD -P "!FULL_PATH!" 0x08000000 -V -Rst
"%STLINK_CLI%" -c SWD -OB RDP=1
echo.
echo [ГОТОВО] ST-LINK прошивка завершена.
goto the_end

:: === UART: прошивка через Tera Term ================================
:do_uart
set /p PCHOICE=Введите номер порта из списка (1-!pidx!): 
if not defined PORTNAME%PCHOICE% (
	echo Неверный выбор. Попробуйте ещё раз.
    echo.
	goto do_uart
)
set "PORTLINE=!PORTNAME%PCHOICE%!"
for /f "tokens=2 delims=(" %%A in ("!PORTLINE!") do (
	for /f "tokens=1 delims=)" %%B in ("%%A") do (
		set "PORTNUM=%%B"
		set "PORTNUM=!PORTNUM:~3!"
	)
)
echo Выбран порт: "!PORTNAME%PCHOICE%!"
echo.
echo [UART] Генерация TTL-скрипта...
> flash_script.ttl (
    echo connect '/C=!PORTNUM! /BAUD=115200 /FC=NONE'
    echo sendln ':DEVICE_RESET'
    echo wait 'Press'
    echo sendln '1'
    echo wait 'Waiting'
    echo pause 1
    echo ymodemsend '!FULL_PATH!'
    echo closett
    echo end
)
set "TERATERM=%~dp0teraterm\ttpmacro.exe"
%TERATERM% flash_script.ttl
del flash_script.ttl
echo.
echo [ГОТОВО] UART-прошивка завершена.
goto the_end

:: === Защита от автозакрытия ==================================
:the_end
echo.
echo Нажмите любую клавишу для выхода...
pause > nul
