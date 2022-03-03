$settings = @{
    "email" = @{
        "emailTo"      = ""
        "emailFrom"    = ""
        "emailSubject" = "Notification: Activities from last week in the git repo {0}/{1}"
        "SMTPServer"   = "smtp.gmail.com"
        "SMTPUser"     = ""
    }
}

function Get-Settings {
    return $settings
}