# SP-Assignment
Assignment is to get recent pull request from any public repository and send email summary

# How to execute?

1. Invoke powershell script "scripts/Get-PullRequests.ps1"
2. It takes two arguments "repo_owner" and "repo_name", which construct github uri.
   <p/> e.g. https://api.github.com/repos/microsoft/powertoys/pulls
   <p/>Here "microsoft" is "repo_owner" and "powertoys" is "repo_name"
        
3. To Send email notification, add following details in "Modules/utility.ps1"
       ![image](https://user-images.githubusercontent.com/41674608/156515355-3b56b9cd-d70a-492f-8f42-315a2362bd47.png)
       
4. Add password in "vault/secret". Simply replace placeholder text with smtp password.

5. Sample run commands,
   <code>
       <p/>cd Scripts
       <p/>./Get-PullRequests.ps1 -repo_owner "microsoft" -repo_name "powertoys"
    <code/>
