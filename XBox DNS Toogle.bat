@echo off
REM ========================================
REM Включение Xbox DNS/DHCP, просмотр адаптеров и DNS
REM ========================================
chcp 65001 >nul
title XBox DNS Toogle v1.0
color 0A

:menu
cls
echo.
echo +======================================+
echo ^|         XBox DNS Toogle v1.0         ^|
echo +======================================+
echo.
echo [1] Включить XBox DNS (автоматически)
echo [2] Отключить (включение DHCP, отключение XBox DNS) 
echo [3] Показать адаптеры
echo [4] Проверить DNS (+ DOH)
echo [5] Выход
echo.
set /p choice="Выбор (1-5): "

if "%choice%"=="1" goto SetDNS
if "%choice%"=="2" goto RestoreDNS
if "%choice%"=="3" goto ListAdapters
if "%choice%"=="4" goto CheckDNS
if "%choice%"=="5" goto exit

echo [!] Неверный выбор!
pause >nul
goto menu

:ListAdapters
cls
echo [ИНФО] АКТИВНЫЕ АДАПТЕРЫ:
echo ===============================  
netsh interface show interface
echo.
echo [ИНФО] Ищите "Connected"!
pause >nul
goto menu

:SetDNS
cls
echo [УСТ] ВКЛЮЧАЕМ XBOX DNS...
echo.

REM ★ ПРАВИЛЬНЫЙ netsh для DNS ★
for /f "tokens=4*" %%a in ('netsh interface show interface ^| findstr "Connected"') do (
    echo [УСТ] %%a %%b
    netsh interface ipv4 set dnsserver "%%a %%b" static 176.99.11.77 primary >nul 2>&1
    netsh interface ipv4 add dnsserver "%%a %%b" 80.78.247.254 index=2 >nul 2>&1
)

ipconfig /flushdns >nul

REM DoH глобально
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v EnableAutoDoh /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\DnsConfig" /v DohTemplate /t REG_SZ /d "https://xbox-dns.ru/dns-query" /f >nul 2>&1

net stop dnscache >nul 2>&1
net start dnscache >nul 2>&1

echo.
echo [ OK ] XBOX DNS ВКЛЮЧЕН!
goto pause

:RestoreDNS
cls
echo [СБР] ПОЛНЫЙ DHCP
echo.

REM ★ команды DHCP ★
for /f "tokens=4*" %%a in ('netsh interface show interface ^| findstr "Connected"') do (
    echo [СБР] %%a %%b
    netsh interface ipv4 set dnsserver "%%a %%b" source=dhcp >nul 2>&1
    netsh interface ip set address "%%a %%b" dhcp >nul 2>&1
)

ipconfig /release >nul 2>&1
ipconfig /renew >nul 2>&1
ipconfig /flushdns >nul

REM Удаляем DoH
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v EnableAutoDoh /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\DnsConfig" /f >nul 2>&1
net stop dnscache >nul 2>&1
net start dnscache >nul 2>&1

echo [ OK ] ВСЕ на DHCP от роутера!
goto pause

:CheckDNS
cls
echo [ПРВ] ПОЛНЫЙ СПИСОК DNS + DoH:
echo ===============================  
echo.
echo === АКТИВНЫЕ АДАПТЕРЫ ===
netsh interface show interface | findstr "Connected"
echo.
echo === ТЕКУЩИЕ DNS ===
ipconfig /all | findstr /C:"DNS Servers" /C:"Адаптер"
echo.
echo === NSLOOKUP ===
nslookup google.com | findstr "Server"
echo.
echo === DoH ПРОВЕРКА ===
reg query "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v EnableAutoDoh 2>nul | findstr "0x2"
if %errorlevel%==0 (echo    [ OK ] DoH ВКЛЮЧЕН!) else (echo    [OFF] DoH ОТКЛЮЧЕН)
reg query "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\DnsConfig" /v DohTemplate 2>nul | findstr "xbox"
if %errorlevel%==0 (echo    [ OK ] DoH URL: xbox-dns.ru) else (echo    [OFF] DoH URL нет)
echo.
echo [ИНФО] 176.99.11.77 + DoH OK = Xbox DNS работает!
pause >nul
goto menu


:pause
echo.
echo [ИНФО] Нажмите клавишу...
pause >nul
goto menu

:exit
exit
