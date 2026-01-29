# Download RAG vector database icons script
$ErrorActionPreference = "Stop"

$iconsDir = "frontend\public\icons"

# RAG vector database list with Google Favicon API URLs
$vectorDBs = @(
    @{name="milvus"; url="https://www.google.com/s2/favicons?domain=milvus.io&sz=64"},
    @{name="pgvector"; url="https://www.google.com/s2/favicons?domain=github.com/pgvector/pgvector&sz=64"},
    @{name="qdrant"; url="https://www.google.com/s2/favicons?domain=qdrant.tech&sz=64"},
    @{name="myscale"; url="https://www.google.com/s2/favicons?domain=myscale.com&sz=64"}
)

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Downloading RAG Vector Database Icons" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Create icons directory
if (-not (Test-Path $iconsDir)) {
    New-Item -ItemType Directory -Path $iconsDir -Force | Out-Null
    Write-Host "Created icons directory: $iconsDir" -ForegroundColor Green
}

# Download each icon
foreach ($db in $vectorDBs) {
    $name = $db.name
    $url = $db.url
    $outputPath = Join-Path $iconsDir "$name.png"
    
    Write-Host "Downloading $name..." -ForegroundColor Yellow
    Write-Host "  URL: $url" -ForegroundColor Gray
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $outputPath -ErrorAction Stop
        Write-Host "  Success: $name -> $outputPath" -ForegroundColor Green
    } catch {
        Write-Host "  Failed: $name - $_" -ForegroundColor Red
        # Create placeholder if download fails
        $svgPath = Join-Path $iconsDir "$name.svg"
        $firstLetter = $name.Substring(0,1).ToUpper()
        $svgContent = "<svg xmlns=`"http://www.w3.org/2000/svg`" viewBox=`"0 0 100 100`"><rect width=`"100`" height=`"100`" fill=`"#667eea`" rx=`"10`"/><text x=`"50`" y=`"70`" font-family=`"Arial, sans-serif`" font-size=`"30`" font-weight=`"bold`" fill=`"#FFFFFF`" text-anchor=`"middle`">$firstLetter</text></svg>"
        Set-Content -Path $svgPath -Value $svgContent -Encoding UTF8
        Write-Host "  Created placeholder: $svgPath" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Icon download completed!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Icons saved to: $iconsDir" -ForegroundColor Cyan
Write-Host ""

