param(
    [string]$baseUrl,
    [string]$inputFilePath,
    [string]$outputPath,
    [string]$userKey,
    [string]$apiKey
)

function Fetch-AndSave-MetadataAndContent {
    param(
        [string]$noteId,
        [string]$baseUrl,
        [string]$outputPath,
        [string]$userKey,
        [string]$apiKey
    )

    $headers = @{
        "x-user-key" = $userKey
        "x-api-key"  = $apiKey
    }

    $metadataUrl = "$baseUrl/notes/$noteId"
    $metadataResponse = Invoke-RestMethod -Uri $metadataUrl -Method Get -Headers $headers

    # Ensure the output directory exists
    $noteOutputPath = Join-Path -Path $outputPath -ChildPath $noteId
    if (-not (Test-Path -Path $noteOutputPath)) {
        New-Item -Path $noteOutputPath -ItemType Directory | Out-Null
    }
    # Adjusted to save metadata in /output/noteId/metadata.json
    $metadataPath = Join-Path -Path $noteOutputPath -ChildPath "metadata.json"

    # Save metadata
    $metadataResponse | ConvertTo-Json | Out-File -FilePath $metadataPath

    # List to hold root noteId and attachment noteIds
    $noteIdsToFetchContent = @($noteId)
    $noteIdsToFetchContent += $metadataResponse.attachments.attachment_note_id

    foreach ($id in $noteIdsToFetchContent) {
        $contentUrl = "$baseUrl/notes/$id/content"
        $contentResponse = Invoke-RestMethod -Uri $contentUrl -Method Get -Headers $headers -OutFile "$noteOutputPath\$id"
    }
}

# Read noteIds from the input file
$noteIds = Get-Content -Path $inputFilePath
$totalNoteIds = $noteIds.Count
$currentNoteIdIndex = 0

foreach ($noteId in $noteIds) {
    $currentNoteIdIndex++
    try {
        # Display progress
        Write-Progress -Activity "Processing noteIds" -Status "$currentNoteIdIndex of $totalNoteIds noteIds processed" -PercentComplete (($currentNoteIdIndex / $totalNoteIds) * 100)

        Fetch-AndSave-MetadataAndContent -noteId $noteId -baseUrl $baseUrl -outputPath $outputPath
    }
    catch {
        # Log the exception and noteId in error.log
        "$noteId : $_" | Out-File -FilePath "error.log" -Append
        # Set the flag to true as an error occurred
        $errorsOccurred = $true
    }
}

# Notify the user if any errors occurred
if ($errorsOccurred) {
    Write-Host "Errors occurred during the process. Please check the error.log file for details."
}

Write-Host "Process completed."