@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

:: === 0. Сканируем доступные COM-порты ===============================
echo Доступные COM-порты:

set "pidx=0"
for /f "delims=" %%P in ('powershell -NoProfile -Command ^
    "Get-WmiObject Win32_PnPEntity | Where-Object { $_.Name -match '\(COM\d+\)' } | ForEach-Object { $_.Name }"' ) do (
    set /a pidx+=1
    set "PORTNAME!pidx!=%%P"
    echo    !pidx!. %%P
)
if %pidx%==0 (
    echo [ОШИБКА] COM-порты не найдены.
    pause & exit /b
)
echo.

:: === 1. Сканируем прошивки =========================================
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
    pause & exit /b
)
echo.

:: === 2. Запрос выбора порта и прошивки ===============================
:askPort
set /p PCHOICE=Введите номер порта из списка (1-!pidx!): 
if not defined PORTNAME%PCHOICE% (
    echo Неверный выбор. Попробуйте ещё раз.
    goto askPort
)
set "PORTLINE=!PORTNAME%PCHOICE%!"
for /f "tokens=2 delims=(" %%A in ("!PORTLINE!") do (
    for /f "tokens=1 delims=)" %%B in ("%%A") do (
        set "PORTNUM=%%B"
        set "PORTNUM=!PORTNUM:~3!"
    )
)

:: === 3. Запрос выбора прошивки ===
:askFirmware
set /p CHOICE=Введите номер прошивки (1-!fw_index!): 
if not defined FIRMWARE_FILE%CHOICE% (
    echo Неверный выбор. Попробуйте ещё раз.
    goto askFirmware
)
set "SELECTED_FILE=!FIRMWARE_FILE%CHOICE%!"
for %%I in ("%FIRMWARE_DIR%\!SELECTED_FILE!") do set "FULL_PATH=%%~fI"
echo Выбрана прошивка: "!SELECTED_FILE!"

:: === 3. Генерация TTL-скрипта ===============================
> flash_script.ttl (
    echo connect '/C=!PORTNUM! /BAUD=115200 /FC=NONE'
    echo sendln ':DEVICE_RESET'
    echo wait 'Press'
    echo sendln '1'
    echo wait 'Waiting'
    echo pause 1
    echo ymodemsend '!FWPATH!'
    echo closett
    echo end
)

:: === 4. Запуск загрузки прошивки ===============================
set "TERATERM=%~dp0teraterm\ttpmacro.exe"
%TERATERM% flash_script.ttl
del flash_script.ttl

echo.
echo [YModem] Перепрошивка завершена.
pause
