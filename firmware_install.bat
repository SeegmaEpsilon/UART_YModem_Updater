@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

:: === 1. Устанавливаем путь к CLI ===
set "STLINK_CLI=%~dp0stlink\ST-LINK_CLI.exe"
if not exist "%STLINK_CLI%" (
    echo [ОШИБКА] ST-LINK CLI не найден по пути: "%STLINK_CLI%"
    pause & exit /b
)

:: === 2. Сканируем прошивки =========================================
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

:: === 4. Прошивка через ST-LINK CLI ===
echo.
echo [ST-LINK] Начинаем загрузку...
:: 4.1. Снять защиту чтения (если нужно)
"%STLINK_CLI%" -c SWD UR -OB RDP=0

:: 4.2. Загрузить прошивку
"%STLINK_CLI%" -c SWD UR -P "!FULL_PATH!" 0x08000000 -V -Rst

:: 4.3. Восстановить защиту (опционально)
"%STLINK_CLI%" -c SWD UR -OB RDP=1

echo.
echo [ГОТОВО] Прошивка завершена.
pause
