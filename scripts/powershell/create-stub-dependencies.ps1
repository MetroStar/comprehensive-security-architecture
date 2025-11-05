# Create Stub Helm Dependencies Script
# Creates minimal stub charts for missing private dependencies

$ErrorActionPreference = "Stop"

# Colors
$GREEN = "Green"
$YELLOW = "Yellow"
$BLUE = "Cyan"
$CYAN = "Cyan"

$ChartDir = if ($env:TARGET_DIR) { Join-Path $env:TARGET_DIR "chart" } else { Join-Path (Get-Location) "chart" }

Write-Host "============================================"
Write-Host "🔧 Helm Dependency Stubbing Tool" -ForegroundColor $BLUE
Write-Host "============================================"
Write-Host "Chart Directory: $ChartDir"
Write-Host ""

# Create charts directory if it doesn't exist
New-Item -ItemType Directory -Force -Path (Join-Path $ChartDir "charts") | Out-Null

# Create stub advana-library chart
$StubChartDir = Join-Path $ChartDir "charts\advana-library"
New-Item -ItemType Directory -Force -Path (Join-Path $StubChartDir "templates") | Out-Null

Write-Host "📦 Creating stub advana-library chart..." -ForegroundColor $CYAN

# Create minimal Chart.yaml for stub
@"
apiVersion: v2
name: advana-library
description: Stub chart for advana-library dependency
type: library
version: 2.0.4
appVersion: "2.0.4"
"@ | Out-File -FilePath (Join-Path $StubChartDir "Chart.yaml") -Encoding UTF8

# Create minimal values.yaml for stub
@"
# Stub values for advana-library
global: {}
"@ | Out-File -FilePath (Join-Path $StubChartDir "values.yaml") -Encoding UTF8

# Create stub templates that provide the common functions
$HelpersContent = @'
{{/*
Stub implementations of common template functions
*/}}
{{- define "common.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
  namespace: {{ .Release.Namespace }}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 8080
{{- end }}

{{- define "common.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}
  namespace: {{ .Release.Namespace }}
spec:
  selector:
    app: {{ .Release.Name }}
  ports:
  - port: 80
    targetPort: 8080
{{- end }}

{{- define "common.env.secret" -}}
# Stub: Environment secrets would be defined here
{{- end }}

{{- define "common.volume.secret" -}}
# Stub: Volume secrets would be defined here  
{{- end }}

{{- define "common.tls.secret" -}}
# Stub: TLS secrets would be defined here
{{- end }}

{{- define "common.dockerconfigjson.secret" -}}
# Stub: Docker registry secrets would be defined here
{{- end }}
'@

$HelpersContent | Out-File -FilePath (Join-Path $StubChartDir "templates\_helpers.tpl") -Encoding UTF8

Write-Host "✅ Stub advana-library chart created" -ForegroundColor $GREEN

# Test template rendering with stub
Write-Host "🧪 Testing template rendering with stub..." -ForegroundColor $CYAN
Push-Location $ChartDir

if (Get-Command helm -ErrorAction SilentlyContinue) {
    $TestRenderPath = "..\helm-dependency-resolution\stub-test-render.yaml"
    New-Item -ItemType Directory -Force -Path "..\helm-dependency-resolution" | Out-Null
    
    helm template test-stub . 2>&1 | Out-File -FilePath $TestRenderPath
    
    if ($LASTEXITCODE -eq 0) {
        $ResourceCount = (Select-String -Path $TestRenderPath -Pattern "^kind:" -AllMatches).Matches.Count
        Write-Host "✅ Template rendering successful with stub" -ForegroundColor $GREEN
        Write-Host "Generated Kubernetes resources: $ResourceCount"
        
        Write-Host ""
        Write-Host "Rendered resource types:"
        Select-String -Path $TestRenderPath -Pattern "^kind:" | ForEach-Object { $_.Line } | Group-Object | Select-Object Count, Name
    } else {
        Write-Host "⚠️  Template rendering still failed" -ForegroundColor $YELLOW
        Write-Host "Check ..\helm-dependency-resolution\stub-test-render.yaml for errors"
    }
} else {
    Write-Host "Testing with Docker Helm..."
    docker run --rm -v "${PWD}:/apps" -w /apps alpine/helm:latest template test-stub . 2>&1 | Out-File -FilePath "..\helm-dependency-resolution\stub-test-render.yaml"
    
    if ($LASTEXITCODE -eq 0) {
        $ResourceCount = (Select-String -Path "..\helm-dependency-resolution\stub-test-render.yaml" -Pattern "^kind:" -AllMatches).Matches.Count
        Write-Host "✅ Template rendering successful with stub" -ForegroundColor $GREEN
        Write-Host "Generated Kubernetes resources: $ResourceCount"
    }
}

Pop-Location

Write-Host ""
Write-Host "📊 Stub Chart Summary" -ForegroundColor $CYAN
Write-Host "========================"
Write-Host "Stub chart location: $StubChartDir"
Write-Host "This stub provides basic implementations of common template functions"
Write-Host "You can now run Checkov security scans on the rendered templates"
Write-Host ""
Write-Host "🎯 Stub dependencies created successfully!" -ForegroundColor $GREEN
