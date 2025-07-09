@echo off
setlocal EnableDelayedExpansion

:: === 1. ������㥬 COM-����� ========================================
:scan_com
echo.
echo ����㯭� COM-�����:

set "pidx=0"
for /f "delims=" %%P in ('powershell -NoProfile -Command ^
    "Get-WmiObject Win32_PnPEntity | Where-Object { $_.Name -match '\(COM\d+\)' } | ForEach-Object { $_.Name }"' ) do (
    set /a pidx+=1
    set "PORTNAME!pidx!=%%P"
    echo   !pidx!. %%P
)
if %pidx%==0 (
    echo [������] COM-����� �� �������.
)
echo.

:: === 2. ������㥬 ��訢�� =========================================
:scan_firmware
set "FIRMWARE_DIR=%~dp0firmware"
echo ����㯭� ��訢��:

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
    echo [������] � ����� firmware ��� 䠩��� *.bin
    goto the_end
)
echo.

:: === 3. ����� ०��� ��訢�� =====================================
echo ����� ᯮᮡ ��訢�� �ᯮ�짮����?
echo   1. ��१ ST-LINK CLI (SWD/JTAG)
echo   2. ��१ UART (TeraTerm + YMODEM)
echo.
:ask_mode
set /p FLASH_MODE=������ ����� ०��� (1-2): 

if not "%FLASH_MODE%"=="1" if not "%FLASH_MODE%"=="2" (
    echo ������ �롮�. ���஡�� ��� ࠧ.
    echo.
    goto ask_mode
)

if "%FLASH_MODE%"=="1" (
    echo ��࠭ ०�� ST-LINK CLI (SWD/JTAG)
) 
if "%FLASH_MODE%"=="2" (
    echo ��࠭ ०�� UART (TeraTerm + YMODEM)
)

echo.

:: === 4. ����� �롮� ��訢�� =====================================
:ask_firmware
set /p CHOICE=������ ����� ��訢�� (1-!fw_index!): 
if not defined FIRMWARE_FILE%CHOICE% (
    echo ������ �롮�. ���஡�� ��� ࠧ.
    echo.
    goto ask_firmware
)
set "SELECTED_FILE=!FIRMWARE_FILE%CHOICE%!"
for %%I in ("%FIRMWARE_DIR%\!SELECTED_FILE!") do set "FULL_PATH=%%~fI"
echo ��࠭� ��訢��: "!SELECTED_FILE!"
echo.

:: === 5. �믮����� ��訢�� ==========================================
if "%FLASH_MODE%"=="1" goto do_stlink
if "%FLASH_MODE%"=="2" goto do_uart

:: === STLINK: ��訢�� ==============================================
:do_stlink
set "STLINK_CLI=%~dp0stlink\ST-LINK_CLI.exe"
if not exist "%STLINK_CLI%" (
    echo [������] ST-LINK CLI �� ������ �� ���: "%STLINK_CLI%"
    goto the_end
)
echo.
echo [ST-LINK] ��稭��� ����㧪�...
"%STLINK_CLI%" -c SWD -OB RDP=0
"%STLINK_CLI%" -c SWD -P "!FULL_PATH!" 0x08000000 -V -Rst
"%STLINK_CLI%" -c SWD -OB RDP=1
echo.
echo [������] ST-LINK ��訢�� �����襭�.
goto the_end

:: === UART: ��訢�� �१ Tera Term ================================
:do_uart
set /p PCHOICE=������ ����� ���� �� ᯨ᪠ (1-!pidx!): 
if not defined PORTNAME%PCHOICE% (
	echo ������ �롮�. ���஡�� ��� ࠧ.
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
echo ��࠭ ����: "!PORTNAME%PCHOICE%!"
echo.
echo [UART] ������� TTL-�ਯ�...
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
echo [������] UART-��訢�� �����襭�.
goto the_end

:: === ���� �� ��⮧������ ==================================
:the_end
echo.
echo ������ ���� ������� ��� ��室�...
pause > nul
