# TODO: set variables
$studentName = "student"
$rgName = "daryn-cli-scripting-rg"
$vmName = "daryn-cli-scripting-vm"
$vmSize = "Standard_B2s"
$vmImage = "$(az vm image list --query "[? contains(urn, 'Ubuntu')] | [0].urn" -o tsv)"
$vmAdminUsername = "student"
$vmAdminPassword = "LaunchCode-@zure1"
$kvName = "daryn-lc0821-ps-kv"
$kvSecretName = "ConnectionStrings--Default"
$kvSecretValue = "server=localhost;port=3306;database=coding_events;user=coding_events;password=launchcode"

# TODO: provision RG
az group create -n $rgName
az configure --default group=$rgName


# TODO: provision VM
az vm create -n "$vmName" --size "$vmSize" --image "$vmImage" --admin-username "$vmAdminUsername" --admin-password "$vmAdminPassword" --authentication-type password --assign-identity | set-content VM.json

# TODO: capture the VM systemAssignedIdentity
$Vm=get-content VM.json | ConvertFrom-Json

# TODO: open vm port 443
az vm open-port --port 443
az configure --default vm="$vmName"

# provision KV
az keyvault create -n "$kvName" --enable-soft-delete false --enabled-for-deployment true

# TODO: create KV secret (database connection string)
az keyvault secret set --vault-name "$kvName" --description 'connection string' --name "$kvSecretName" --value "$kvSecretValue"

# TODO: set KV access-policy (using the vm ``systemAssignedIdentity``)
az keyvault set-policy --name "$kvName" --object-id "$Vm.identity.systemAssignedIdentity" --secret-permissions list get


az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/1configure-vm.sh

az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/2configure-ssl.sh

az vm run-command invoke --command-id RunShellScript --scripts @deliver-deploy.sh

# TODO: print VM public IP address to STDOUT or save it as a file
write-output "$Vm.publicIpAddress"
