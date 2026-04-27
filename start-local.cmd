@echo off
setlocal

cd /d "%~dp0"

if not exist ".env" (
  echo [ERROR] Missing .env in %CD%.
  echo Create .env with LMSTUDIO_BASE_URL, LMSTUDIO_EMBEDDING_MODEL, and OPENROUTER_API_KEY.
  exit /b 1
)

echo [1/5] Starting Docker middleware...
docker-compose -f resources\docker\local-ragent-infra.compose.yaml up -d
if errorlevel 1 exit /b 1

echo [2/5] Starting LM Studio local server and loading embedding model...
"%USERPROFILE%\.lmstudio\bin\lms.exe" server start >nul 2>nul
"%USERPROFILE%\.lmstudio\bin\lms.exe" ps | findstr /c:"text-embedding-qwen3-embedding-0.6b@f16" >nul
if errorlevel 1 (
  "%USERPROFILE%\.lmstudio\bin\lms.exe" load text-embedding-qwen3-embedding-0.6b@f16
  if errorlevel 1 (
    "%USERPROFILE%\.lmstudio\bin\lms.exe" ps | findstr /c:"text-embedding-qwen3-embedding-0.6b@f16" >nul
    if errorlevel 1 exit /b 1
  )
) else (
  echo LM Studio embedding model is already loaded.
)

echo [3/5] Starting MCP server on 9099...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$existing = Get-NetTCPConnection -LocalPort 9099 -State Listen -ErrorAction SilentlyContinue; if (-not $existing) { Start-Process -FilePath 'java' -ArgumentList @('-jar', (Join-Path $PWD 'mcp-server\target\mcp-server-0.0.1-SNAPSHOT.jar')) -WorkingDirectory $PWD -WindowStyle Hidden -RedirectStandardOutput (Join-Path $PWD 'mcp-server.dev.log') -RedirectStandardError (Join-Path $PWD 'mcp-server.dev.err.log') }"
if errorlevel 1 exit /b 1

echo [4/5] Starting backend on 9090...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$existing = Get-NetTCPConnection -LocalPort 9090 -State Listen -ErrorAction SilentlyContinue; if (-not $existing) { Start-Process -FilePath 'java' -ArgumentList @('-jar', (Join-Path $PWD 'bootstrap\target\bootstrap-0.0.1-SNAPSHOT.jar')) -WorkingDirectory $PWD -WindowStyle Hidden -RedirectStandardOutput (Join-Path $PWD 'bootstrap.dev.log') -RedirectStandardError (Join-Path $PWD 'bootstrap.dev.err.log') }"
if errorlevel 1 exit /b 1

echo [5/5] Starting frontend on 5173...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$existing = Get-NetTCPConnection -LocalPort 5173 -State Listen -ErrorAction SilentlyContinue; if (-not $existing) { Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c', 'cd /d ""%CD%\frontend"" && npm run dev -- --host 127.0.0.1 --port 5173 ^> vite-dev.log 2^> vite-dev.err.log') -WindowStyle Hidden }"
if errorlevel 1 exit /b 1

echo.
echo Ragent local stack is starting.
echo Frontend: http://127.0.0.1:5173/
echo Backend:  http://127.0.0.1:9090/api/ragent/
echo RocketMQ: http://127.0.0.1:18082/
echo RustFS:   http://127.0.0.1:9001/rustfs/console/index.html

endlocal
