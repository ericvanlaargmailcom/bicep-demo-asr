# Azure Deployment Leerlijn: Van Portal Naar Herbruikbare Bicep-modules

In deze leerlijn bouw je Azure-infrastructuur vijf keer op een steeds beter automatiseerbare manier. Je begint visueel in de Azure Portal, voert daarna dezelfde soort handelingen uit met Azure CLI, stapt vervolgens over op een declaratieve ARM-template en herschrijft dat concept in Bicep. Tot slot gebruik je de volledige demo uit deze repository om herbruikbare modules, What-If, drift, Deployment Stacks en RBAC als code te onderzoeken.

Je hebt voor de volledige leerlijn alleen deze README, een moderne browser en toegang tot de cursus-subscription nodig. Installeer lokaal geen Visual Studio Code, Git, Bicep, Azure CLI of Azure PowerShell. Vanaf **P2** gebruik je de vooraf geïnstalleerde hulpmiddelen in Azure Cloud Shell.

## De Didactische Opbouw

| Fase | Werkwijze | Wat je leert | Beperking die je ervaart |
|---|---|---|---|
| **P1** | Azure Portal | Resources en afhankelijkheden visueel herkennen. | Handmatige stappen zijn lastig exact te herhalen. |
| **P2** | Azure CLI | Azure imperatief en scriptbaar aansturen. | Je beschrijft losse acties in plaats van één gewenste eindtoestand. |
| **P3** | ARM JSON-template | Infrastructuur declaratief en herhaalbaar vastleggen. | Kale JSON is uitgebreid en lastig leesbaar. |
| **P4** | Bicep-template | Dezelfde ARM-engine met compacte syntax en typecontrole gebruiken. | Eén groot bestand is nog niet automatisch een organisatiebrede standaard. |
| **A–E** | Herbruikbare Bicep-modules | Security-by-default, parameters, drift, ownership, lifecyclebeheer en governance toepassen. | Je ziet waar platformstandaarden en applicatieverantwoordelijkheid elkaar raken. |

Iedere fase lost bewust een probleem van de vorige fase op. Bicep verschijnt daardoor niet als zomaar een nieuwe taal, maar als een logisch vervolg op ervaringen die je eerder in de leerlijn hebt opgedaan.

De letter **P** staat voor *voortraject*. Gebruik bij vragen steeds de volledige stapcode, bijvoorbeeld: “Ik ben bij P3.4”. Vanaf de einddemo gebruik je de bestaande codes A1, B1.3, B5.6 enzovoort. De oefeningen wisselen tussen Windows- en Linux-VM's omdat ze verschillende officiële quickstarts combineren; het leerdoel is het verschil tussen de deploymentmethoden, niet het verschil tussen de besturingssystemen.

> **Let op: deze leerlijn veroorzaakt werkelijke Azure-kosten.** Verwijder de oefen-resourcegroep aan het einde van iedere P-fase. De einddemo bevat betaalde `P1v3` App Service Plans. Virsoft ruimt de cursus-subscription na maximaal zes uur automatisch op, maar wacht daar tijdens het oefenen niet onnodig op.

## P0. Eenmalige Voorbereiding

### P0.1 Meld Je Aan En Activeer MFA

