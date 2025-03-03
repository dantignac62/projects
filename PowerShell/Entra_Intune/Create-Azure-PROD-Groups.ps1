# Connect to Microsoft Graph with required scope
Connect-MgGraph -Scopes 'Group.ReadWrite.All'

# Define the Autopilot groups with their OrderIDs
$autopilotGroups = @(
    @{Name = 'SG-TEST-DEVICE-AUTOPILOT-UD'; OrderID = 'UD' },
    @{Name = 'SG-TEST-DEVICE-AUTOPILOT-SD'; OrderID = 'SD' }
)

# Define static device groups
$staticDeviceGroups = @(
    'SG-TEST-DEVICE-LSA',
    'SG-TEST-DEVICE-PRACTICE',
    'SG-TEST-DEVICE-WFH',
    'SG-TEST-DEVICE-LAB'
)

# Define application groups (static)
$appGroups = @(
    'SG-TEST-APP-INFOSEC-CROWDSTRIKE',
    'SG-TEST-APP-INFOSEC-DARKSTRACE',
    'SG-TEST-APP-INFOSEC-NESSUS',
    'SG-TEST-APP-INFOSEC-TRELLIX',
    'SG-TEST-APP-BT-CISCO-VPN',
    'SG-TEST-APP-BT-CISCO-UMBRELLA',
    'SG-TEST-APP-BT-DUO',
    'SG-TEST-APP-BT-EPC',
    'SG-TEST-APP-CORP-LASERFICHE',
    'SG-TEST-APP-CORP-BISCOM',
    'SG-TEST-APP-CORP-ZOOM',
    'SG-TEST-APP-CORP-CHROME',
    'SG-TEST-APP-CORP-DYMO',
    'SG-TEST-APP-CORP-EASYPRINT',
    'SG-TEST-APP-CORP-EASYPRINT-SERVICE',
    'SG-TEST-APP-CORP-PDF-ARCHITECT'
)

# Define CONFIG and COMPLI groups (dynamic, Windows 11)
$configCompliGroups = @(
    'SG-TEST-CONFIG-L1-AUDIT-POLICY-W11',
    'SG-TEST-CONFIG-L1-ADM-TPL-NETWORK-W11',
    'SG-TEST-CONFIG-L1-ADM-TPL-SYSTEM-W11',
    'SG-TEST-CONFIG-L1-ADM-TPL-WIN-COMP-W11',
    'SG-TEST-COMPLI-DEFAULT-W11'
)

# Create Autopilot dynamic device groups
foreach ($group in $autopilotGroups) {
    $name = $group.Name
    $orderID = $group.OrderID
    $description = "Dynamic device group for Autopilot devices with OrderID $orderID"
    $membershipRule = '(device.devicePhysicalIds -any (_ -eq "[OrderID]:UD"))'
    New-MgGroup -DisplayName $name `
        -Description $description `
        -MailNickname (New-Guid).Guid `
        -MailEnabled:$false `
        -SecurityEnabled:$true `
        -GroupTypes 'DynamicMembership' `
        -MembershipRule $membershipRule `
        -MembershipRuleProcessingState 'On'
    Write-Host "Created dynamic group: $name"
}

# Create static device groups
foreach ($name in $staticDeviceGroups) {
    $description = 'Static device group'
    New-MgGroup -DisplayName $name `
        -Description $description `
        -MailEnabled:$false `
        -MailNickname (New-Guid).Guid `
        -SecurityEnabled:$true
    Write-Host "Created static group: $name"
}

# Create application groups as static
foreach ($name in $appGroups) {
    $description = 'Static group for application assignment'
    New-MgGroup -DisplayName $name `
        -Description $description `
        -MailEnabled:$false `
        -MailNickname (New-Guid).Guid `
        -SecurityEnabled:$true
    Write-Host "Created static group: $name"
}

# Create CONFIG and COMPLI dynamic device groups for Windows 11
$win11Rule = '(device.deviceOSType -eq "Windows") and (device.deviceOSVersion -startsWith "10.0.2")'
foreach ($name in $configCompliGroups) {
    $description = 'Dynamic device group for Windows 11 devices'
    New-MgGroup -DisplayName $name `
        -Description $description `
        -MailEnabled:$false `
        -MailNickname (New-Guid).Guid `
        -SecurityEnabled:$true `
        -GroupTypes 'DynamicMembership' `
        -MembershipRule $win11Rule `
        -MembershipRuleProcessingState 'On'
    Write-Host "Created dynamic group: $name"
}

Write-Host 'All groups have been created successfully.'