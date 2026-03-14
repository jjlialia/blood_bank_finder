@echo off
echo Starting FastAPI Backend...
start cmd /k "cd backend && venv\Scripts\activate && python main.py"

echo Starting Flutter App in Chrome...
start cmd /k "flutter run -d chrome"

echo Both services are starting up!
