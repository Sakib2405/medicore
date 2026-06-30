param(
    [int]$Port = 8080
)

Write-Host "Starting Flutter web on port $Port..."
flutter run -d chrome --web-port=$Port
