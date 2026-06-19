# Secure Azure Landing Zone Mini-demo

Deze repository bevat een compacte klantdemo voor ASR over herbruikbare Azure Bicep modules. De demo laat zien hoe je met een klein aantal gestandaardiseerde modules snel een veilige applicatieomgeving kunt uitrollen met consistente naming, tags, monitoring en private connectivity.

De insteek is bewust compact: geen enterprise landing zone met tientallen lagen, maar een realistische mini-landing-zone die in 20 tot 30 minuten goed uit te leggen is.

## Doel Van De Demo

Met deze demo kun je laten zien hoe een financiële organisatie security-by-default en herhaalbaarheid kan combineren:

- Eén `main.bicep` op subscription scope maakt de resource group en orkestreert de modules.
- Herbruikbare modules leveren netwerk, storage, Web App runtime, monitoring en optionele RBAC.
- Alle resources worden uitgerold in West Europe.
- Governance is zichtbaar via verplichte tags voor applicatie, omgeving, eigenaar, cost center, beheerwijze en klant.
- Publieke toegang staat uit voor dataresources; toegang loopt via private endpoints en private DNS.

## Architectuur

De demo rolt per omgeving een applicatie-resource-group uit:

- Resource group: `rg-asr-{applicationName}-{environment}-we-001`
- Virtual network: `vnet-asr-{applicationName}-{environment}-we-001`
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
  - `staging` deployment slot voor CI/CD-demo's
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

## Folderstructuur

```text
bicep-demo-asr/
├─ README.md
├─ main.bicep
├─ main.parameters.dev.bicepparam
├─ main.parameters.test.bicepparam
├─ main.parameters.prod.bicepparam
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

## Parameters

De hoofdtemplate gebruikt deze parameters:

- `environment`: `dev`, `test` of `prod`
- `applicationName`: korte applicatienaam, maximaal 5 tekens voor compacte en consistente resource names
- `location`: vastgezet op `westeurope`
- `owner`: eigenaar voor governance
- `costCenter`: kostenplaats voor chargeback/showback
- `principalId`: optioneel object-ID van een Entra ID-groep voor de voorbeeld-role-assignment
- `roleDefinitionId`: optioneel aanpasbare role definition, standaard `Reader`

De parameterbestanden gebruiken het Bicep-native `.bicepparam` formaat met dummywaarden. Hoewel Azure de technische parameternaam `principalId` gebruikt, verwacht deze demo specifiek het object-ID van een **Entra ID-groep** en niet van een service principal, gebruiker of managed identity.

## Voorbereiding Op Een Schone Windows-Labpc

De labpc heeft voor deze voorbereiding internettoegang nodig. Gebruik **PowerShell** alleen voor de eerste installatie met `winget`. Gebruik daarna **Git Bash** voor alle Bicep-, Git- en Azure CLI-commando's. Git Bash wordt automatisch met Git for Windows geïnstalleerd.

### 1. Installeer Visual Studio Code, Git en Azure CLI Met PowerShell

Open PowerShell, bij voorkeur als administrator, en installeer op Windows 10/11 de benodigde onderdelen met Windows Package Manager (`winget`):

```powershell
winget install --exact --id Microsoft.VisualStudioCode
winget install --exact --id Git.Git
winget install --exact --id Microsoft.AzureCLI
```

Als `winget` niet beschikbaar is, gebruik dan de officiële installers:

- [Visual Studio Code voor Windows](https://code.visualstudio.com/download)
- [Git voor Windows](https://git-scm.com/download/win)
- [Azure CLI voor Windows](https://learn.microsoft.com/cli/azure/install-azure-cli-windows)

Sluit na de installatie PowerShell. Open vervolgens **Git Bash** vanuit het Startmenu. Hierdoor worden de nieuwe commando's via het bijgewerkte `PATH` gevonden.

Controleer daarna de installatie:

```bash
code --version
git --version
az version
```

### 2. Installeer Bicep Vanuit Git Bash

Installeer de Bicep CLI via Azure CLI:

```bash
az bicep install
az bicep version
```

Installeer vervolgens de officiële Bicep-extensie voor Visual Studio Code:

```bash
code --install-extension ms-azuretools.vscode-bicep
```

Je kunt dit ook handmatig doen in VS Code via **Extensions** (`Ctrl+Shift+X`), zoek op **Bicep** en kies de extensie van Microsoft.

### 3. Clone De GitHub-Repository

Ga naar een lokale werkmap en download de demo vanaf GitHub:

```bash
cd ~/Documents
git clone https://github.com/ericvanlaargmailcom/bicep-demo-asr.git
```

Hierdoor wordt een nieuwe map met de naam `bicep-demo-asr` aangemaakt. Als GitHub om aanmelding vraagt, meld je dan aan met een GitHub-account dat toegang heeft tot de repository.

### 4. Open De Demo In Visual Studio Code

Ga naar de zojuist gekloonde projectmap en open deze in VS Code:

```bash
cd ~/Documents/bicep-demo-asr
code .
```

Open daarna in VS Code een terminal via **Terminal > New Terminal** en controleer dat **Git Bash** als terminalprofiel is geselecteerd. Alle volgende deployment- en cleanupcommando's worden in deze terminal uitgevoerd.

## Deployment Commands Met Azure CLI

### 1. Meld Je Aan Bij Azure

Log in met het Global Administrator-account van de eigen Virsoft-tenant:

```bash
az login
```

Wanneer het account toegang heeft tot meerdere tenants of wanneer de verkeerde tenant wordt geopend, log dan expliciet in op de juiste tenant:

```bash
az login --tenant "<tenant-id>"
```

Als de browserlogin op de labpc niet werkt, gebruik dan:

```bash
az login --use-device-code
```

Bekijk de beschikbare subscriptions:

```bash
az account list --output table
```

Selecteer de eigen Azure-subscription op naam of ID en controleer de selectie:

```bash
az account set --subscription "<subscription-id-of-subscription-name>"
az account show --output table
```

Ga pas verder wanneer `az account show` de juiste tenant en subscription toont. Een Entra Global Administrator-rol geeft niet automatisch toegang tot iedere Azure-subscription; de subscription moet ook zichtbaar zijn in de bovenstaande lijst.

Valideer of de Bicep compileert. Bij een geldige template verschijnt een compacte JSON-bevestiging; bij een fout toont de Bicep-compiler de foutmelding en geeft het commando een mislukte exitcode terug:

```bash
if az bicep build --file main.bicep --stdout > /dev/null; then
  printf '{"success":true,"file":"main.bicep"}\n'