1. Open [portal.azure.com](https://portal.azure.com) in de browser.
2. Meld je aan met het Global Administrator-account van de eigen Virsoft-tenant. Kies **Werk- of schoolaccount** wanneer Microsoft om het accounttype vraagt.
3. Kies **Volgende** wanneer de melding verschijnt dat meer informatie vereist is.
4. Installeer **Microsoft Authenticator** op je smartphone als deze app nog niet is geïnstalleerd.
5. Open Microsoft Authenticator, sta meldingen en cameratoegang toe wanneer daarom wordt gevraagd en kies het plus-teken gevolgd door **Werk- of schoolaccount > QR-code scannen**.
6. Scan met de app de QR-code die in de browser wordt getoond.
7. Keur de testmelding in Microsoft Authenticator goed en rond alle resterende stappen in de browser af.
8. Controleer dat de Azure Portal opent voordat je verdergaat.

Verschijnt de registratiewizard niet automatisch, open dan [Beveiligingsgegevens](https://mysignins.microsoft.com/security-info), kies **Aanmeldingsmethode toevoegen** en selecteer **Microsoft Authenticator**.

### P0.2 Controleer De Cursus-subscription

1. Zoek in de Azure Portal naar **Subscriptions**.
2. Open de cursus-subscription.
3. Controleer bij **Overview** dat de subscription actief is.
4. Controleer rechtsboven dat je met het cursusaccount in de juiste tenant bent aangemeld.

Gebruik in alle volgende fasen uitsluitend deze cursus-subscription.

## P1. Deploy Een Windows-VM Via De Azure Portal

In deze eerste fase werk je volledig visueel. Je ziet welke keuzes nodig zijn om een VM te maken en welke ondersteunende resources Azure daarbij aanmaakt. De oefening is gebaseerd op de [Microsoft-quickstart voor een Windows-VM in de Azure Portal](https://learn.microsoft.com/azure/virtual-machines/windows/quick-create-portal).

### P1.1 Maak De Virtuele Machine

1. Zoek in de Azure Portal naar **Virtual machines**.
2. Kies **Create > Azure virtual machine**.
3. Controleer dat de cursus-subscription is geselecteerd.
4. Kies **Create new** bij **Resource group** en gebruik `rg-leerlijn-portal-we-001`.
5. Gebruik als **Virtual machine name** `vmportal001`. Een Windows-computernaam mag maximaal 15 tekens bevatten.
6. Kies **West Europe** als regio.
7. Kies **Windows Server 2022 Datacenter: Azure Edition - x64 Gen 2** als image.
8. Kies indien beschikbaar `Standard_B2s` als VM-grootte.
9. Gebruik `azureuser` als gebruikersnaam en stel een tijdelijk sterk wachtwoord in. Bewaar dit alleen zolang deze oefening duurt.
10. Kies bij **Public inbound ports** voor **Allow selected ports** en selecteer **RDP (3389)** en **HTTP (80)**.
11. Open het tabblad **Management**, schakel **Auto-shutdown** in en kies een tijdstip later op dezelfde cursusdag.
12. Kies **Review + create**, controleer de samenvatting en wacht op de validatie.
13. Kies **Create** en wacht totdat de deployment is voltooid.
14. Kies **Go to resource**.

> De open poorten en het tijdelijke wachtwoord zijn alleen bedoeld voor deze afgeschermde cursus-oefening. Dit is geen productieontwerp.

### P1.2 Onderzoek Wat De Portal Heeft Aangemaakt

1. Bekijk op **Overview** de status, regio, VM-grootte, private IP en public IP.
2. Open de resourcegroep `rg-leerlijn-portal-we-001`.
3. Controleer dat Azure naast de VM ook een disk, netwerkinterface, public IP, Network Security Group en Virtual Network heeft aangemaakt.
4. Open **Deployments** en bekijk de deployment die door de portal is uitgevoerd.

De portal vroeg vooral om functionele keuzes. Veel resourcenamen, afhankelijkheden en standaardinstellingen werden automatisch voor je ingevuld. Dat is snel en overzichtelijk, maar de exacte reeks muisklikken is niet vanzelf reproduceerbaar.

### P1.3 Test De VM Optioneel Via RDP

Voer deze stap alleen uit wanneer RDP op de lab-pc is toegestaan:

1. Open de VM en kies **Connect > Connect via RDP**.
2. Controleer met **Check access** dat poort 3389 bereikbaar is.
3. Download en open het RDP-bestand.
4. Meld je aan met `azureuser` en het tijdelijke wachtwoord.
5. Accepteer de certificaatwaarschuwing voor deze tijdelijke oefen-VM.
6. Open PowerShell in de VM en installeer IIS:

```powershell
Install-WindowsFeature -Name Web-Server -IncludeManagementTools
```

Sluit daarna de RDP-sessie. Open het public IP-adres van de VM in een browser en controleer of de IIS-welkomstpagina verschijnt.

### P1.4 Verwijder De Portal-resources

1. Open `rg-leerlijn-portal-we-001`.
2. Kies **Delete resource group**.
3. Volg de bevestigingsstappen in de portal.
4. Wacht totdat de resourcegroep niet meer bestaat.

Je verwijdert bewust de volledige resourcegroep. Daarmee verdwijnen ook alle ondersteunende resources die de portal voor de VM heeft aangemaakt.

## P2. Deploy Een Linux-VM Met Azure CLI

Je gaat nu vergelijkbare infrastructuur maken met commando's. De stappen zijn daardoor beter te herhalen en in een script op te nemen. De oefening is gebaseerd op de [Microsoft-quickstart voor een Linux-VM met Azure CLI](https://learn.microsoft.com/azure/virtual-machines/linux/quick-create-cli).

### P2.1 Start Azure Cloud Shell Met Bash

1. Klik rechtsboven in de Azure Portal op het pictogram **Cloud Shell** (`>_`).
2. Kies **Bash** wanneer naar het shelltype wordt gevraagd.
3. Kies bij de eerste start **No storage account required** voor een tijdelijke sessie.
4. Selecteer de cursus-subscription en kies **Apply**.
5. Wacht totdat de Bash-prompt verschijnt.

Cloud Shell is al aangemeld met de portalsessie. Voer daarom geen afzonderlijk `az login`-commando uit.

### P2.2 Controleer De CLI-context

```bash
az version
az account show --output table
```

Ga pas verder wanneer de juiste tenant en cursus-subscription worden getoond.

### P2.3 Stel De Variabelen In

```bash
CLI_RESOURCE_GROUP="rg-leerlijn-cli-we-001"
CLI_VM_NAME="vm-leerlijn-cli-we-001"
CLI_LOCATION="westeurope"
CLI_USERNAME="azureuser"
```

Variabelen maken het commando herbruikbaar zonder iedere waarde op meerdere plaatsen te wijzigen.

### P2.4 Maak De Resourcegroep En VM

```bash
az group create \
  --name "$CLI_RESOURCE_GROUP" \
  --location "$CLI_LOCATION" \
  --output table

az vm create \
  --resource-group "$CLI_RESOURCE_GROUP" \
  --name "$CLI_VM_NAME" \
  --image "Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest" \
  --size Standard_B2s \
  --admin-username "$CLI_USERNAME" \
  --assign-identity \
  --generate-ssh-keys \
  --public-ip-sku Standard \
  --output table
```

`--generate-ssh-keys` gebruikt een bestaande sleutel uit `~/.ssh` of maakt daar een nieuwe sleutel. Het commando maakt niet alleen de VM, maar laat Azure CLI ook de benodigde netwerkresources samenstellen.

### P2.5 Controleer De Deployment

```bash
az vm show \
  --resource-group "$CLI_RESOURCE_GROUP" \
  --name "$CLI_VM_NAME" \
  --show-details \
  --query "{name:name,powerState:powerState,privateIp:privateIps,publicIp:publicIps}" \
  --output table

az resource list \
  --resource-group "$CLI_RESOURCE_GROUP" \
  --query "[].{name:name,type:type}" \
  --output table
```

Vergelijk de resourcelijst met P1. Je hebt opnieuw een VM en ondersteunende resources gekregen, maar deze keer beschreef je handelingen: maak eerst een resourcegroep en voer daarna `az vm create` uit.

Test SSH eventueel rechtstreeks vanuit Cloud Shell:

```bash
CLI_PUBLIC_IP=$(az vm show \
  --resource-group "$CLI_RESOURCE_GROUP" \
  --name "$CLI_VM_NAME" \
  --show-details \
  --query publicIps \
  --output tsv)

ssh -o StrictHostKeyChecking=no "$CLI_USERNAME@$CLI_PUBLIC_IP"
```

Gebruik `exit` om de SSH-sessie weer te verlaten.

### P2.6 Verwijder De CLI-resources

```bash
az group delete \
  --name "$CLI_RESOURCE_GROUP" \
  --yes

az group exists --name "$CLI_RESOURCE_GROUP"
```

De verwachte laatste uitvoer is `false`. Voer het controlecommando na enkele minuten opnieuw uit wanneer de verwijdering nog loopt.

### P2.7 Clone Deze Repository

De volgende fasen gebruiken voorbeeldbestanden uit deze publieke repository:

```bash
cd ~

if [ -d bicep-demo-asr/.git ]; then
  git -C bicep-demo-asr pull --ff-only
else
  git clone https://github.com/ericvanlaargmailcom/bicep-demo-asr.git
fi

cd bicep-demo-asr
```

Voor het klonen is geen GitHub-account nodig. Omdat Cloud Shell tijdelijk is, moet je na een beëindigde sessie de repository opnieuw clonen.

## P3. Deploy Een Windows-VM Met Een Kale ARM-template

Azure CLI maakte in P2 meerdere resources voor je op basis van één hoog-niveaucommando. In deze fase leg je de gewenste resources en afhankelijkheden zelf declaratief vast in JSON. De oefening bouwt voort op de [Microsoft-instructie voor een Windows-VM met een ARM-template](https://learn.microsoft.com/azure/virtual-machines/windows/ps-template).

### P3.1 Schakel Cloud Shell Over Naar PowerShell

1. Gebruik in de Cloud Shell-werkbalk **Switch to PowerShell**.
2. Wacht op de PowerShell-prompt.
3. Ga terug naar de repository:

```powershell
Set-Location ~/bicep-demo-asr
Get-AzContext
```

Controleer dat `Get-AzContext` de cursus-subscription toont.

### P3.2 Bekijk De ARM-template

Open de kale JSON-template:

```powershell
code learning-path/arm-vm/main.json
```

Zoek in het bestand naar:

- `parameters`: waarden die bij een deployment kunnen verschillen;
- `variables`: intern hergebruikte namen;
- `resources`: de NSG, VNet, public IP, NIC en Windows-VM;
- `dependsOn`: expliciete volgorde tussen resources;
- ARM-expressies zoals `[parameters('vmName')]` en `[resourceId(...)]`;
- `outputs`: waarden die na de deployment worden teruggegeven.

De template is herhaalbaar en beschrijft de gewenste eindtoestand, maar de vele accolades, komma's, geneste properties en stringexpressies maken het bestand moeilijker te lezen en onderhouden.

### P3.3 Maak De Resourcegroep En Valideer De Template

```powershell
$ArmResourceGroup = 'rg-leerlijn-arm-we-001'
$ArmLocation = 'westeurope'
$ArmAdminPassword = Read-Host 'Kies een tijdelijk sterk VM-wachtwoord' -AsSecureString

New-AzResourceGroup `
  -Name $ArmResourceGroup `
  -Location $ArmLocation

Test-AzResourceGroupDeployment `
  -ResourceGroupName $ArmResourceGroup `
  -TemplateFile './learning-path/arm-vm/main.json' `
  -adminPassword $ArmAdminPassword
```

`Test-AzResourceGroupDeployment` controleert de template en parameters zonder resources te maken.

### P3.4 Deploy De ARM-template

```powershell
New-AzResourceGroupDeployment `
  -Name 'arm-vm' `
  -ResourceGroupName $ArmResourceGroup `
  -TemplateFile './learning-path/arm-vm/main.json' `
  -adminPassword $ArmAdminPassword `
  -Verbose
```

Wis de wachtwoordvariabele zodra de deployment is gestart:

```powershell
$ArmAdminPassword = $null
```

### P3.5 Controleer De ARM-deployment

```powershell
Get-AzResourceGroupDeployment `
  -ResourceGroupName $ArmResourceGroup `
  -Name 'arm-vm'

Get-AzResource `
  -ResourceGroupName $ArmResourceGroup |
  Select-Object Name, ResourceType
```

Open daarnaast in de Azure Portal de resourcegroep `rg-leerlijn-arm-we-001`, bekijk de resources en controleer onder **Deployments** dat `arm-vm` is geslaagd.

### P3.6 Verwijder De ARM-resources En Keer Terug Naar Bash

```powershell
Remove-AzResourceGroup `
  -Name $ArmResourceGroup `
  -Force
```

1. Wacht totdat de resourcegroep is verwijderd.
2. Gebruik **Switch to Bash** in de Cloud Shell-werkbalk.
3. Ga terug naar de repository:

```bash
cd ~/bicep-demo-asr
```

## P4. Deploy Een Linux-VM Met Bicep

Bicep gebruikt dezelfde Azure Resource Manager-engine als de JSON-template uit P3. Het verschil zit vooral in de schrijfervaring: compacte declaraties, typecontrole, symbolische namen en automatisch afgeleide afhankelijkheden. De oefening is gebaseerd op de [Microsoft-quickstart voor een Linux-VM met Bicep](https://learn.microsoft.com/azure/virtual-machines/linux/quick-create-bicep?tabs=CLI).

### P4.1 Bekijk De Bicep-template

```bash
code learning-path/bicep-vm/main.bicep
```

Vergelijk het bestand met `learning-path/arm-vm/main.json` en let op:

- resources hebben symbolische namen zoals `nsg`, `vnet`, `publicIp`, `nic` en `vm`;
- propertywaarden worden zonder JSON-stringexpressies aan elkaar gekoppeld;
- verwijzingen zoals `nsg.id` en `nic.id` maken afhankelijkheden duidelijk;
- er is meestal geen expliciete `dependsOn` nodig wanneer Bicep de afhankelijkheid uit een verwijzing kan afleiden;
- parameters, variabelen en outputs zijn compacter maar leveren uiteindelijk een ARM-template op.

### P4.2 Controleer De Bicep-hulpmiddelen En SSH-sleutel

```bash
bicep --version

if [ ! -f ~/.ssh/id_rsa.pub ]; then
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
fi

bicep build learning-path/bicep-vm/main.bicep --stdout > /dev/null
printf 'Bicep-template is geldig.\n'
```

De compiler controleert onder andere syntax, typen en beschikbare properties voordat Azure de deployment ontvangt.

### P4.3 Maak De Resourcegroep En Deploy Bicep

```bash
BICEP_RESOURCE_GROUP="rg-leerlijn-bicep-we-001"

az group create \
  --name "$BICEP_RESOURCE_GROUP" \
  --location westeurope \
  --output table

az deployment group create \
  --name bicep-vm \
  --resource-group "$BICEP_RESOURCE_GROUP" \
  --template-file learning-path/bicep-vm/main.bicep \
  --parameters adminPublicKey="$(cat ~/.ssh/id_rsa.pub)" \
  --output json
```

Azure ontvangt hierbij geen Bicep-broncode. De Bicep-compiler zet het bestand eerst om naar een ARM-template en Azure Resource Manager voert die gegenereerde template uit.

### P4.4 Controleer De Bicep-deployment

```bash
az deployment group show \
  --name bicep-vm \
  --resource-group "$BICEP_RESOURCE_GROUP" \
  --query "{state:properties.provisioningState,outputs:properties.outputs}" \
  --output json

az resource list \
  --resource-group "$BICEP_RESOURCE_GROUP" \
  --query "[].{name:name,type:type}" \
  --output table
```

Open ook de resourcegroep in de Azure Portal. De resourcetypen lijken sterk op P2 en P3, maar de gewenste configuratie staat nu leesbaar en reproduceerbaar in één Bicep-bestand.

### P4.5 Verwijder De Bicep-VM

```bash
az group delete \
  --name "$BICEP_RESOURCE_GROUP" \
  --yes

az group exists --name "$BICEP_RESOURCE_GROUP"
```

Wacht totdat de laatste uitvoer `false` is.

### P4.6 Maak De Balans Op

| Onderwerp | Portal | Azure CLI | ARM JSON | Bicep |
|---|---|---|---|---|
| Visueel ontdekken | Sterk | Beperkt | Beperkt | Beperkt |
| Exact herhaalbaar | Moeilijk | Redelijk | Ja | Ja |
| Beschrijft gewenste toestand | Nee | Meestal niet | Ja | Ja |
| Leesbaarheid bij meerdere resources | Niet van toepassing | Verspreide commando's | Laag | Hoog |
| Parameters en outputs | Via formulieren | Via argumenten en queries | Ja | Ja |
| Herbruikbare modules | Nee | Alleen via eigen scripts | Mogelijk, maar uitgebreid | Ja, compact en typeveilig |

Je hebt nu de basis van Bicep ervaren. In de einddemo ga je van één Bicep-bestand naar een realistische oplossing met herbruikbare modules, omgevingsparameters, security-by-default, driftcontrole en lifecyclebeheer.

## Einddemo: Secure Azure Landing Zone Met Herbruikbare Bicep-modules

Deze repository bevat een compacte ASR-demo over herbruikbare Azure Bicep-modules. De demo laat zien hoe je met een klein aantal gestandaardiseerde modules snel een veilige applicatieomgeving uitrolt met consistente naming, tags, monitoring en private connectivity.

De insteek is bewust compact: geen enterprise landing zone met tientallen lagen, maar een realistische mini-landing-zone waarin de principes duidelijk zichtbaar blijven.

### Doel Van De Einddemo

In deze demo ontdek je hoe een financiële organisatie security-by-default en herhaalbaarheid kan combineren:

- Eén `main.bicep` op subscription scope maakt de resource group en orkestreert de modules.
- Herbruikbare modules leveren netwerk, storage, Web App runtime, monitoring en optionele RBAC.
- Alle resources worden uitgerold in West Europe.
- Governance is zichtbaar via verplichte tags voor applicatie, omgeving, eigenaar, cost center, beheerwijze en klant.
- Publieke toegang staat uit voor dataresources; toegang loopt via private endpoints en private DNS.

### Architectuur Van De Einddemo

De demo rolt per omgeving een applicatie-resource-group uit:

- Resource group: `rg-asr-{applicationName}-{environment}-we-001`
- Virtual network: `vnet-asr-{applicationName}-{environment}-we-001`
- Web App: `app-asr-{applicationName}-{environment}-we-001-{uniqueSuffix}`
- Storage account: `st{applicationName}{environment}{uniqueSuffix}`
- Subnets:
  - `subnet-app` met NSG
  - `subnet-data` met NSG
  - `subnet-private-endpoints` voor private endpoints
- Log Analytics Workspace met 30 dagen retention
- Workspace-based Application Insights
- Web App met:
  - Linux App Service Plan op Premium V3, geschikt voor maximaal 20 deployment slots
  - PHP runtime
  - system-assigned managed identity
  - HTTPS only
  - minimum TLS 1.2
  - FTPS uitgeschakeld
  - `staging` deployment slot
  - Application Insights configuratie
  - diagnostic settings naar Log Analytics
- Storage account met:
  - publieke netwerktoegang uit
  - blob public access uit
  - shared key access uit
  - OAuth default authentication aan
  - Azure Files file service
  - private endpoint voor `file`
  - private DNS zone `privatelink.file.core.windows.net`
  - diagnostic settings naar Log Analytics
- Optionele voorbeeld-role-assignment op resource group scope.

### Folderstructuur

```text
bicep-demo-asr/
├─ README.md
├─ main.bicep
├─ main.parameters.dev.bicepparam
├─ main.parameters.test.bicepparam
├─ main.parameters.prod.bicepparam
├─ learning-path/
│  ├─ arm-vm/
│  │  └─ main.json
│  └─ bicep-vm/
│     └─ main.bicep
├─ scripts/
│  └─ cleanup.sh
└─ modules/
   ├─ network/
   │  └─ vnet.bicep
   ├─ storage/
   │  └─ storageAccount.bicep
   ├─ webapp/
   │  └─ webApp.bicep
   ├─ monitoring/
   │  └─ logAnalytics.bicep
   └─ security/
      └─ roleAssignments.bicep
```

### Parameters Van De Einddemo

De hoofdtemplate gebruikt deze parameters:

- `environment`: `dev`, `test` of `prod`
- `applicationName`: korte applicatienaam, maximaal 5 tekens voor compacte en consistente resource names
- `location`: vastgezet op `westeurope`
- `owner`: eigenaar voor governance
- `costCenter`: kostenplaats voor chargeback/showback
- `principalId`: optioneel object-ID van een Entra ID-groep voor de voorbeeld-role-assignment
- `roleDefinitionId`: optioneel aanpasbare role definition, standaard `Reader`
- `deployStagingSlot`: bepaalt of het staging slot wordt uitgerold, standaard `true`

De parameterbestanden gebruiken het Bicep-native `.bicepparam` formaat met dummywaarden. Hoewel Azure de technische parameternaam `principalId` gebruikt, verwacht deze demo specifiek het object-ID van een **Entra ID-groep** en niet van een service principal, gebruiker of managed identity.

Web App- en Storage Account-namen moeten wereldwijd uniek zijn. De template voegt daarom automatisch een deterministische `uniqueString` op basis van de subscription-ID toe. Cursisten hoeven hiervoor geen eigen naam te bedenken.

## A. Bereid De Einddemo Voor

Voer de einddemo uit in **Bash** vanuit de map `bicep-demo-asr`. Wanneer je P2 tot en met P4 in dezelfde Cloud Shell-sessie hebt uitgevoerd, staan de repository en hulpmiddelen al klaar.

### A1. Controleer Of Herstel De Cloud Shell-sessie

Start Cloud Shell met **Bash** wanneer deze niet meer geopend is. Controleer daarna de hulpmiddelen en Azure-context:

```bash
az version
bicep --version
git --version
az account show --output table
```

Cloud Shell is al aangemeld met de portalsessie. Voer daarom geen afzonderlijk `az login`-commando uit.

### A2. Controleer Of Clone De Repository

```bash
cd ~

if [ -d bicep-demo-asr/.git ]; then
  git -C bicep-demo-asr pull --ff-only
else
  git clone https://github.com/ericvanlaargmailcom/bicep-demo-asr.git
fi

cd bicep-demo-asr
```

Voor het klonen is geen GitHub-account nodig. De bestanden bestaan alleen zolang de tijdelijke Cloud Shell-sessie bestaat.

### A3. Open De Cloud Shell-editor

```bash
code .
```

De Cloud Shell-editor bevat een bestandsverkenner en syntax highlighting. Gebruik de editor om `main.bicep`, de parameterbestanden en modules te bekijken. Gebruik de Bash-terminal onder de editor voor alle deployment- en cleanupcommando's. Met ``Ctrl+` `` wissel je tussen de editor en de terminal.

## B. Deployment Commands In Azure Cloud Shell

Voer alle commando's in dit hoofdstuk uit in **Bash** vanuit de Cloud Shell-map `bicep-demo-asr`. Houd Cloud Shell tijdens de oefeningen geopend. Na een beëindigde tijdelijke sessie moet je de repository opnieuw clonen en variabelen zoals `RESOURCE_GROUP_NAME`, `WEB_APP_NAME`, `STACK_NAME` en `GROUP_ID` opnieuw instellen bij de stap waar je verdergaat.

### B1. Valideer En Deploy De Omgeving

#### B1.1 Controleer De Cloud Shell-context

Controleer vanuit de map `bicep-demo-asr` welke tenant en subscription actief zijn:

```bash
pwd
az account show --output table
```

Ga pas verder wanneer `pwd` eindigt op `/bicep-demo-asr` en `az account show` de juiste tenant en subscription toont.

#### B1.2 Valideer De Bicep-template

Valideer of de Bicep compileert. Bij een geldige template verschijnt een compacte JSON-bevestiging; bij een fout toont de Bicep-compiler de foutmelding en geeft het commando een mislukte exitcode terug:

```bash
if bicep build main.bicep --stdout > /dev/null; then
  printf '{"success":true,"file":"main.bicep"}\n'
else
  printf '{"success":false,"file":"main.bicep"}\n'
  false
fi
```

Wil je ook de volledige gegenereerde ARM-template als JSON bekijken, gebruik dan:

```bash
bicep build main.bicep --stdout
```

#### B1.3 Deploy De Dev-omgeving

Deploy de dev-omgeving:

```bash
DEPLOYMENT_NAME="asr-dev"

az deployment sub create \
  --name "$DEPLOYMENT_NAME" \
  --location westeurope \
  --template-file main.bicep \
  --parameters main.parameters.dev.bicepparam \
  --verbose
```

`--verbose` toont aanvullende informatie van Azure CLI. Tijdens een langlopende deployment blijft de voortgangsindicator soms alsnog op `Running` staan. Wil je tussendoor zien welke onderdelen Azure verwerkt, open dan via **New session** een tweede Cloud Shell-sessie en voer daar uit:

```bash
az deployment operation sub list \
  --name asr-dev \
  --query "[].{Resource:properties.targetResource.resourceName,Type:properties.targetResource.resourceType,State:properties.provisioningState}" \
  --output table
```

Voer dit controlecommando eventueel na enkele minuten opnieuw uit. De oorspronkelijke Cloud Shell-sessie blijft de deployment uitvoeren.

> **Deployment mislukt?** Voer vóór een nieuwe poging altijd `./scripts/cleanup.sh` uit en wacht op de melding dat de cleanup is voltooid. Een mislukte deployment kan gedeeltelijk aangemaakte resources achterlaten, zoals een Private DNS-link. Opnieuw deployen zonder cleanup kan daardoor een conflict veroorzaken.

#### B1.4 Controleer De Deployment In De Azure Portal

Voer na een geslaagde deployment een visuele controle uit:

1. Minimaliseer Cloud Shell zodat de Azure Portal weer volledig zichtbaar is.
2. Zoek bovenin de portal naar **Resource groups**.
3. Open de resourcegroep `rg-asr-asrdm-dev-we-001`.
4. Bekijk op de pagina **Overview** de lijst met uitgerolde resources.
5. Controleer dat je onder andere een Virtual Network, Network Security Groups, Log Analytics Workspace, Application Insights, App Service Plan, Web App, Storage Account, Private Endpoint en Private DNS Zone ziet.
6. Open in het linkermenu **Deployments** en controleer dat de moduledeployments, waaronder `monitoring-dev`, `network-dev`, `storage-dev` en `webapp-dev`, de status **Succeeded** hebben.
7. Ga terug naar **Overview** en open eventueel de Web App of Storage Account om de automatisch gegenereerde naam te bekijken.

De Web App en Storage Account bevatten een unieke suffix. Daardoor kunnen meerdere cursisten dezelfde template gebruiken zonder dat hun wereldwijd unieke resourcenamen botsen.

#### B1.5 Deploy Test En Prod

Voor ASR laat deze stap zien hoe één goedgekeurde infrastructuurstandaard gecontroleerd door verschillende omgevingen kan bewegen. Dezelfde `main.bicep` en herbruikbare modules worden voor dev, test en prod gebruikt; alleen het parameterbestand verandert.

Dit is nuttig omdat:

- security-instellingen, naming, tags, monitoring en private connectivity in iedere omgeving op dezelfde manier worden toegepast;
- teams wijzigingen eerst in dev en test kunnen beoordelen voordat dezelfde standaard naar prod gaat;
- omgevingen van elkaar gescheiden blijven, terwijl configuratieverschillen expliciet en reviewbaar in parameterbestanden staan;
- handmatige configuratiefouten en ongewenste afwijkingen tussen omgevingen worden beperkt;
- deployments en parameterwijzigingen via Git achteraf herleidbaar en controleerbaar zijn.

Deploy eerst test en daarna prod door alleen het parameterbestand te wisselen:

```bash
az deployment sub create \
  --name asr-test \
  --location westeurope \
  --template-file main.bicep \
  --parameters main.parameters.test.bicepparam
```

```bash
az deployment sub create \
  --name asr-prod \
  --location westeurope \
  --template-file main.bicep \
  --parameters main.parameters.prod.bicepparam
```

Virsoft ruimt de volledige cursus-subscription na maximaal zes uur automatisch op. De vervolgoefeningen gebruiken alleen de dev-omgeving; test en prod blijven als demonstratie van de herhaalbare standaard bestaan totdat de automatische cleanup plaatsvindt of je later zelf `./scripts/cleanup.sh` uitvoert.

### B2. Ervaar Infrastructuurdrift Met What-If

Infrastructuurdrift ontstaat wanneer iemand een gedeployde resource buiten Bicep om wijzigt. In deze oefening verwijdert de tijdelijke beheerder het deployment slot `staging` handmatig, terwijl dit slot nog steeds in de Bicep-code staat.

#### B2.1 Stel De Resourcenamen In

Haal de werkelijke namen van de dev-resources op uit de deployment-output. De Web App-naam bevat een automatisch gegenereerde suffix en is daarom voor iedere subscription anders:

```bash
DEPLOYMENT_NAME="asr-dev"
RESOURCE_GROUP_NAME=$(az deployment sub show \
  --name "$DEPLOYMENT_NAME" \
  --query "properties.outputs.resourceGroupName.value" \
  --output tsv)
WEB_APP_NAME=$(az deployment sub show \
  --name "$DEPLOYMENT_NAME" \
  --query "properties.outputs.webAppName.value" \
  --output tsv)

printf 'Resource group: %s\nWeb App: %s\n' "$RESOURCE_GROUP_NAME" "$WEB_APP_NAME"
```

#### B2.2 Controleer Het Staging Slot

Controleer eerst dat het staging slot bestaat:

```bash
az webapp deployment slot list \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$WEB_APP_NAME" \
  --query "[].{slot:name,state:state}" \
  --output table
```

#### B2.3 Verwijder Het Slot Handmatig

Simuleer vervolgens via de Azure Portal een handmatige wijziging buiten Bicep om:

1. Open in de Azure Portal de resourcegroep waarvan de naam bij **B2.1** is getoond.
2. Open de Web App waarvan de naam bij **B2.1** is getoond.
3. Selecteer in het menu **Deployment > Deployment slots**.
4. Selecteer het slot **staging**.
5. Kies **Delete** en bevestig de verwijdering.

#### B2.4 Detecteer Drift Met What-If

Voer het eerdere `az webapp deployment slot list`-commando opnieuw uit om te controleren dat het slot verdwenen is. De Bicep-code bevat het staging slot nog steeds. Gebruik daarom `what-if` om de actuele Azure-omgeving met de gewenste configuratie te vergelijken:

```bash
az deployment sub what-if \
  --location westeurope \
  --template-file main.bicep \
  --parameters main.parameters.dev.bicepparam
```

Zoek in de uitvoer naar het Web App-slot `staging`. Het ontbrekende slot en de bijbehorende diagnostic settings worden als `Create` weergegeven. `What-if` verandert zelf nog niets.

Het is normaal dat de samenvatting meer wijzigingen toont dan de ene handmatige actie die je hebt uitgevoerd. Eén deployment slot bestaat in deze template uit twee afzonderlijke Azure-resources: het slot zelf en de diagnostic settings die eraan gekoppeld zijn. Na het verwijderen van het slot kan de samenvatting daarom bijvoorbeeld `2 to create` tonen.

Lees de categorieën als volgt:

- **Create:** de resource staat in Bicep, maar ontbreekt in Azure. In deze oefening zijn dit het `staging`-slot en de bijbehorende diagnostic settings.
- **Modify:** Azure verwacht een verschil in één of meer eigenschappen. Een deel hiervan kan What-If-ruis zijn, bijvoorbeeld doordat Azure standaardwaarden toevoegt of doordat waarden uit module-outputs en resource-referenties pas tijdens de echte deployment kunnen worden berekend. Controleer daarom de getoonde eigenschappen; een `Modify` betekent niet automatisch dat iemand die resource handmatig heeft aangepast.
- **NoChange:** de resource staat in Bicep en komt al overeen met de actuele Azure-configuratie.
- **Ignore:** de resource bestaat in Azure, maar maakt geen deel uit van deze deployment. Omdat dit een incrementele deployment is, laat Azure deze resource ongemoeid.

De precieze aantallen kunnen per subscription en moment verschillen. Voor deze drift-oefening is vooral belangrijk dat het slot en zijn diagnostic settings onder **Create** staan. Dat bewijst dat Bicep de ontbrekende gewenste configuratie heeft gedetecteerd.

#### B2.5 Herstel Het Slot Met Bicep

Herstel daarna de gedeclareerde omgeving met dezelfde Bicep-deployment:

```bash
az deployment sub create \
  --name "$DEPLOYMENT_NAME" \
  --location westeurope \
  --template-file main.bicep \
  --parameters main.parameters.dev.bicepparam
```

Voer het eerdere `az webapp deployment slot list`-commando opnieuw uit. Het slot `staging` hoort nu weer te bestaan. Ongewijzigde resources worden niet opnieuw aangemaakt; de deployment herstelt de resources die ontbreken of afwijken van de Bicep-code.

Je ziet hiermee dat Bicep geen Terraform-statefile nodig heeft om deze drift te vinden: ARM vergelijkt de gewenste template met de actuele configuratie in Azure.

> Verwijder in deze oefening uitsluitend het staging slot en niet de productie-Web App. Eventuele applicatie-inhoud die handmatig in het slot is geplaatst, wordt niet door Bicep hersteld.

### B3. Verwijder Een Resource Uit De Gewenste Configuratie

#### B3.1 Schakel Het Staging Slot Uit

De vorige oefening liet zien dat gewone Bicep een ontbrekende resource kan herstellen zolang die resource nog in de gewenste configuratie staat. Nu draai je het scenario om: het staging slot bestaat nog in Azure, maar je haalt het uit de gewenste configuratie.

De parameter `deployStagingSlot=false` zorgt ervoor dat de conditionele declaraties van het slot en zijn diagnostic settings niet in de gegenereerde ARM-template komen. Hiermee simuleer je dat de resources uit de Bicep-code zijn verwijderd, zonder dat je het modulebestand handmatig hoeft te wijzigen.

#### B3.2 Bekijk De Wijziging Met What-If

Bekijk eerst met een gewone incrementele deployment wat Azure zou veranderen:

```bash
az deployment sub what-if \
  --location westeurope \
  --template-file main.bicep \
  --parameters main.parameters.dev.bicepparam \
  --parameters deployStagingSlot=false
```

De samenvatting kan bijvoorbeeld `5 to modify`, `11 no change` en `4 to ignore` tonen. De `Modify`-regels kunnen dezelfde What-If-ruis bevatten die bij **B2.4** is uitgelegd; controleer de getoonde eigenschappen in plaats van alleen het aantal. Het belangrijke verschil is dat het bestaande staging slot nu niet meer in de gegenereerde template staat. Bij een incrementele deployment classificeert Azure bestaande resources buiten de template als **Ignore**: ze worden niet beheerd door deze deployment, maar ook niet verwijderd.

De precieze aantallen kunnen verschillen. Controleer vooral dat het staging slot niet als **Delete** wordt weergegeven. Dat is het gedrag dat deze oefening wil aantonen.

#### B3.3 Voer De Incrementele Deployment Uit

Het staging slot wordt niet als `Delete` weergegeven. Voer daarna dezelfde configuratie daadwerkelijk uit:

> **Waarom duurt dit toch enkele minuten?** Incrementeel betekent niet dat Azure uitsluitend gewijzigde regels uitvoert. Azure Resource Manager valideert de volledige template en alle modules opnieuw, berekent afhankelijkheden en module-outputs en biedt de gedeclareerde resources opnieuw aan bij de verschillende Resource Providers. Die providers controleren vervolgens of de actuele configuratie overeenkomt met de gewenste configuratie. Daardoor kan de deployment ongeveer even lang duren als een gewone update, ook wanneer uiteindelijk vrijwel niets verandert. Het belangrijke kenmerk van de incrementele modus is hier dat een bestaande resource die niet meer in de template staat niet automatisch wordt verwijderd.

```bash
az deployment sub create \
  --name "$DEPLOYMENT_NAME" \
  --location westeurope \
  --template-file main.bicep \
  --parameters main.parameters.dev.bicepparam \
  --parameters deployStagingSlot=false
```

#### B3.4 Controleer Het Staging Slot

Controleer opnieuw:

```bash
az webapp deployment slot list \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$WEB_APP_NAME" \
  --query "[].{slot:name,state:state}" \
  --output table
```

#### B3.5 Verklaar Het Resultaat

Het slot bestaat nog steeds. Gewone Bicep-deployments gebruiken standaard de incrementele modus: Azure maakt en wijzigt gedeclareerde resources, maar verwijdert niet automatisch een bestaande resource die uit de nieuwe template is verdwenen.

Dit is de beperking die de handmatige drift-oefening niet liet zien:

- **Resource ontbreekt in Azure, maar staat nog in Bicep:** What-If toont `Create` en een deployment herstelt de resource.
- **Resource bestaat in Azure, maar staat niet meer in Bicep:** een gewone incrementele deployment laat de resource staan.

### B4. Ruim De Gewone Deployment Op

#### B4.1 Voer Het Cleanup-script Uit

Verwijder de gewone Bicep-omgeving voordat je dezelfde omgeving als Deployment Stack maakt. Zo begint de stack met een schone omgeving en is duidelijk welke resources door de stack worden beheerd:

```bash
./scripts/cleanup.sh
```

#### B4.2 Controleer De Resourcegroep

Controleer dat de dev-resourcegroep verdwenen is:

```bash
az group exists \
  --name "$RESOURCE_GROUP_NAME"
```

De verwachte uitvoer is `false`.

### B5. Deploy De Omgeving Als Deployment Stack

Een Deployment Stack voegt aan een gewone Bicep-deployment lifecyclebeheer toe dat conceptueel lijkt op Terraform. Standaard beschrijft Bicep wel de gewenste configuratie, maar een gewone incrementele deployment onthoudt niet blijvend welke resources bij eerdere deployments hoorden en verwijdert een resource daarom niet wanneer die later uit de template verdwijnt. Een Deployment Stack bewaart wél het ownership van de beheerde resource-ID's en past lifecycle-instellingen toe wanneer een resource niet langer wordt gedeclareerd, bijvoorbeeld verwijderen met `deleteAll` of alleen loskoppelen van de stack. Dit lijkt op de manier waarop Terraform beheerde resources via state volgt, maar een Deployment Stack is geen volledige Terraform-statefile met alle resource-eigenschappen en providerinformatie.

#### B5.1 Controleer De Azure CLI-versie

Deployment Stacks vereisen Azure CLI 2.61.0 of nieuwer. Controleer de geïnstalleerde versie:

```bash
az version
```

#### B5.2 Bouw Het Parameterbestand

De gewone `az deployment sub create`-commando's uit de eerdere oefeningen kunnen het gekoppelde `.bicepparam`-bestand rechtstreeks verwerken. Het `az stack sub`-commando verwerkt een parameterbestand daarentegen in het standaard ARM JSON-formaat. Daarom moet het Bicep-parameterbestand voor deze stack eerst worden gecompileerd.

`bicep build-params` verandert de parameterwaarden niet. Het zet de mensvriendelijke Bicep-syntax om naar de JSON-structuur die Azure Resource Manager voor de stack verwacht. Het gegenereerde bestand wordt bewust in `/tmp` geplaatst: `main.parameters.dev.bicepparam` blijft de enige bron die je onderhoudt en het tijdelijke JSON-bestand hoeft niet in Git te worden opgeslagen.

Zet het Bicep-parameterbestand om naar een ARM JSON-parameterbestand:

```bash
bicep build-params main.parameters.dev.bicepparam \
  --outfile /tmp/main.parameters.dev.json
```

#### B5.3 Stel De Stacknaam In

Stel een vaste stacknaam in:

```bash
STACK_NAME="stack-asr-asrdm-dev-we-001"
```

#### B5.4 Valideer De Stack

Valideer de stack:

```bash
az stack sub validate \
  --name "$STACK_NAME" \
  --location westeurope \
  --template-file main.bicep \
  --parameters /tmp/main.parameters.dev.json \
  --action-on-unmanage deleteAll \
  --deny-settings-mode none
```

#### B5.5 Maak De Stack

Maak daarna de stack en de dev-omgeving:

```bash
az stack sub create \
  --name "$STACK_NAME" \
  --location westeurope \
  --template-file main.bicep \
  --parameters /tmp/main.parameters.dev.json \
  --action-on-unmanage deleteAll \
  --deny-settings-mode none \
  --description "ASR Bicep Deployment Stacks lab" \
  --yes
```

#### B5.6 Controleer De Stack En Resources

Een Deployment Stack is zelf een Azure-resource op het gekozen beheerniveau. Deze stack is op subscriptionniveau aangemaakt en is daarom ook vanuit de cursus-subscription in de Azure Portal terug te vinden. De portalweergave voor Deployment Stacks is nog beperkt, maar laat wel zien dat de stack bestaat en welke resources hij beheert.

Voer na het aanmaken van de stack eerst een visuele controle uit in de Azure Portal:

1. Minimaliseer Cloud Shell zodat de Azure Portal weer volledig zichtbaar is.
2. Zoek bovenin de portal naar **Subscriptions** en open de cursus-subscription.
3. Selecteer in het linkermenu van de subscription **Deployment stacks**.
4. Controleer dat de stack `stack-asr-asrdm-dev-we-001` in de lijst staat en open deze.
5. Controleer dat de provisioningstatus **Succeeded** is en dat de stack op de cursus-subscription is aangemaakt.
6. Bekijk de beheerde resources van de stack. Controleer dat `rg-asr-asrdm-dev-we-001` in de lijst staat en zoek ook naar het Web App-slot `staging`. Hiermee zie je dat de stack niet alleen resources heeft uitgerold, maar hun resource-ID's nu ook voor lifecyclebeheer volgt.
7. Zoek daarna naar **Resource groups** en open `rg-asr-asrdm-dev-we-001`.
8. Bekijk op **Overview** opnieuw de uitgerolde resources en controleer dat onder andere het Virtual Network, de Web App, het Storage Account en de monitoringresources aanwezig zijn.
9. Open in het linkermenu **Deployments** en controleer dat de moduledeployments de status **Succeeded** hebben.

Bekijk vervolgens vanuit Cloud Shell de stack en zijn beheerde resources:

```bash
az stack sub show \
  --name "$STACK_NAME" \
  --output json
```

Controleer ook dat het staging slot opnieuw bestaat. Bij **B4** is de eerdere dev-omgeving opgeruimd en bij **B5.5** heeft de Deployment Stack een nieuwe dev-omgeving gemaakt met `deployStagingSlot=true`, de standaardwaarde uit de template. Het slot moet daarom opnieuw zijn aangemaakt én door de stack worden beheerd.

Deze controle is een belangrijke voorwaarde voor **B6**. Daar wordt hetzelfde slot uit de gewenste configuratie gehaald en moet de stack het dankzij `deleteAll` verwijderen. Wanneer het slot hier al ontbreekt, kun je in B6 niet aantonen dat de Deployment Stack lifecyclebeheer toepast; een ontbrekend slot kan dan ten onrechte op een geslaagde verwijdering lijken.

```bash
az webapp deployment slot list \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$WEB_APP_NAME" \
  --query "[].{slot:name,state:state}" \
  --output table
```

### B6. Laat De Deployment Stack Het Slot Verwijderen

#### B6.1 Werk De Stack Bij Zonder Staging Slot

Werk dezelfde stack bij en zet het staging slot opnieuw buiten de gewenste configuratie:

```bash
az stack sub create \
  --name "$STACK_NAME" \
  --location westeurope \
  --template-file main.bicep \
  --parameters /tmp/main.parameters.dev.json \
  --parameters deployStagingSlot=false \
  --action-on-unmanage deleteAll \
  --deny-settings-mode none \
  --description "ASR Bicep Deployment Stacks lab" \
  --yes
```

#### B6.2 Controleer Dat Het Slot Is Verwijderd

Controleer de deployment slots:

```bash
az webapp deployment slot list \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$WEB_APP_NAME" \
  --query "[].{slot:name,state:state}" \
  --output table
```

Het slot `staging` is nu verwijderd. Ook de diagnostic settings van het slot worden niet langer beheerd en zijn verwijderd.

#### B6.3 Verklaar Het Verschil Met Gewone Bicep

Het verschil met stap **B3** is resource-ownership:

- De gewone deployment wist niet dat het bestaande slot bij een eerdere template hoorde en liet het daarom staan.
- De Deployment Stack wist dat het slot eerder door deze stack werd beheerd. Toen het slot uit de gewenste configuratie verdween, bepaalde `deleteAll` dat de onbeheerd geraakte resource moest worden verwijderd.

Deployment Stacks bewaren hiermee een vorm van geheugen over **ownership**, maar geen volledige Terraform-statefile met alle resource-eigenschappen en providerinformatie.

> Deployment Stacks ondersteunen momenteel geen What-If. Controleer daarom vóór een stack-update zorgvuldig de template, parameters, lijst met beheerde resources en de ingestelde waarde voor `action-on-unmanage`.

#### B6.4 Herstel Het Staging Slot

Herstel het slot voor eventuele vervolgoefeningen:

```bash
az stack sub create \
  --name "$STACK_NAME" \
  --location westeurope \
  --template-file main.bicep \
  --parameters /tmp/main.parameters.dev.json \
  --parameters deployStagingSlot=true \
  --action-on-unmanage deleteAll \
  --deny-settings-mode none \
  --description "ASR Bicep Deployment Stacks lab" \
  --yes
```

### B7. Begrijp Complete Mode, Deployment Stacks En Terraform

#### B7.1 Vergelijk De Verwijdermechanismen

Complete Mode is geen onderdeel van Deployment Stacks. Het is een oudere deploymentmodus van ARM waarbij resources in de doel-resourcegroep kunnen worden verwijderd wanneer ze niet in de template staan.

Het verschil zit in de selectie van resources:

| Mechanisme | Welke bestaande resources kunnen worden verwijderd? | Kent ownership? |
|---|---|---|
| Gewone Bicep, incremental | Resources die niet meer in de template staan blijven bestaan. | Nee |
| ARM Complete Mode | Resources in de doel-resourcegroep die niet in de template staan. | Nee |
| Deployment Stack | Resources die eerder door de stack werden beheerd en nu onbeheerd raken. | Ja |

#### B7.2 Begrijp Het Risico Van Complete Mode

Complete Mode kan daardoor ook een handmatig aangemaakte of door een ander proces beheerde resource verwijderen wanneer die toevallig in dezelfde resourcegroep staat maar niet in de template voorkomt. Deployment Stacks werken gerichter vanuit hun lijst met beheerde resources.

Microsoft raadt voor verwijderingen met Bicep Deployment Stacks aan. Complete Mode wordt geleidelijk uitgefaseerd, werkt alleen op resource group deployments en wordt daarom in deze cursus niet uitgevoerd.

#### B7.3 Vergelijk Bicep Met Terraform

Terraform gebruikt een statefile en onthoudt daarmee uitgebreider welke resources en eigenschappen het beheert. Conceptueel:

- **Gewone Bicep:** gewenste template tegenover de actuele Azure-omgeving.
- **Bicep met Deployment Stack:** gewenste template plus ownership van beheerde Azure-resources.
- **Terraform:** gewenste configuratie plus een uitgebreide state over beheerde resources.

Het praktische aha-moment blijft hetzelfde: wanneer een eerder beheerde resource uit de code verdwijnt, kan een Deployment Stack die gericht verwijderen; een gewone incrementele Bicep-deployment doet dat niet.

### B8. Verwijder De Deployment Stack En Omgeving

#### B8.1 Bekijk De Beheerde Resources

Bekijk eventueel nog één keer welke resources worden beheerd:

```bash
az stack sub show \
  --name "$STACK_NAME" \
  --query "resources[].{resource:id,status:status}" \
  --output table
```

#### B8.2 Verwijder De Stack En Omgeving

Verwijder daarna de stack, de beheerde resourcegroep en de resources:

```bash
az stack sub delete \
  --name "$STACK_NAME" \
  --action-on-unmanage deleteAll \
  --yes
```

#### B8.3 Controleer De Verwijdering

Controleer dat de stack en resourcegroep verdwenen zijn:

```bash
az stack sub list --output table
az group exists --name "$RESOURCE_GROUP_NAME"
```

De tweede opdracht hoort `false` terug te geven.

### B9. Demonstreer RBAC Als Code

#### B9.1 Begrijp De Opzet

De securitymodule maakt optioneel een Azure RBAC-role-assignment aan op de resource group. De module maakt de Entra ID-groep zelf niet aan. Je maakt daarom eerst een tijdelijke demogroep aan. In deze demo is `principalType` vastgezet op `Group`; een service principal, gebruiker of managed identity werkt hier dus niet.

#### B9.2 Maak Een Tijdelijke Entra-groep

Maak de tijdelijke groep aan en bewaar het object-ID:

```bash
GROUP_NAME="bicep-rbac-demo"
GROUP_ID=$(az ad group create \
  --display-name "$GROUP_NAME" \
  --mail-nickname "$GROUP_NAME" \
  --query id \
  --output tsv)

printf 'Entra group object ID: %s\n' "$GROUP_ID"
```

Hiervoor moet je cursusaccount groepen mogen aanmaken in Entra ID. Als dat niet is toegestaan, vraag je docent dan om een vooraf aangemaakte demogroep. Je kunt het object-ID daarvan opzoeken met `az ad group show`.

#### B9.3 Deploy De Role-assignment

Deploy vervolgens de dev-omgeving met het object-ID van de groep. De Bicep-parameter heet technisch `principalId`, maar bevat hier dus een groeps-ID:

```bash
az deployment sub create \
  --name asr-dev \
  --location westeurope \
  --template-file main.bicep \
  --parameters main.parameters.dev.bicepparam \
  --parameters principalId="$GROUP_ID"
```

#### B9.4 Controleer De Role-assignment

De standaardrol is `Reader`. De groep mag daardoor resources in de demo-resourcegroep bekijken, maar niet wijzigen of verwijderen. Controleer de aangemaakte assignment met Azure CLI:

```bash
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
RESOURCE_GROUP_NAME="rg-asr-asrdm-dev-we-001"
SCOPE="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}"

az role assignment list \
  --scope "$SCOPE" \
  --assignee-object-id "$GROUP_ID" \
  --output table
```

Controleer ook in de Azure Portal bij **Resource group > Access control (IAM) > Role assignments** dat de Entra-groep de rol **Reader** heeft.

#### B9.5 Leg De Bicep-principes Uit

Wat deze demo over Bicep laat zien:

- **RBAC is declaratieve infrastructuur:** toegangsrechten staan naast de resources in broncode en zijn daardoor reviewbaar en herhaalbaar.
- **Least privilege:** de standaardrol is bewust `Reader` en de scope is beperkt tot één resource group.
- **Optionele governance:** de securitymodule wordt alleen uitgevoerd wanneer `principalId` is ingevuld.
- **Idempotency:** de naam van de role-assignment wordt met `guid()` deterministisch opgebouwd. Dezelfde deployment maakt daarom geen dubbele assignment.
- **Herbruikbaarheid:** via `roleDefinitionId` kan hetzelfde patroon ook een andere ingebouwde of custom rol toewijzen.

Meld je eventueel in een privébrowser aan als een testgebruiker uit de groep. Controleer dat deze gebruiker de resources kan bekijken, maar bijvoorbeeld geen resource kan verwijderen. Houd rekening met enkele minuten verwerkingstijd voor nieuwe RBAC-toewijzingen.

De uitvoerder van de Bicep-deployment moet zelf rechten hebben om role-assignments te maken, bijvoorbeeld **Owner** of **User Access Administrator** op de betreffende scope.

#### B9.6 Verwijder De Demo-assignment En Groep

> Alleen opnieuw deployen zonder `principalId` verwijdert een bestaande assignment niet bij een incrementele deployment. Verwijder de demo-assignment daarom expliciet:

```bash
az role assignment delete \
  --scope "$SCOPE" \
  --assignee-object-id "$GROUP_ID" \
  --role Reader

az ad group delete --group "$GROUP_ID"
```

> **Klaar met de oefeningen?** Voer nu `./scripts/cleanup.sh` uit. Hiermee verwijder je de bekende Deployment Stacks, de resourcegroepen van dev, test en prod en eventuele achtergebleven resourcegroepen uit P1 tot en met P4.

## C. Wat Je Uit De Architectuur Kunt Afleiden

### C1. Bekijk De Orkestratie In Main.bicep

Start bij `main.bicep`. Laat zien dat dit bestand vooral orkestratie doet: resource group aanmaken, standaardnamen bepalen, tags centraal opbouwen en modules aanroepen.

### C2. Bekijk De Herbruikbare Modules

Open daarna de modules:

- `modules/network/vnet.bicep`: standaard netwerkbouwblok met vaste subnets en NSG's.
- `modules/monitoring/logAnalytics.bicep`: gedeelde observability voor logs, metrics en Application Insights.
- `modules/storage/storageAccount.bicep`: secure-by-default dataopslag met public access uit, OAuth-default en private endpoint.
- `modules/webapp/webApp.bicep`: gestandaardiseerde PHP applicatieruntime met managed identity, HTTPS only, Application Insights en een `staging` slot voor CI/CD.
- `modules/security/roleAssignments.bicep`: klein voorbeeld van uitbreidbare governance op resource group scope.

### C3. Herken De Kernboodschap

Je hebt nu gezien dat `main.bicep` de infrastructuur niet volledig zelf beschrijft, maar een aantal herbruikbare bouwblokken samenvoegt. Een platformteam kan deze modules centraal ontwikkelen, testen en goedkeuren. Security-instellingen, naming, tags, monitoring en netwerkkeuzes worden daarmee één keer in de modules vastgelegd.

Dit sluit aan bij het doel van een Azure Solution Review. Een review gaat niet alleen over de vraag of een losse resource technisch werkt, maar ook over de vraag of de volledige oplossing voldoet aan de afgesproken architectuurprincipes. Denk aan veilige netwerktoegang, centrale logging, consistente tags, herkenbare resourcenamen en het uitschakelen van onnodige publieke toegang. Door deze keuzes in herbruikbare modules vast te leggen, worden reviewafspraken onderdeel van de uitvoerbare infrastructuurcode.

Een applicatieteam hoeft die keuzes vervolgens niet voor iedere omgeving of applicatie opnieuw te maken. Het team gebruikt de goedgekeurde modules en levert alleen de waarden aan die werkelijk per workload of omgeving verschillen. In deze demo zijn dat bijvoorbeeld de omgevingsnaam, applicatienaam, eigenaar en kostenplaats. Daardoor ontstaat in dev, test en prod dezelfde veilige en herkenbare basis, terwijl bewuste configuratieverschillen expliciet in de parameterbestanden blijven staan.

Deze scheiding maakt ook de verantwoordelijkheden duidelijker. Het platformteam beheert de kwaliteit van de bouwblokken en bepaalt welke technische standaard daarin wordt afgedwongen. Het applicatieteam combineert die bouwblokken in `main.bicep` en vult de workloadspecifieke parameters in. Een ontwikkelaar hoeft daardoor niet voor iedere deployment opnieuw uit te zoeken hoe diagnostic settings, private endpoints, managed identities of securityinstellingen moeten worden geconfigureerd.

Wanneer de organisatie later een standaard wil verbeteren, hoeft die wijziging niet handmatig in iedere afzonderlijke template te worden gekopieerd. Het platformteam kan de gedeelde module aanpassen, testen en als nieuwe versie beschikbaar stellen. Applicatieteams kunnen die verbetering vervolgens gecontroleerd overnemen. Dat verkleint de kans op copy-pastefouten en voorkomt dat tientallen bijna gelijke templates langzaam van elkaar gaan afwijken.

De parameterbestanden en deployments maken bovendien zichtbaar welke standaard in welke omgeving is toegepast. Wijzigingen kunnen via Git worden gereviewd en de deploymenthistorie in Azure laat zien wanneer de infrastructuur is uitgerold. What-If helpt vooraf om verschillen te beoordelen en Deployment Stacks voegen ownership en lifecyclebeheer toe voor resources die later uit de gewenste configuratie verdwijnen.

De winst zit dus niet alleen in minder Bicep-code schrijven. Herbruikbare modules vertalen architectuurafspraken naar een herhaalbare technische standaard. Ze maken de veilige werkwijze de eenvoudige standaardroute voor teams en zorgen dat verbeteringen centraal, gecontroleerd en aantoonbaar kunnen worden doorgevoerd.

## D. Cleanup Commands

Ben je klaar met ontdekken of neem je een langere pauze, voer dan altijd het cleanup-script uit:

```bash
./scripts/cleanup.sh
```

Het script verwijdert eerst bekende Deployment Stacks met `deleteAll`. Daarna verwijdert het eventuele resterende resourcegroepen van dev, test en prod én de vaste oefen-resourcegroepen uit P1 tot en met P4 parallel. Tot slot controleert het of er nog cursus-stacks of -resourcegroepen bestaan.

Voor een afwijkende `applicationName` geef je de naam als argument mee:

```bash
./scripts/cleanup.sh "<applicationName>"
```

Omdat deze versie geen Key Vault meer gebruikt, is er geen soft-delete of purge-stap nodig. De cleanup blijft daardoor geschikt voor herhaalde cursusdemo's.

## E. Optionele Verdieping En Naslag – Deployment Stacks

In **B5** en **B6** heb je Deployment Stacks al praktisch gebruikt: de stack nam ownership over de resources en verwijderde met `deleteAll` het staging slot toen dit uit de gewenste configuratie verdween. Dit optionele hoofdstuk is geen nieuwe doorlopende oefening, maar naslag voor andere lifecyclekeuzes, beveiliging en veelvoorkomende problemen.

### E1. Action On Unmanage

In **B6** gebruikte je `deleteAll`. Ter vergelijking toont onderstaande tabel ook de twee andere keuzes voor wat Azure doet wanneer een resource na een stack-update of het verwijderen van de stack niet langer wordt beheerd:

| Actie | Gevolg |
|---|---|
| `detachAll` | Resources en resourcegroepen blijven bestaan, maar worden losgekoppeld van de stack. |
| `deleteResources` | Beheerde resources worden verwijderd, maar beheerde resourcegroepen blijven bestaan. |
| `deleteAll` | Beheerde resources en beheerde resourcegroepen worden verwijderd. |

Gebruik `deleteAll` alleen wanneer de stack eigenaar is van de volledige resourcegroep en alles daarin veilig verwijderd mag worden. Controleer vóór iedere update of delete de beheerde resources zoals je bij **B5.6** hebt gedaan.

### E2. Deny Settings

Deployment Stacks kunnen handmatige control-planewijzigingen aan beheerde resources beperken:

- `none`: geen extra blokkade;
- `denyDelete`: blokkade tegen verwijderen;
- `denyWriteAndDelete`: blokkade tegen wijzigen en verwijderen.

Deny settings zijn krachtig en kunnen ook beheerders hinderen tijdens herstel. Gebruik ze pas nadat uitzonderingen, beheerrollen en break-glass-toegang zijn ontworpen. Deze cursus gebruikt daarom `--deny-settings-mode none`.

### E3. Resources Loskoppelen In Plaats Van Verwijderen

Wil je de stack verwijderen maar de omgeving behouden, gebruik dan:

```bash
az stack sub delete \
  --name "$STACK_NAME" \
  --action-on-unmanage detachAll \
  --yes
```

De resources blijven dan in Azure bestaan, maar de verwijderde stack houdt hun ownership niet langer bij. Je kunt ze later opnieuw onder beheer brengen door een stack met de juiste template bij te werken of te maken. Begin voor het cursuslab steeds met een schone omgeving, zodat duidelijk zichtbaar blijft welke stack de resources beheert.

### E4. Problemen Oplossen

#### De Stack Bestaat Al

`az stack sub create` werkt een bestaande stack met dezelfde naam bij. Wil je opnieuw beginnen, voer dan `./scripts/cleanup.sh` uit.

#### De Resourcegroep Bestaat Al

Een eerdere gewone Bicep-deployment gebruikt dezelfde resourcegroepnaam. Ruim die deployment eerst op voordat je de stack maakt, zodat ownership niet onduidelijk wordt.

#### Stack Out Of Sync

Bekijk bij een stack-out-of-sync-melding eerst de volledige lijst met beheerde resources. Gebruik een bypass-optie nooit als standaardoplossing; deploy bij twijfel eerst opnieuw met dezelfde template en parameters als de huidige stack.

#### Onvoldoende Rechten

Controleer de geselecteerde subscription:

```bash
az account show --output table
```

De uitvoerder moet op subscriptionniveau Deployment Stacks en de gedeclareerde resources mogen beheren. Voor deny settings zijn aanvullende rechten of de daarvoor bedoelde Deployment Stack-rollen nodig.

### E5. Meer Informatie

- [Microsoft Learn: tijdelijke Azure Cloud Shell-sessies](https://learn.microsoft.com/azure/cloud-shell/get-started/ephemeral)
- [Microsoft Learn: Azure Cloud Shell-editor](https://learn.microsoft.com/azure/cloud-shell/use-cloud-shell-editor-new)
- [Microsoft Learn: Deployment Stacks met Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deployment-stacks)
- [Microsoft Learn: ARM-deploymentmodi](https://learn.microsoft.com/azure/azure-resource-manager/templates/deployment-modes)
- [Azure CLI: az stack sub](https://learn.microsoft.com/cli/azure/stack/sub)
- [Microsoft Learn: ARM/Bicep What-If](https://learn.microsoft.com/azure/azure-resource-manager/templates/deploy-what-if)
