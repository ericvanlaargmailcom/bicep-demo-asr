# Optioneel Lab – Deployment Stacks

## Doel

In dit optionele lab deploy je de dev-omgeving als een Azure Deployment Stack. Je leert:

- wat een Deployment Stack toevoegt aan een gewone Bicep-deployment;
- hoe Azure bijhoudt welke resources door de stack worden beheerd;
- wat `detachAll`, `deleteResources` en `deleteAll` betekenen;
- hoe een stack een resource verwijdert die niet langer in de gewenste configuratie staat;
- hoe je een volledige omgeving gecontroleerd via de stack opruimt;
- waarom een Deployment Stack niet hetzelfde is als een Terraform-statefile.

Reken op ongeveer 45 tot 60 minuten.

## Deployment Stack Versus Terraform-State

Een Deployment Stack is een Azure-resource die een verzameling beheerde resource-ID's en lifecycle-instellingen bijhoudt. Daardoor kan Azure bepalen wat er met resources moet gebeuren wanneer ze niet langer door de stack worden beheerd of wanneer je de stack verwijdert.

Een Deployment Stack is geen volledige Terraform-statefile. Voor het bekijken van configuratieverschillen en infrastructuurdrift gebruik je bij Bicep nog steeds `az deployment sub what-if`. Deployment Stacks voegen vooral ownership, verwijdergedrag en optionele deny settings toe.

## Voorwaarden

Voer de commando's uit vanuit de hoofdmap van deze repository. Controleer eerst:

```bash
az version
az bicep version
az account show --output table
```

Je account moet op subscriptionniveau resources en Deployment Stacks mogen aanmaken en verwijderen. Voor de optionele RBAC-module zijn daarnaast rechten nodig om role-assignments te maken. In dit lab blijft `principalId` leeg.

> De App Service Plan gebruikt de betaalde SKU `P1v3`. Verwijder de stack aan het einde van het lab om onnodige kosten te voorkomen.

## 1. Begin Met Een Schone Omgeving

Dit lab gebruikt dezelfde resource-namen als de gewone dev-deployment. Verwijder daarom eerst eventuele bestaande cursusomgevingen:

```bash
./scripts/cleanup.sh
```

Controleer dat de dev-resourcegroep niet meer bestaat:

```bash
az group exists \
  --name "rg-asr-asrdm-dev-we-001"
```

De verwachte uitvoer is:

```text
false
```

## 2. Maak Een JSON-Parameterbestand

Deployment Stacks accepteren een ARM-parameterbestand. Zet daarom het bestaande Bicep-parameterbestand om naar JSON:

```bash
az bicep build-params \
  --file main.parameters.dev.bicepparam \
  --outfile /tmp/main.parameters.dev.json
```

Controleer het resultaat:

```bash
sed -n '1,120p' /tmp/main.parameters.dev.json
```

## 3. Valideer De Deployment Stack

Stel eerst een vaste stacknaam in:

```bash
STACK_NAME="stack-asr-asrdm-dev-we-001"
```

Valideer daarna de stack zonder resources te deployen:

```bash
az stack sub validate \
  --name "$STACK_NAME" \
  --location westeurope \
  --template-file main.bicep \
  --parameters /tmp/main.parameters.dev.json \
  --action-on-unmanage deleteAll \
  --deny-settings-mode none
```

In dit lab gebruik je:

- `deleteAll`: verwijder onbeheerde resources én resourcegroepen;
- `none`: voeg geen deny settings toe.

## 4. Deploy De Stack

Maak de Deployment Stack en de dev-omgeving aan:

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

Dit commando gebruikt dezelfde `main.bicep` en modules als de gewone cursusdeployment. Het verschil is dat Azure nu ook een Deployment Stack-resource opslaat die de gedeployde resources beheert.

## 5. Bekijk De Stack En De Beheerde Resources

Toon de beschikbare stacks:

```bash
az stack sub list --output table
```

Bekijk de volledige stackinformatie:

```bash
az stack sub show \
  --name "$STACK_NAME" \
  --output json
```

Open daarnaast in de Azure Portal:

1. Open **Subscriptions** en selecteer de subscription waarin je de stack hebt gedeployd.
2. Selecteer in het linkermenu **Deployment stacks**. Gebruik eventueel het zoekveld bovenaan het menu van de subscription.
3. Open `stack-asr-asrdm-dev-we-001`.
4. Bekijk de beheerde resources.
5. Controleer dat de resourcegroep `rg-asr-asrdm-dev-we-001` onderdeel van de stack is.

> Deployment Stacks verschijnen niet als zelfstandige service in de algemene zoekbalk van de Azure Portal. Je opent ze altijd vanuit de resourcegroep of subscription waarop de stack is aangemaakt.

## 6. Begrijp Action On Unmanage

Een stack ondersteunt drie acties voor resources die niet langer worden beheerd:

| Actie | Gevolg |
|---|---|
| `detachAll` | Resources en resourcegroepen blijven bestaan, maar worden losgekoppeld van de stack. |
| `deleteResources` | Beheerde resources worden verwijderd, maar resourcegroepen blijven bestaan. |
| `deleteAll` | Beheerde resources en beheerde resourcegroepen worden verwijderd. |

