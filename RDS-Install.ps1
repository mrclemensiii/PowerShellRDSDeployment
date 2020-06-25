Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Module RemoteDesktop -SkipPublisherCheck -Force
Import-Module RemoteDesktop
New-RDSessionDeployment -ConnectionBroker mrcgw01.clemensfamily.org -WebAccessServer mrcgw01.clemensfamily.org -SessionHost @("mrcsh01.clemensfamily.org","mrcsh02.clemensfamily.org")

New-RDSessionCollection –CollectionName PetriRemoteApps –SessionHost @("mrcsh01.clemensfamily.org","mrcsh02.clemensfamily.org") –CollectionDescription ‘Remote Apps’ –ConnectionBroker mrcgw01.clemensfamily.org
Get-RDSessionCollection –ConnectionBroker mrcgw01.clemensfamily.org

New-RDRemoteApp -Alias Wordpad -DisplayName WordPad -FilePath ‘C:\Program Files\Windows NT\Accessories\wordpad.exe’ -ShowInWebAccess 1 -CollectionName PetriRemoteApps -ConnectionBroker mrcgw01.clemensfamily.org
Get-RDRemoteApp -ConnectionBroker mrcgw01.clemensfamily.org -CollectionName PetriRemoteApps

Add-WindowsFeature -Name RDS-Gateway -IncludeManagementTools -ComputerName mrcgw01.clemensfamily.org

Add-RDServer -Server mrcgw01.clemensfamily.org -Role "RDS-GATEWAY" -ConnectionBroker mrcgw01.clemensfamily.org -GatewayExternalFqdn mrcgw01.clemensfamily.org

Invoke-Command -ComputerName $config.RDGatewayServer01 -ArgumentList $config.GatewayAccessGroup, $config.RDBrokerDNSInternalName, $config.RDBrokerDNSInternalZone, $config.RDSHost01, $config.RDSHost02 -ScriptBlock {
        $GatewayAccessGroup = $args[0]
        $RDBrokerDNSInternalName = $args[1]
        $RDBrokerDNSInternalZone = $args[2]
        $RDSHost01 = $args[3]
        $RDSHost02 = $args[4]
        Import-Module RemoteDesktopServices
        Remove-Item -Path "RDS:\GatewayServer\CAP\RDG_CAP_AllUsers" -Force -recurse
        Remove-Item -Path "RDS:\GatewayServer\RAP\RDG_RDConnectionBrokers" -Force -recurse
        Remove-Item -Path "RDS:\GatewayServer\RAP\RDG_AllDomainComputers" -Force -recurse
        Remove-Item  -Path "RDS:\GatewayServer\GatewayManagedComputerGroups\RDG_RDCBComputers" -Force -recurse
        New-Item -Path "RDS:\GatewayServer\GatewayManagedComputerGroups" -Name "RDSFarm1" -Description "RDSFarm1" -Computers "$RDBrokerDNSInternalName.$RDBrokerDNSInternalZone" -ItemType "String"
        New-Item -Path "RDS:\GatewayServer\GatewayManagedComputerGroups\RDSFarm1\Computers" -Name $RDSHost01 -ItemType "String"
        New-Item -Path "RDS:\GatewayServer\GatewayManagedComputerGroups\RDSFarm1\Computers" -Name $RDSHost02 -ItemType "String"

        New-Item -Path "RDS:\GatewayServer\RAP" -Name "RDG_RAP_RDSFarm1" -UserGroups $GatewayAccessGroup -ComputerGroupType 0 -ComputerGroup "RDSFarm1"
        New-Item -Path "RDS:\GatewayServer\CAP" -Name "RDG_CAP_RDSFarm1" -UserGroups $GatewayAccessGroup -AuthMethod 1

    }
    Write-Verbose "Configured CAP & RAP Policies on: $($config.RDGatewayServer01)"  -Verbose

    read-host "Configuring CAP & RAP on $($config.RDGatewayServer01) error? Re-run this part of the script before continue"