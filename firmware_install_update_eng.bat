@echo off
setlocal EnableDelayedExpansion

:: === 1. Scan COM ports ========================================
:scan_com
echo.
echo Available COM ports:

set "pidx=0"
for /f "delims=" %%P in ('powershell -NoProfile -Command ^
    "Get-WmiObject Win32_PnPEntity | Where-Object { $_.Name -match '\(COM\d+\)' } | ForEach-Object { $_.Name }"' ) do (
    set /a pidx+=1
    set "PORTNAME!pidx!=%%P"
    echo   !pidx!. %%P
)
if %pidx%==0 (
    echo [ERROR] No COM ports found.
)
echo.

:: === 2. Scan firmware files ====================================
:scan_firmware
set "FIRMWARE_DIR=%~dp0firmware"
echo Available firmware files:

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
    echo [ERROR] No *.bin files found in the firmware folder
    goto the_end
)
echo.

:: === 3. Select flashing method ================================
echo Which flashing method would you like to use?
echo   1. Via ST-LINK CLI (SWD/JTAG)
echo   2. Via UART (TeraTerm + YMODEM)
echo.
:ask_mode
set /p FLASH_MODE=Enter mode number (1-2): 

if not "%FLASH_MODE%"=="1" if not "%FLASH_MODE%"=="2" (
    echo Invalid choice. Try again.
    echo.
    goto ask_mode
)

if "%FLASH_MODE%"=="1" (
    echo Selected mode: ST-LINK CLI (SWD/JTAG)
)
if "%FLASH_MODE%"=="2" (
    echo Selected mode: UART (TeraTerm + YMODEM)
)

echo.

:: === 4. Select firmware file ==================================
:ask_firmware
set /p CHOICE=Enter firmware number (1-!fw_index!): 
if not defined FIRMWARE_FILE%CHOICE% (
    echo Invalid choice. Try again.
    echo.
    goto ask_firmware
)
set "SELECTED_FILE=!FIRMWARE_FILE%CHOICE%!"
for %%I in ("%FIRMWARE_DIR%\!SELECTED_FILE!") do set "FULL_PATH=%%~fI"
echo Selected firmware: "!SELECTED_FILE!"
echo.

:: === 5. Perform flashing ======================================
if "%FLASH_MODE%"=="1" goto do_stlink
if "%FLASH_MODE%"=="2" goto do_uart

:: === STLINK flashing ==========================================
:do_stlink
set "STLINK_CLI=%~dp0stlink\ST-LINK_CLI.exe"
if not exist "%STLINK_CLI%" (
    echo [ERROR] ST-LINK CLI not found at: "%STLINK_CLI%"
    goto the_end
)
echo.
echo [ST-LINK] Starting flash...
"%STLINK_CLI%" -c SWD -OB RDP=0
"%STLINK_CLI%" -c SWD -P "!FULL_PATH!" 0x08000000 -V -Rst
"%STLINK_CLI%" -c SWD -OB RDP=1
echo.
echo [DONE] ST-LINK flashing completed.
goto the_end

:: === UART flashing via Tera Term ==============================
:do_uart
set /p PCHOICE=Enter port number from list (1-!pidx!): 
if not defined PORTNAME%PCHOICE% (
	echo Invalid choice. Try again.
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
echo Selected port: "!PORTNAME%PCHOICE%!"
echo.
echo [UART] Generating TTL script...
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
echo [DONE] UART flashing completed.
goto the_end

:: === Prevent auto-close =======================================
:the_end
echo.
echo Press any key to exit...
pause > nul
