# Průběh volání

## Ukládání

```text
WriteListFile    ← jediný zápis na disk
   ↑
SaveListAs       ← dialog na jméno
   ↑
DoSave           ← bez souboru → SaveListAs
   ↑
AskSaveChanges   ← „Uložit změny?“
```

## Otevření a nový seznam

```text
LoadFromBinary   ← pořadí Y/X podle přípony
   ↑
OpenList         ← AskSaveChanges → dialog → načtení
```

```text
WriteListFile    ← prázdný seznam hned na disk
   ↑
CreateNewList    ← AskSaveChanges → dialog → Clear
```

## Import a export

```text
AskExistingPoint ← existující bod: ponechat, nový, průměr, nové číslo
   ↑
DoImport         ← nejdřív ReadFromTXT / ReadFromCSV (jen čte), pak přidává
```

```text
ExportText       ← seřazeno podle čísla
   ↑
DoExport         ← jméno seznamu + .txt / .csv
```

## Tabulka

```text
AddOrUpdatePoint ← změna hned v seznamu
   ↑
StoreRow         ← nový bod: KK a popis z lišty
   ↑
NumberCommitted  ← předčíslí, přečíslování
   ↑
GridCellCommitted
```

```text
RemovePoint
   ↑
DeleteSelected   ← jeden dotaz na všechny označené
   ↑
Delete na čísle
```

## Návrat do okna

```text
RefreshGrid      ← jen po změně z výpočtu
   ↑
FormActivate
```
