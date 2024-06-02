<#
    Title: Windows Unattend Generator v1.0
    Copyright© 2024 Magdy Aloxory. All rights reserved.
    Contact: maloxory@gmail.com
#>

# Check if the script is running with administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Relaunch the script with administrator privileges
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# Function to create a local account XML snippet
function CreateLocalAccount {
    param (
        [string]$username,
        [string]$password,
        [bool]$isAdmin
    )

    $group = if ($isAdmin) { "Administrators" } else { "Users" }

    return @"
                    <LocalAccount wcm:action="add">
                        <Password>
                            <Value>$password</Value>
                            <PlainText>true</PlainText>
                        </Password>
                        <Name>$username</Name>
                        <Group>$group</Group>
                    </LocalAccount>
"@
}

# Function to center text
function CenterText {
    param (
        [string]$text,
        [int]$width
    )
    
    $textLength = $text.Length
    $padding = ($width - $textLength) / 2
    return (" " * [math]::Max([math]::Ceiling($padding), 0)) + $text + (" " * [math]::Max([math]::Floor($padding), 0))
}

# Function to create a border
function CreateBorder {
    param (
        [string[]]$lines,
        [int]$width
    )

    $borderLine = "+" + ("-" * $width) + "+"
    $borderedText = @($borderLine)
    foreach ($line in $lines) {
        $borderedText += "|$(CenterText $line $width)|"
    }
    $borderedText += $borderLine
    return $borderedText -join "`n"
}

# Display script information with border
$title = "Windows Unattend Generator v1.0"
$copyright = "Copyright 2024 Magdy Aloxory. All rights reserved."
$contact = "Contact: maloxory@gmail.com"
$maxWidth = 50

$infoText = @($title, $copyright, $contact)
$borderedInfo = CreateBorder -lines $infoText -width $maxWidth

Write-Host $borderedInfo -ForegroundColor Cyan

# Prompt the user for various settings
$inputLocale = Read-Host "Enter Input Language (e.g., en-US;ar-EG)"
$systemLocale = Read-Host "Enter System Language (e.g., en-US)"
$uiLanguage = $systemLocale
$timeZone = Read-Host "Enter TimeZone (e.g., Egypt Standard Time)"

# Create a list to hold user accounts
$userAccounts = @()

# Ask if the user wants to create local accounts
do {
    $createNewAccount = Read-Host "Do you want to create a new local account? (yes/no)"
    if ($createNewAccount -eq "yes") {
        $username = Read-Host "Enter the username for the new local account"
        $password = Read-Host "Enter the password for the new local account"
        $isAdmin = Read-Host "Should this user be added to the Administrators group? (yes/no)"
        $isAdmin = $isAdmin -eq "yes"
        
        # Add the new user account to the list
        $userAccounts += CreateLocalAccount -username $username -password $password -isAdmin $isAdmin
    }
} while ($createNewAccount -eq "yes")

# Construct the XML content
$xmlContent = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>$inputLocale</InputLocale>
            <SystemLocale>$systemLocale</SystemLocale>
            <UILanguage>$uiLanguage</UILanguage>
            <UILanguageFallback>$uiLanguage</UILanguageFallback>
            <UserLocale>$uiLanguage</UserLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Work</NetworkLocation>
                <ProtectYourPC>3</ProtectYourPC>
            </OOBE>
            <UserAccounts>
                <LocalAccounts>
$(($userAccounts -join "`n"))
                </LocalAccounts>
            </UserAccounts>
            <TimeZone>$timeZone</TimeZone>
            <RegisteredOrganization>Windows User</RegisteredOrganization>
        </component>
    </settings>
    <cpi:offlineImage cpi:source="wim:d:/wims/win11.wim#Windows 11 Pro (Default official install) - Sysprepped" xmlns:cpi="urn:schemas-microsoft-com:cpi" />
</unattend>
"@

# Write the XML content to a .txt file in the root directory of drive C:
$outFile = "C:\unattend.txt"
Set-Content -Path $outFile -Value $xmlContent

Write-Host "Unattend.txt file has been generated and saved at $outFile" -ForegroundColor Green

pause
