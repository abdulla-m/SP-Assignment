param(
    [Parameter(Mandatory = $true)]
    [string]$repo_owner,
    [Parameter(Mandatory = $true)]
    [string]$repo_name
)
 
$pageNumber = 1
$today = [System.DateTime]::UtcNow
$continueToNextPage = $true
$data = @{}

# Import utility module
. $PSScriptRoot/../Module/Utility.ps1

# retrieve settings
$settings = Get-Settings

# Invoke web requests to get pull requests
function FetchPullRequests() {
    # Prepare git repo url
    $uri = "https://api.github.com/repos/$repo_owner/$repo_name/pulls?state=all&sort=updated&direction=desc&page=$pageNumber&per_page=100"

    # Fetch pull request for given repo
    $response = Invoke-WebRequest -Uri $uri -Method Get

    return $response
}

# Funciton to send summary email
function  SendSummaryEmail {
    $emailTo = $settings.email.emailTo
    $emailFrom = $settings.email.emailFrom
    $SMTPServer = $settings.email.SMTPServer
    $emailSubject = $settings.email.emailSubject
    $emailSubject = $emailSubject.ToString() -f $repo_owner, $repo_name
    if ($data.Count -gt 0) {
        $emailBody = "Please find activities as below:"
        $isDraft = @{label = "IsDraft"; expression = { if ($_ -eq $true) { "yes" } else { "No" } } }
        $details = $data.Values | Sort-Object -Property LastUpdated -Descending | Select-Object -Property ID, Title, URL, State, $isDraft, LastUpdated  | Format-List |  Out-String
        $emailBody = $emailBody + $details
    }
    else {
        $emailBody = "There is no activity in the git repo $repo_owner/$repo_name. No pull requests found !! "
    }

    $PasswordFile = "$PSScriptRoot/../Vault/secret"
    $username = $settings.email.SMTPUser
    $password = Get-Content $PasswordFile | ConvertTo-SecureString -AsPlainText -Force
    $Credentials = New-Object -TypeName pscredential -ArgumentList $username, $password

    # Send Email
    Send-MailMessage -To $emailTo -From $emailFrom  -Subject $emailSubject -Body $emailBody -Credential $Credentials -SmtpServer $SMTPServer -Port 587 -UseSsl
}

# Execute loop until PR older than 7 days found or last page occurs( last page having less than 100 records)
try {
    while ($true) {

        # Invoke web request to fetch data
        $response = FetchPullRequests

        # Get all pull resquests
        $pulls = $response.Content | ConvertFrom-Json

        if ($response.Content.Length -eq 0) {
            Write-Host "No pull requests found !!"
            break;
        }

        # Loop through all pull requests and consider only if activity happened last week.
        foreach ($pull in $pulls) {
            $updatedAt = [System.DateTime]::Parse($pull.updated_at)
            $ts = New-TimeSpan -Start $updatedAt -End $today

            write-host $pull.html_url $pull.state $pull.updated_at

            if ($ts.Days -le 7) {
                $info = New-Object PSObject -Property @{
                    ID          = $pull.number
                    Title       = $pull.title
                    URL         = $pull.html_url
                    State       = $pull.state 
                    IsDraft     = $pull.draft
                    LastUpdated = $updatedAt
                } 
            
                $data.Add($pull.number, $info)
            }
            else {
                $continueToNextPage = $false
                break;
            }
        }

        if (-not $continueToNextPage -or $pulls.Length -lt 100 ) {
            write-host "Traversed through all PRs in recent week..."
            break;
        }

        $pageNumber = $pageNumber + 1
    }

    # Send Email
    SendSummaryEmail
}
catch {
    Write-Host "Error while retriving pull requests $($_.Exception)"
    Exit
}