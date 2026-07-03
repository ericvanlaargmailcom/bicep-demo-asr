# Secure Azure Landing Zone Demo

Deze repository bevat een compacte klantdemo voor ASR over herbruikbare Azure Bicep modules. De demo laat zien hoe je met een klein aantal gestandaardiseerde modules snel een veilige applicatieomgeving kunt uitrollen met consistente naming, tags, monitoring en private connectivity.

De insteek is bewust compact: geen enterprise landing zone met tientallen lagen, maar een realistische mini-landing-zone die in 20 tot 30 minuten goed uit te leggen is.

> **Let op: deze demo veroorzaakt werkelijke Azure-kosten.** Elke omgeving bevat onder andere een betaald `P1v3` App Service Plan. Dev, test en prod samen betekenen drie betaalde plannen. Ben je klaar met oefenen of neem je een langere pauze? Voer dan direct `./scripts/cleanup.sh` uit en controleer dat er niets is achtergebleven.

## Doel Van De Demo

In deze demo ontdek je hoe een financiële organisatie security-by-default en herhaalbaarheid kan combineren:

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
- `deployStagingSlot`: bepaalt of het staging slot wordt uitgerold, standaard `true`

De parameterbestanden gebruiken het Bicep-native `.bicepparam` formaat met dummywaarden. Hoewel Azure de technische parameternaam `principalId` gebruikt, verwacht deze demo specifiek het object-ID van een **Entra ID-groep** en niet van een service principal, gebruiker of managed identity.

## Voorbereiding Op Een Schone Windows-Labpc

De labpc heeft voor deze voorbereiding internettoegang nodig. Gebruik **PowerShell** voor de eerste installatie met Chocolatey, of gebruik de handmatige installers. Gebruik daarna **Git Bash** voor alle Bicep-, Git- en Azure CLI-commando's. Git Bash wordt automatisch met Git for Windows geïnstalleerd.

### 1. Installeer Visual Studio Code, Git en Azure CLI

Kies één van de onderstaande installatieroutes. Chocolatey is standaard aanwezig op de labpc's en is daarom de aanbevolen route. Gebruik de handmatige route wanneer Chocolatey niet werkt of door organisatiebeleid is geblokkeerd.

#### Route A: Installatie Met Chocolatey

Open PowerShell als administrator en controleer eerst of Chocolatey beschikbaar is:

```powershell
choco --version
```

Installeer Visual Studio Code, Git en Azure CLI:

```powershell
choco install vscode git azure-cli -y
```

Wanneer de installatie is voltooid, voer dan geen volgende labcommando's meer uit in PowerShell. **Sluit PowerShell volledig af**, sla route B over en ga verder bij **Start Git Bash En Controleer De Installatie**.

Ga verder met route B wanneer Chocolatey niet wordt herkend of de installatie wordt geblokkeerd.

#### Route B: Handmatige Installatie

Download en installeer de volgende pakketten via de officiële websites:

1. Download [Visual Studio Code voor Windows](https://code.visualstudio.com/download).
   - Kies op een normale 64-bits Windows-labpc de **Windows User Installer x64**.
   - Selecteer tijdens de installatie de opties om VS Code aan `PATH` toe te voegen en **Open with Code** beschikbaar te maken.
2. Download [Git voor Windows](https://git-scm.com/install/windows).
   - Gebruik de 64-bits installer en accepteer de standaardinstellingen.
   - Git Bash wordt hiermee automatisch geïnstalleerd.
3. Download de [Azure CLI MSI voor 64-bits Windows](https://aka.ms/installazurecliwindowsx64).
   - Start het gedownloade MSI-bestand en doorloop de installatie.
   - Bevestig de Windows-melding wanneer toestemming wordt gevraagd om wijzigingen aan te brengen.

Gebruik de algemene documentatie wanneer een directe download niet werkt:

- [Azure CLI voor Windows](https://learn.microsoft.com/cli/azure/install-azure-cli-windows)

#### Start Git Bash En Controleer De Installatie

Voer na route A of B de volgende stappen in deze volgorde uit:

1. Sluit alle geopende PowerShell-, opdrachtprompt- en Git Bash-vensters volledig af.
2. Open **Git Bash** vanuit het Windows Startmenu. Hierdoor worden de nieuwe commando's via het bijgewerkte `PATH` gevonden.
3. Controleer vanuit **Git Bash** of Visual Studio Code, Git en Azure CLI correct zijn geïnstalleerd:

```bash
code --version
git --version
az version
```

Wanneer een commando niet wordt herkend, herstart dan eerst de labpc en voer de controle opnieuw uit. Als een installer door organisatiebeleid of ontbrekende administratorrechten wordt geblokkeerd, neem dan contact op met de trainer of werkplekbeheerder.

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

Hierdoor wordt een nieuwe map met de naam `bicep-demo-asr` aangemaakt. De repository is openbaar; voor het klonen is geen GitHub-account of aanmelding nodig. Verschijnt er toch een aanmeldvenster, annuleer dit dan en controleer of je exact de bovenstaande HTTPS-URL hebt gebruikt.

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

> **Stop je hier of ga je later verder?** Ruim dev, test en prod nu op met `./scripts/cleanup.sh`. De omgevingen blijven kosten genereren zolang de resources bestaan.

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

Simuleer vervolgens via de Azure Portal een handmatige wijziging buiten Bicep om:

1. Open in de Azure Portal de resourcegroep `rg-asr-asrdm-dev-we-001`.
2. Open de Web App `app-asr-asrdm-dev-we-001`.
3. Selecteer in het menu **Deployment > Deployment slots**.
4. Selecteer het slot **staging**.
5. Kies **Delete** en bevestig de verwijdering.

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

### 3. Verwijder Een Resource Uit De Gewenste Configuratie

De vorige oefening liet zien dat gewone Bicep een ontbrekende resource kan herstellen zolang die resource nog in de gewenste configuratie staat. Nu draai je het scenario om: het staging slot bestaat nog in Azure, maar je haalt het uit de gewenste configuratie.

De parameter `deployStagingSlot=false` zorgt ervoor dat de conditionele declaraties van het slot en zijn diagnostic settings niet in de gegenereerde ARM-template komen. Hiermee simuleer je dat de resources uit de Bicep-code zijn verwijderd, zonder dat je het modulebestand handmatig hoeft te wijzigen.

Bekijk eerst met een gewone incrementele deployment wat Azure zou veranderen:

```bash
az deployment sub what-if \
  --location westeurope \
  --template-file main.bicep \
  --parameters main.parameters.dev.bicepparam \
  --parameters deployStagingSlot=false
```

Het staging slot wordt niet als `Delete` weergegeven. Voer daarna dezelfde configuratie daadwerkelijk uit:

```bash
az deployment sub create \
  --location westeurope \
  --template-file main.bicep \
  --parameters main.parameters.dev.bicepparam \
  --parameters deployStagingSlot=false
```

Controleer opnieuw:

```bash
az webapp deployment slot list \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$WEB_APP_NAME" \
  --query "[].{slot:name,state:state}" \
  --output table
```

Het slot bestaat nog steeds. Gewone Bicep-deployments gebruiken standaard de incrementele modus: Azure maakt en wijzigt gedeclareerde resources, maar verwijdert niet automatisch een bestaande resource die uit de nieuwe template is verdwenen.

Dit is de beperking die de handmatige drift-oefening niet liet zien:

- **Resource ontbreekt in Azure, maar staat nog in Bicep:** What-If toont `Create` en een deployment herstelt de resource.
- **Resource bestaat in Azure, maar staat niet meer in Bicep:** een gewone incrementele deployment laat de resource staan.

### 4. Ruim De Gewone Deployment Op

Verwijder de gewone Bicep-omgeving voordat je dezelfde omgeving als Deployment Stack maakt. Zo begint de stack met een schone omgeving en is duidelijk welke resources door de stack worden beheerd:

```bash
./scripts/cleanup.sh
```

Controleer dat de dev-resourcegroep verdwenen is:

```bash
az group exists \
  --name "$RESOURCE_GROUP_NAME"
```

De verwachte uitvoer is `false`.

### 5. Deploy De Omgeving Als Deployment Stack

Een Deployment Stack voegt resource-ownership en lifecycle-instellingen toe aan een gewone Bicep-deployment. Azure houdt bij welke resource-ID's door de stack worden beheerd.

Deployment Stacks vereisen Azure CLI 2.61.0 of nieuwer. Controleer de geïnstalleerde versie:

```bash
az version
```

Zet het Bicep-parameterbestand om naar een ARM JSON-parameterbestand:

```bash
az bicep build-params \
  --file main.parameters.dev.bicepparam \
  --outfile /tmp/main.parameters.dev.json
```

Stel een vaste stacknaam in:

```bash
STACK_NAME="stack-asr-asrdm-dev-we-001"
```

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

Bekijk de stack en zijn beheerde resources:

```bash
az stack sub show \
  --name "$STACK_NAME" \
  --output json
```

Controleer ook dat het staging slot opnieuw bestaat:

```bash
az webapp deployment slot list \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$WEB_APP_NAME" \
  --query "[].{slot:name,state:state}" \
  --output table
```

### 6. Laat De Deployment Stack Het Slot Verwijderen

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

Controleer de deployment slots:

```bash
az webapp deployment slot list \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$WEB_APP_NAME" \
  --query "[].{slot:name,state:state}" \
  --output table
```

Het slot `staging` is nu verwijderd. Ook de diagnostic settings van het slot worden niet langer beheerd en zijn verwijderd.

Het verschil met stap 3 is resource-ownership:

- De gewone deployment wist niet dat het bestaande slot bij een eerdere template hoorde en liet het daarom staan.
- De Deployment Stack wist dat het slot eerder door deze stack werd beheerd. Toen het slot uit de gewenste configuratie verdween, bepaalde `deleteAll` dat de onbeheerd geraakte resource moest worden verwijderd.

Deployment Stacks bewaren hiermee een vorm van geheugen over **ownership**, maar geen volledige Terraform-statefile met alle resource-eigenschappen en providerinformatie.

> Deployment Stacks ondersteunen momenteel geen What-If. Controleer daarom vóór een stack-update zorgvuldig de template, parameters, lijst met beheerde resources en de ingestelde waarde voor `action-on-unmanage`.

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

### 7. Begrijp Complete Mode, Deployment Stacks En Terraform

Complete Mode is geen onderdeel van Deployment Stacks. Het is een oudere deploymentmodus van ARM waarbij resources in de doel-resourcegroep kunnen worden verwijderd wanneer ze niet in de template staan.

Het verschil zit in de selectie van resources:

| Mechanisme | Welke bestaande resources kunnen worden verwijderd? | Kent ownership? |
|---|---|---|
| Gewone Bicep, incremental | Resources die niet meer in de template staan blijven bestaan. | Nee |
| ARM Complete Mode | Resources in de doel-resourcegroep die niet in de template staan. | Nee |
| Deployment Stack | Resources die eerder door de stack werden beheerd en nu onbeheerd raken. | Ja |

Complete Mode kan daardoor ook een handmatig aangemaakte of door een ander proces beheerde resource verwijderen wanneer die toevallig in dezelfde resourcegroep staat maar niet in de template voorkomt. Deployment Stacks werken gerichter vanuit hun lijst met beheerde resources.

Microsoft raadt voor verwijderingen met Bicep Deployment Stacks aan. Complete Mode wordt geleidelijk uitgefaseerd, werkt alleen op resource group deployments en wordt daarom in deze cursus niet uitgevoerd.

Terraform gebruikt een statefile en onthoudt daarmee uitgebreider welke resources en eigenschappen het beheert. Conceptueel:

- **Gewone Bicep:** gewenste template tegenover de actuele Azure-omgeving.
- **Bicep met Deployment Stack:** gewenste template plus ownership van beheerde Azure-resources.
- **Terraform:** gewenste configuratie plus een uitgebreide state over beheerde resources.

Het praktische aha-moment blijft hetzelfde: wanneer een eerder beheerde resource uit de code verdwijnt, kan een Deployment Stack die gericht verwijderen; een gewone incrementele Bicep-deployment doet dat niet.

### 8. Verwijder De Deployment Stack En Omgeving

Bekijk eventueel nog één keer welke resources worden beheerd:

```bash
az stack sub show \
  --name "$STACK_NAME" \
  --query "resources[].{resource:id,status:status}" \
  --output table
```

Verwijder daarna de stack, de beheerde resourcegroep en de resources:

```bash
az stack sub delete \
  --name "$STACK_NAME" \
  --action-on-unmanage deleteAll \
  --yes
```

Controleer dat de stack en resourcegroep verdwenen zijn:

```bash
az stack sub list --output table
az group exists --name "$RESOURCE_GROUP_NAME"
```

De tweede opdracht hoort `false` terug te geven.

### 9. Demonstreer RBAC Als Code

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

> **Klaar met de oefeningen?** Voer nu `./scripts/cleanup.sh` uit. Hiermee verwijder je de bekende Deployment Stacks en de resourcegroepen van dev, test en prod.

## Wat Je Uit De Architectuur Kunt Afleiden

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

Ben je klaar met ontdekken of neem je een langere pauze, voer dan altijd het cleanup-script uit:

```bash
./scripts/cleanup.sh
```

Het script verwijdert eerst bekende Deployment Stacks met `deleteAll`. Daarna verwijdert het eventuele resterende resourcegroepen van dev, test en prod parallel. Tot slot controleert het of er nog cursus-stacks of -resourcegroepen bestaan.

Voor een afwijkende `applicationName` geef je de naam als argument mee:

```bash
./scripts/cleanup.sh "<applicationName>"
```

Omdat deze versie geen Key Vault meer gebruikt, is er geen soft-delete of purge-stap nodig. De cleanup blijft daardoor geschikt voor herhaalde cursusdemo's.

## Verdieping – Deployment Stacks

### Action On Unmanage

`action-on-unmanage` bepaalt wat Azure doet wanneer een resource door een stack-update of het verwijderen van de stack niet langer wordt beheerd:

| Actie | Gevolg |
|---|---|
| `detachAll` | Resources en resourcegroepen blijven bestaan, maar worden losgekoppeld van de stack. |
| `deleteResources` | Beheerde resources worden verwijderd, maar beheerde resourcegroepen blijven bestaan. |
| `deleteAll` | Beheerde resources en beheerde resourcegroepen worden verwijderd. |

Gebruik `deleteAll` alleen wanneer de stack eigenaar is van de volledige resourcegroep en alles daarin veilig verwijderd mag worden. Controleer vóór iedere update of delete de beheerde resources:

```bash
az stack sub show \
  --name "$STACK_NAME" \
  --query "resources[].{resource:id,status:status}" \
  --output table
```

### Deny Settings

Deployment Stacks kunnen handmatige control-planewijzigingen aan beheerde resources beperken:

- `none`: geen extra blokkade;
- `denyDelete`: blokkade tegen verwijderen;
- `denyWriteAndDelete`: blokkade tegen wijzigen en verwijderen.

Deny settings zijn krachtig en kunnen ook beheerders hinderen tijdens herstel. Gebruik ze pas nadat uitzonderingen, beheerrollen en break-glass-toegang zijn ontworpen. Deze cursus gebruikt daarom `--deny-settings-mode none`.

### Resources Loskoppelen In Plaats Van Verwijderen

Wil je de stack verwijderen maar de omgeving behouden, gebruik dan:

```bash
az stack sub delete \
  --name "$STACK_NAME" \
  --action-on-unmanage detachAll \
  --yes
```

De resources blijven dan in Azure bestaan, maar de verwijderde stack houdt hun ownership niet langer bij. Je kunt ze later opnieuw onder beheer brengen door een stack met de juiste template bij te werken of te maken. Begin voor het cursuslab steeds met een schone omgeving, zodat duidelijk zichtbaar blijft welke stack de resources beheert.

### Problemen Oplossen

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

### Meer Informatie

- [Microsoft Learn: Deployment Stacks met Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deployment-stacks)
- [Microsoft Learn: ARM-deploymentmodi](https://learn.microsoft.com/azure/azure-resource-manager/templates/deployment-modes)
- [Azure CLI: az stack sub](https://learn.microsoft.com/cli/azure/stack/sub)
- [Microsoft Learn: ARM/Bicep What-If](https://learn.microsoft.com/azure/azure-resource-manager/templates/deploy-what-if)
