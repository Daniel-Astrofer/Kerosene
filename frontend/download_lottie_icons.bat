@echo off
REM Script para baixar animações Lottie usando PowerShell
REM Execute: download_lottie_icons.bat

echo ================================================
echo Download de Animacoes Lottie
echo ================================================
echo.

REM Criar diretório se não existir
if not exist "assets\lottie" mkdir "assets\lottie"

echo Baixando animacoes...
echo.

REM URLs de exemplo - você pode substituir por URLs específicas do LottieFiles.com
powershell -Command "Invoke-WebRequest -Uri 'https://assets10.lottiefiles.com/packages/lf20_khzniaya.json' -OutFile 'assets\lottie\home.json'" 2>nul
if %errorlevel% equ 0 (echo [OK] home.json) else (echo [ERRO] home.json)

powershell -Command "Invoke-WebRequest -Uri 'https://assets2.lottiefiles.com/packages/lf20_tll0j4bb.json' -OutFile 'assets\lottie\credit_card.json'" 2>nul
if %errorlevel% equ 0 (echo [OK] credit_card.json) else (echo [ERRO] credit_card.json)

powershell -Command "Invoke-WebRequest -Uri 'https://assets9.lottiefiles.com/packages/lf20_uu3x2ijq.json' -OutFile 'assets\lottie\qr_scan.json'" 2>nul
if %errorlevel% equ 0 (echo [OK] qr_scan.json) else (echo [ERRO] qr_scan.json)

powershell -Command "Invoke-WebRequest -Uri 'https://assets4.lottiefiles.com/packages/lf20_qp1q7mct.json' -OutFile 'assets\lottie\analytics.json'" 2>nul
if %errorlevel% equ 0 (echo [OK] analytics.json) else (echo [ERRO] analytics.json)

powershell -Command "Invoke-WebRequest -Uri 'https://assets1.lottiefiles.com/packages/lf20_x62chJ.json' -OutFile 'assets\lottie\profile.json'" 2>nul
if %errorlevel% equ 0 (echo [OK] profile.json) else (echo [ERRO] profile.json)

powershell -Command "Invoke-WebRequest -Uri 'https://assets5.lottiefiles.com/packages/lf20_9wpyhdzo.json' -OutFile 'assets\lottie\bitcoin.json'" 2>nul
if %errorlevel% equ 0 (echo [OK] bitcoin.json) else (echo [ERRO] bitcoin.json)

powershell -Command "Invoke-WebRequest -Uri 'https://assets3.lottiefiles.com/packages/lf20_w51pcehl.json' -OutFile 'assets\lottie\trending_up.json'" 2>nul
if %errorlevel% equ 0 (echo [OK] trending_up.json) else (echo [ERRO] trending_up.json)

powershell -Command "Invoke-WebRequest -Uri 'https://assets7.lottiefiles.com/packages/lf20_qp1q7mct.json' -OutFile 'assets\lottie\pie_chart.json'" 2>nul
if %errorlevel% equ 0 (echo [OK] pie_chart.json) else (echo [ERRO] pie_chart.json)

powershell -Command "Invoke-WebRequest -Uri 'https://assets6.lottiefiles.com/packages/lf20_9wpyhdzo.json' -OutFile 'assets\lottie\bar_chart.json'" 2>nul
if %errorlevel% equ 0 (echo [OK] bar_chart.json) else (echo [ERRO] bar_chart.json)

powershell -Command "Invoke-WebRequest -Uri 'https://assets8.lottiefiles.com/packages/lf20_uu3x2ijq.json' -OutFile 'assets\lottie\freeze.json'" 2>nul
if %errorlevel% equ 0 (echo [OK] freeze.json) else (echo [ERRO] freeze.json)

powershell -Command "Invoke-WebRequest -Uri 'https://assets2.lottiefiles.com/packages/lf20_w51pcehl.json' -OutFile 'assets\lottie\lock.json'" 2>nul
if %errorlevel% equ 0 (echo [OK] lock.json) else (echo [ERRO] lock.json)

powershell -Command "Invoke-WebRequest -Uri 'https://assets4.lottiefiles.com/packages/lf20_khzniaya.json' -OutFile 'assets\lottie\speed.json'" 2>nul
if %errorlevel% equ 0 (echo [OK] speed.json) else (echo [ERRO] speed.json)

powershell -Command "Invoke-WebRequest -Uri 'https://assets1.lottiefiles.com/packages/lf20_tll0j4bb.json' -OutFile 'assets\lottie\settings.json'" 2>nul
if %errorlevel% equ 0 (echo [OK] settings.json) else (echo [ERRO] settings.json)

echo.
echo ================================================
echo Download concluido!
echo ================================================
echo.
echo Execute 'flutter pub get' e reinicie o app.
echo.
pause
