# Secure Azure Landing Zone Mini-demo

Deze repository bevat een compacte klantdemo voor ASR over herbruikbare Azure Bicep modules. De demo laat zien hoe je met een klein aantal gestandaardiseerde modules snel een veilige applicatieomgeving kunt uitrollen met consistente naming, tags, monitoring en private connectivity.

De insteek is bewust compact: geen enterprise landing zone met tientallen lagen, maar een realistische mini-landing-zone die in 20 tot 30 minuten goed uit te leggen is.

## Doel Van De Demo

Met deze demo kun je laten zien hoe een financiële organisatie security-by-default en herhaalbaarheid kan combineren:

- Eén `main.bicep` op subscription scope maakt de resource group en orkestreert de modules.
- Herbruikbare modules leveren netwerk, storage, Key Vault, monitoring en optionele RBAC.
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
- Storage account met:
  - publieke netwerktoegang uit
  - blob public access uit
  - shared key access uit
  - OAuth default authentication aan
  - Azure Files file service
  - private endpoint voor `file`
  - private DNS zone `privatelink.file.core.windows.net`
  - diagnostic settings naar Log Analytics
- Key Vault met:
  - RBAC authorization
  - soft delete met 7 dagen retention
  - purge protection uitgeschakeld voor demo-cleanup
  - publieke netwerktoegang uit
  - private endpoint
  - private DNS zone `privatelink.vaultcore.azure.net`
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
└─ modules/
   ├─ network/
   │  └─ vnet.bicep
   ├─ storage/
   │  └─ storageAccount.bicep
   ├─ keyvault/
   │  └─ keyVault.bicep
   ├─ monitoring/
   │  └─ logAnalytics.bicep
   └─ security/
      └─ roleAssignments.bicep
```

## Parameters

De hoofdtemplate gebruikt deze parameters:

- `environment`: `dev`, `test` of `prod`
- `applicationName`: korte applicatienaam, maximaal 5 tekens in deze demo vanwege de Key Vault naamlimiet
- `location`: vastgezet op `westeurope`
- `owner`: eigenaar voor governance
- `costCenter`: kostenplaats voor chargeback/showback
- `principalId`: optioneel object ID voor de voorbeeld-role-assignment
- `roleDefinitionId`: optioneel aanpasbare role definition, standaard `Reader`

De parameterbestanden gebruiken het Bicep-native `.bicepparam` formaat met dummywaarden. Vul `principalId` alleen met een echte Entra ID object ID als je de RBAC-module tijdens de demo wilt activeren.

## Deployment Commands

Log in en kies de juiste subscription:

```bash
az login
az account set --subscription "<subscription-id>"
```

Valideer of de Bicep compileert:

```bash
az bicep build --file main.bicep
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
- `modules/keyvault/keyVault.bicep`: secrets management met RBAC, soft delete, demo-vriendelijke cleanup en private endpoint.
- `modules/security/roleAssignments.bicep`: klein voorbeeld van uitbreidbare governance op resource group scope.

De kernboodschap: teams hoeven niet telkens opnieuw securitykeuzes te maken. Ze consumeren goedgekeurde modules, vullen parameters in en krijgen dezelfde veilige baseline voor dev, test en prod.

## Cleanup Commands

Verwijder de demo-resource-groups per omgeving:

```bash
az group delete --name rg-asr-claim-dev-we-001 --yes --no-wait
az group delete --name rg-asr-claim-test-we-001 --yes --no-wait
az group delete --name rg-asr-claim-prod-we-001 --yes --no-wait
```

Let op: Key Vault soft delete staat verplicht aan bij moderne Key Vaults. In deze demo staat purge protection uit en is de retention 7 dagen, zodat je na cleanup eventueel handmatig kunt purgen en dezelfde naam sneller opnieuw kunt gebruiken. In productie zet je purge protection normaal gesproken wel aan.