else
  printf '{"success":false,"file":"main.bicep"}\n'
  false
fi
```

Wil je ook de volledige gegenereerde ARM-template als JSON bekijken, gebruik dan:

```bash
az bicep build --file main.bicep --stdout
```

Deploy de dev-omgeving:

```bash
az deployment sub create \
  --location westeurope \
  --template-file main.bicep \
  --parameters main.parameters.dev.bicepparam
```

Deploy test of prod door het parameterbestand te wisselen:

```bash
az deployment sub create \
  --location westeurope \
  --template-file main.bicep \
  --parameters main.parameters.test.bicepparam
```

```bash
az deployment sub create \
  --location westeurope \
  --template-file main.bicep \
  --parameters main.parameters.prod.bicepparam
```

### 2. Ervaar Infrastructuurdrift Met What-If

Infrastructuurdrift ontstaat wanneer iemand een gedeployde resource buiten Bicep om wijzigt. In deze oefening verwijdert de tijdelijke beheerder het deployment slot `staging` handmatig, terwijl dit slot nog steeds in de Bicep-code staat.

Stel eerst de namen van de dev-resources in:

```bash
RESOURCE_GROUP_NAME="rg-asr-asrdm-dev-we-001"
WEB_APP_NAME="app-asr-asrdm-dev-we-001"
```

Controleer eerst dat het staging slot bestaat:

```bash
az webapp deployment slot list \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$WEB_APP_NAME" \
  --query "[].{slot:name,state:state}" \
  --output table
```

Simuleer vervolgens de handmatige verwijdering:

```bash
az webapp deployment slot delete \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$WEB_APP_NAME" \
  --slot staging
```

Voer het eerdere `az webapp deployment slot list`-commando opnieuw uit om te controleren dat het slot verdwenen is. De Bicep-code bevat het staging slot nog steeds. Gebruik daarom `what-if` om de actuele Azure-omgeving met de gewenste configuratie te vergelijken:

```bash
az deployment sub what-if \
  --location westeurope \
  --template-file main.bicep \
  --parameters main.parameters.dev.bicepparam
```

Zoek in de uitvoer naar het Web App-slot `staging`. Het ontbrekende slot en de bijbehorende diagnostic settings worden als `Create` weergegeven. `What-if` verandert zelf nog niets.

Herstel daarna de gedeclareerde omgeving met dezelfde Bicep-deployment:

```bash
az deployment sub create \
  --location westeurope \
  --template-file main.bicep \
  --parameters main.parameters.dev.bicepparam
