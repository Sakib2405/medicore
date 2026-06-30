@echo off
SETLOCAL
IF "%1"=="" (
  set PORT=8080
) ELSE (
  set PORT=%1
)
echo Starting Flutter web on port %PORT%...
flutter run -d chrome --web-port=%PORT%
