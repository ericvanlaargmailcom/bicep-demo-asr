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
- `principalId`: optioneel object ID voor de voorbeeld-role-assignment
- `roleDefinitionId`: optioneel aanpasbare role definition, standaard `Reader`

De parameterbestanden gebruiken het Bicep-native `.bicepparam` formaat met dummywaarden. Vul `principalId` alleen met een echte Entra ID object ID als je de RBAC-module tijdens de demo wilt activeren.

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

Voor een demo met RBAC kun je tijdelijk een principal meegeven:

```bash
az deployment sub create \
  --location westeurope \
  --template-file main.bicep \
  --parameters main.parameters.dev.bicepparam \
  --parameters principalId="<entra-object-id>"
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