```

Voer het eerdere `az webapp deployment slot list`-commando opnieuw uit. Het slot `staging` hoort nu weer te bestaan. Ongewijzigde resources worden niet opnieuw aangemaakt; de deployment herstelt de resources die ontbreken of afwijken van de Bicep-code.

Je ziet hiermee dat Bicep geen Terraform-statefile nodig heeft om deze drift te vinden: ARM vergelijkt de gewenste template met de actuele configuratie in Azure.

> Verwijder in deze oefening uitsluitend het staging slot en niet de productie-Web App. Eventuele applicatie-inhoud die handmatig in het slot is geplaatst, wordt niet door Bicep hersteld.

### 3. Demonstreer RBAC Als Code

De securitymodule maakt optioneel een Azure RBAC-role-assignment aan op de resource group. De module maakt de Entra ID-groep zelf niet aan. Je maakt daarom eerst een tijdelijke demogroep aan. In deze demo is `principalType` vastgezet op `Group`; een service principal, gebruiker of managed identity werkt hier dus niet.

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

Deploy vervolgens de dev-omgeving met het object-ID van de groep. De Bicep-parameter heet technisch `principalId`, maar bevat hier dus een groeps-ID:

```bash
az deployment sub create \
  --location westeurope \
  --template-file main.bicep \
  --parameters main.parameters.dev.bicepparam \
  --parameters principalId="$GROUP_ID"
```

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

Wat deze demo over Bicep laat zien:

- **RBAC is declaratieve infrastructuur:** toegangsrechten staan naast de resources in broncode en zijn daardoor reviewbaar en herhaalbaar.
- **Least privilege:** de standaardrol is bewust `Reader` en de scope is beperkt tot één resource group.
- **Optionele governance:** de securitymodule wordt alleen uitgevoerd wanneer `principalId` is ingevuld.
- **Idempotency:** de naam van de role-assignment wordt met `guid()` deterministisch opgebouwd. Dezelfde deployment maakt daarom geen dubbele assignment.
- **Herbruikbaarheid:** via `roleDefinitionId` kan hetzelfde patroon ook een andere ingebouwde of custom rol toewijzen.

Meld je eventueel in een privébrowser aan als een testgebruiker uit de groep. Controleer dat deze gebruiker de resources kan bekijken, maar bijvoorbeeld geen resource kan verwijderen. Houd rekening met enkele minuten verwerkingstijd voor nieuwe RBAC-toewijzingen.

De uitvoerder van de Bicep-deployment moet zelf rechten hebben om role-assignments te maken, bijvoorbeeld **Owner** of **User Access Administrator** op de betreffende scope.

> Alleen opnieuw deployen zonder `principalId` verwijdert een bestaande assignment niet bij een incrementele deployment. Verwijder de demo-assignment daarom expliciet:

```bash
az role assignment delete \
  --scope "$SCOPE" \
  --assignee-object-id "$GROUP_ID" \
  --role Reader

az ad group delete --group "$GROUP_ID"
```

## Wat Je Tijdens De Demo Kunt Vertellen

Start bij `main.bicep`. Laat zien dat dit bestand vooral orkestratie doet: resource group aanmaken, standaardnamen bepalen, tags centraal opbouwen en modules aanroepen.

Open daarna de modules:

- `modules/network/vnet.bicep`: standaard netwerkbouwblok met vaste subnets en NSG's.
- `modules/monitoring/logAnalytics.bicep`: gedeelde observability voor logs, metrics en Application Insights.
- `modules/storage/storageAccount.bicep`: secure-by-default dataopslag met public access uit, OAuth-default en private endpoint.
- `modules/webapp/webApp.bicep`: gestandaardiseerde PHP applicatieruntime met managed identity, HTTPS only, Application Insights en een `staging` slot voor CI/CD.
- `modules/security/roleAssignments.bicep`: klein voorbeeld van uitbreidbare governance op resource group scope.

De kernboodschap: teams hoeven niet telkens opnieuw securitykeuzes te maken. Ze consumeren goedgekeurde modules, vullen parameters in en krijgen dezelfde veilige baseline voor dev, test en prod.

Voor het CI/CD-deel kun je tijdens de training handmatig een GitHub Actions workflow koppelen aan de Web App of aan het `staging` slot. De App Service Plan SKU is bewust `P1v3`, omdat Premium tiers deployment slots ondersteunen en deze demo ruimte laat om tot 20 slots te gebruiken. Voor een goedkopere korte demo kun je de SKU tijdelijk verlagen, maar dan verlies je de 20-slot capaciteit.

## Cleanup Commands

Verwijder de dev-omgeving:

```bash
./scripts/cleanup.sh dev
```

Voor test en prod:

```bash
./scripts/cleanup.sh test
./scripts/cleanup.sh prod
```

Omdat deze versie geen Key Vault meer gebruikt, is er geen soft-delete of purge-stap nodig. De cleanup blijft daardoor geschikt voor herhaalde cursusdemo's.