Dit lab gebruikt `deleteAll`, omdat `main.bicep` zelf de resourcegroep aanmaakt en de volledige cursusomgeving aan het einde moet worden opgeruimd.

Deployment Stacks ondersteunen ook `denyDelete` en `denyWriteAndDelete`. Daarmee kun je handmatige wijzigingen blokkeren. Deze opties vallen buiten dit lab, omdat ze extra aandacht vereisen voor uitzonderingen en hersteltoegang.

## 7. Aha-Moment: Laat De Stack Een Resource Verwijderen

Bij een gewone incrementele Bicep-deployment blijft een bestaande resource meestal staan wanneer die niet langer in de template voorkomt. Een Deployment Stack kan zo'n resource wel verwijderen, omdat de stack weet dat de resource eerder door hem werd beheerd.

In deze oefening zet je het staging slot via de parameter `deployStagingSlot` uit. Daardoor komt het slot niet meer voor in de gewenste configuratie van de stack.

Stel eerst de namen van de resources in en controleer dat het slot bestaat:

```bash
RESOURCE_GROUP_NAME="rg-asr-asrdm-dev-we-001"
WEB_APP_NAME="app-asr-asrdm-dev-we-001"

az webapp deployment slot list \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$WEB_APP_NAME" \
  --query "[].{slot:name,state:state}" \
  --output table
```

Werk daarna dezelfde stack bij, maar zet `deployStagingSlot` op `false`:

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

Controleer opnieuw de deployment slots:

```bash
az webapp deployment slot list \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$WEB_APP_NAME" \
  --query "[].{slot:name,state:state}" \
  --output table
```

Het slot `staging` is nu verwijderd. Ook de diagnostic settings van het slot worden niet langer beheerd en zijn verwijderd.

Dit is het belangrijkste aha-moment:

> De stack wist dat het staging slot eerder door hem werd beheerd. Zodra het slot niet meer in de gewenste configuratie stond, heeft `deleteAll` het daadwerkelijk uit Azure verwijderd.

Herstel het slot door dezelfde stack opnieuw bij te werken met `deployStagingSlot=true`:

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

Controleer dat het staging slot opnieuw bestaat:

```bash
az webapp deployment slot list \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$WEB_APP_NAME" \
  --query "[].{slot:name,state:state}" \
  --output table
```

## 8. Aha-Moment: Verwijder De Volledige Omgeving Met Eén Opdracht

> Dit commando verwijdert de Deployment Stack, de dev-resourcegroep en de resources in die resourcegroep.

Bekijk eventueel nog één keer welke resources door de stack worden beheerd:

```bash
az stack sub show \
  --name "$STACK_NAME" \
  --query "resources[].{resource:id,status:status}" \
  --output table
```

Verwijder daarna de volledige omgeving met één opdracht:

```bash
az stack sub delete \
  --name "$STACK_NAME" \
  --action-on-unmanage deleteAll \
  --yes
```

Controleer daarna dat zowel de stack als de resourcegroep verdwenen zijn:

```bash
az stack sub list --output table

az group exists \
  --name "rg-asr-asrdm-dev-we-001"
```

De tweede opdracht hoort `false` terug te geven.

Het tweede aha-moment is dat je niet ieder onderdeel afzonderlijk hoeft te verwijderen. De stack gebruikt zijn lijst met beheerde resources en het ingestelde `deleteAll`-gedrag om de volledige omgeving op te ruimen.

## Wat Je Uit Dit Lab Meeneemt

- Gewone Bicep-deployments zijn geschikt voor declaratieve creatie, updates en driftherstel met `what-if`.
- Deployment Stacks voegen beheergrenzen en lifecycle-instellingen toe.
- Azure kent via de stack de beheerde resource-ID's, maar bewaart geen volledige Terraform-achtige statefile.
- `action-on-unmanage` bepaalt of Azure resources loskoppelt of verwijdert.
- Een stack-update kan resources verwijderen die niet langer in de gewenste configuratie staan.
- `deleteAll` maakt gecontroleerde cleanup van deze volledige cursusomgeving mogelijk.

## Problemen Oplossen

### De Stack Bestaat Al

`az stack sub create` werkt een bestaande stack met dezelfde naam bij. Wil je opnieuw beginnen, verwijder dan eerst de bestaande stack met de juiste `action-on-unmanage`.

### De Resourcegroep Bestaat Nog

Controleer of een eerdere gewone Bicep-deployment dezelfde resourcegroep heeft gemaakt. Voer `./scripts/cleanup.sh` uit voordat je de stack opnieuw maakt.

### Onvoldoende Rechten

Controleer de geselecteerde subscription met:

```bash
az account show --output table
```

Vraag je docent of beheerder om te controleren of je account voldoende rechten heeft op de subscription.

## Meer Informatie

- [Microsoft Learn: Deployment Stacks met Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deployment-stacks)
- [Azure CLI: az stack sub](https://learn.microsoft.com/cli/azure/stack/sub)
- [Microsoft Learn: ARM/Bicep what-if](https://learn.microsoft.com/azure/azure-resource-manager/templates/deploy-what-if)
