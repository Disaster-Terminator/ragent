@echo off
setlocal

cd /d "%~dp0"

echo [1/5] Stopping frontend dev servers on 5173/5174...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "foreach ($port in 5173,5174) { try { $conns = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue; foreach ($c in $conns) { $p = Get-CimInstance Win32_Process -Filter ('ProcessId=' + $c.OwningProcess) -ErrorAction SilentlyContinue; if ($p -and $p.CommandLine -match 'ragent|vite|npm run dev') { Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue; Write-Host ('Stopped PID ' + $c.OwningProcess + ' on port ' + $port) } } } catch { Write-Warning ('Could not inspect port ' + $port + ': ' + $_.Exception.Message) } }"

echo [2/5] Stopping backend on 9090 and MCP server on 9099...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "foreach ($port in 9090,9099) { try { $conns = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue; foreach ($c in $conns) { $p = Get-CimInstance Win32_Process -Filter ('ProcessId=' + $c.OwningProcess) -ErrorAction SilentlyContinue; if ($p -and $p.CommandLine -match 'ragent|bootstrap-0.0.1-SNAPSHOT.jar|mcp-server-0.0.1-SNAPSHOT.jar') { Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue; Write-Host ('Stopped PID ' + $c.OwningProcess + ' on port ' + $port) } } } catch { Write-Warning ('Could not inspect port ' + $port + ': ' + $_.Exception.Message) } }"

echo [3/5] Unloading LM Studio models...
if exist "%USERPROFILE%\.lmstudio\bin\lms.exe" (
  "%USERPROFILE%\.lmstudio\bin\lms.exe" unload --all >nul 2>nul
) else (
  echo LM Studio CLI not found, skipped.
)

echo [4/5] Stopping Docker middleware...
docker-compose -f resources\docker\local-ragent-infra.compose.yaml down
if errorlevel 1 exit /b 1

echo [5/5] Done.
echo Ragent local stack has been stopped.

endlocal
