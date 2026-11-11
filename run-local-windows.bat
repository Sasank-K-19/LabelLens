@echo off
setlocal
if not exist ".venv\Scripts\activate.bat" (
  echo Python virtual environment not found. Follow README.md setup steps first.
  pause
  exit /b 1
)
if not exist "node_modules" (
  echo Node dependencies not found. Run npm install in this folder first.
  pause
  exit /b 1
)
start "LabelLens Python API" cmd /k "call .venv\Scripts\activate.bat && python -m uvicorn backend.main:app --host 127.0.0.1 --port 8000 --reload"
start "LabelLens React UI" cmd /k "npm run dev"
echo Started the backend and frontend in separate terminals.
echo Open the Vite URL shown in the frontend terminal.
endlocal
