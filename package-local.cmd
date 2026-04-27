@echo off
setlocal

cd /d "%~dp0"

echo [1/2] Stopping backend on 9090 if it is running...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { $conns = Get-NetTCPConnection -LocalPort 9090 -State Listen -ErrorAction SilentlyContinue; foreach ($c in $conns) { Stop-Process -Id $c.OwningProcess -Force } } catch { Write-Warning ('Could not inspect/stop port 9090: ' + $_.Exception.Message) }"

echo [2/2] Packaging backend modules...
call mvnw.cmd -DskipTests -Dspotless.apply.skip=true package
if errorlevel 1 exit /b 1

echo.
echo Package complete.
echo Run start-local.cmd to start the local stack.

endlocal
