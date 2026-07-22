# PROJECT MAP — GeoSoft

Aktualizováno: **2. června 2026** — kompletní mapa po refaktoringu + opravy validace, kódování a migrace AddPoint.

---

## 1) Přehled projektu

**GeoSoft** je desktopová VCL aplikace pro geodetické výpočty. Umožňuje:
- Správu seznamu souřadnic (slovník bodů)
- Výpočet polohy bodů polární metodou
- Výpočet polohy bodů ortogonální metodou
- Transformaci souřadnicových systémů

**Technologie:** Delphi / Pascal, VCL, Win32  
**Vstupní bod:** `src/GUI/GeoSoft.dpr`

---

## 2) Adresářová struktura

```
GeoSoft/
├── GeoComponents/          reusable komponentový balíček (nezávislý na src/)
│   ├── GeoGrid.pas
│   ├── GeoColumnValidation.pas
│   ├── GeoFieldsDef.pas
│   ├── GeoFieldsGrid.pas
│   ├── GeoPointsGrid.pas
│   ├── MyGrid.pas
│   ├── GeoGridReg.pas
│   ├── GeoComponentsR.dpk/.dproj
│   └── test/               testovací VCL projekt pro komponenty
│
├── src/
│   ├── DataStructures/     datové modely geodetické domény
│   │   ├── Point.pas
│   │   ├── PointsUtils.pas
│   │   ├── PointsUtilsSingleton.pas
│   │   ├── GeoRow.pas
│   │   └── GeoDataFrame.pas
│   │
│   ├── GeoAlgorithms/      výpočetní algoritmy v2 (instanční design)
│   │   ├── GeoAlgorithmBase.pas
│   │   ├── GeoAlgorithmPolar.pas
│   │   ├── GeoAlgorithmPolar2.pas
│   │   ├── GeoAlgorithmOrthogonal.pas
│   │   ├── GeoAlgorithmTransformBase.pas
│   │   ├── GeoAlgorithmTransformSimilarity.pas
│   │   ├── GeoAlgorithmTransformCongruent.pas
│   │   └── GeoAlgorithmTransformAffine.pas
│   │
│   ├── Utils/              pomocné utility + legacy algoritmy v1
│   │   ├── ValidationUtils.pas
│   │   ├── InputFilterUtils.pas
│   │   ├── StringGridValidationUtils.pas
│   │   ├── PointPrefixState.pas
│   │   ├── GeoAlgorithmBase.pas       ← legacy v1
│   │   ├── GeoAlgorithmPolar.pas      ← legacy v1
│   │   └── GeoAlgorithmOrthogonal.pas ← legacy v1
│   │
│   ├── GUI/                VCL formuláře
│   │   ├── GeoSoft.dpr/.dproj
│   │   ├── MainForm.pas/.dfm
│   │   ├── PointsManagement.pas/.dfm
│   │   ├── AddPoint.pas/.dfm
│   │   ├── PolarMethod.pas/.dfm
│   │   ├── OrthogonalMethod.pas/.dfm
│   │   ├── ParcelArea.pas/.dfm
│   │   ├── Transformation.pas/.dfm
│   │   ├── CheckMeasurement.pas/.dfm
│   │   ├── TestFieldGrid.pas/.dfm     ← vývojová forma (Components)
│   │   └── Unit5.pas/.dfm             ← vývojová forma (GeoComponents)
│   │
│   ├── Components/         ⚠ DEPRECATED — bude nahrazeno GeoComponents
│   │   ├── MyStringGrid.pas
│   │   ├── MyFieldsStringGrid.pas
│   │   ├── ColumnValidation.pas
│   │   ├── GeoFieldColumn.pas
│   │   └── MyStringGridReg.pas
│   │
│   └── Packages/           ⚠ DEPRECATED — packages pro Components
│       ├── GeoSoftComponentsR.dpk/.dproj
│       └── dclusr.dpk/.dproj
│
├── tests/
│   ├── Algorithms/         konzolové testy algoritmů
│   │   ├── PolarTest.dpr/.dproj
│   │   ├── PolarTest2.dpr/.dproj
│   │   ├── OrthogonalTest.dpr/.dproj
│   │   ├── TransformTest.dpr/.dproj
│   │   ├── TransformTestTXT.dpr/.dproj
│   │   └── TestReadTXT.dpr/.dproj
│   ├── Console/
│   │   └── GeoSoftConsole.dpr/.dproj  konzolová varianta aplikace
│   └── DataModel/
│       ├── TestGeoRow.dpr/.dproj
│       └── TestGeoDataFrame.dpr/.dproj
│
├── icons/
│   └── ikona.ico                      ikona aplikace (linkována přes .res)
├── .gitignore
├── README.md
└── PROJECT_MAP.md
```

---

## 3) Datové modely (src/DataStructures/)

### `Point.pas` — TPoint
Základní geodetický bod.
```pascal
TPoint = record
  PointNumber: Integer;   // 1 .. 999999999999999
  X, Y, Z: Double;        // souřadnice
  Quality: Integer;       // 0–8
  Description: string;
end;
```
- Dva konstruktory: 3D (X,Y,Z) a 2D (Z=0.0 default)
- Všechna pole validována přes `TValidationUtils` při konstruktu
- Pointer type `PPoint` deklarován ale nepoužíván

### `PointsUtilsSingleton.pas` — TPointDictionary (singleton)
Centrální úložiště bodů pro celou GUI aplikaci.
- `FPointDict: TDictionary<Integer, TPoint>` — in-memory slovník
- `GetInstance()` — singleton přístup
- **`AddPoint()`** — přidá bod; vyhodí exception pokud číslo existuje
- **`AddOrUpdatePoint()`** — přidá nebo přepíše bez exception *(přidáno v refaktoringu)*
- `UpdatePoint()` — přepíše existující; exception pokud neexistuje
- `PointExists()`, `GetPoint()`, `RemovePoint()`, `GetPointCount()`
- Import/Export: TXT (tab), CSV (středník), Binary (raw TFileStream)
- Všechny importy volají `CheckFileError` před čtením

### `PointsUtils.pas` — TPointDictionary (nesingleton)
Stejné API jako singleton verze, ale bez `GetInstance`.  
Používán pouze konzolové/testovací projekty kde globální stav nechceš.

### `GeoRow.pas` — TGeoRow
Řádek geodetického měření (18 polí).
```
Uloha, CB, X, Y, Z, Xm, Ym, Zm, TypS, SH, SS, VS, VC, HZ, Zuhel, PolarD, PolarK, Poznamka
```
- `TGeoField` enum, `TGeoFields` set
- `ClearGeoRow()`, `PrintGeoRow()`, `SaveRow()`, `LoadRow()` (typed file I/O)
- ⚠ Duplicitní enum s `GeoComponents/GeoFieldsDef.pas` — musí být ručně synchronní

### `GeoDataFrame.pas` — TGeoDataFrame
Tabulkový kontejner nad `TGeoRowArray`.
- Dynamická alokace s capacity doublingem
- 4 konstruktory: prázdný, s fields, z CSV StringList, ze souboru
- `ToCSV()`, `FromCSV()` — podporuje quoted fields a embedded separátory
- `SaveToFile()`, `LoadFromFile()` — binární formát, field maska uložena v header řádku

---

## 4) Utility (src/Utils/)

### `ValidationUtils.pas` — TValidationUtils
Statické validační metody, žádné závislosti na VCL.
- `ValidatePointNumber`: 0 < n ≤ 999999999999999
- `ValidateCoordinate`: rejectuje NaN a Infinity, vrací 0.0 při selhání
- `ValidateQuality`: enforces 0–8, vrací 0 při selhání
- `ValidateDescription`: passthrough (žádné omezení)

### `InputFilterUtils.pas`
Keypress filtry pro grid sloupce (procedure-based callbacks).
- `FilterPointNumber`: jen číslice + backspace
- `FilterCoordinate`: číslice + `+-*/()` + decimal separator
- `FilterQuality`: jen 0–8 + backspace, max 1 znak
- `FilterDescription`: vše kromě control chars (kromě backspace)
- Všechny pouštějí Ctrl zkratky (Ctrl+C, Ctrl+V, Ctrl+X, Ctrl+A)

### `StringGridValidationUtils.pas`
Validační helpery specifické pro gridy + výraz evaluátor.
- `EvaluateExpression()` — COM/OLE volání `MSScriptControl.ScriptControl` (VBScript)
  - Normalizuje čárky na tečky, vrací Double
  - ⚠ Závislost na Windows COM (křehké na 64bit)
- `ValidatePointNumber`, `ValidateCoordinates`, `ValidateQualityCode`, `HandleBackspace`

### `PointPrefixState.pas`
Globální stav prefixu čísla bodu. Má závislost na VCL (`StdCtrls`).
- `TPointPrefixState`: KU (6 číslic), ZPMZ (5 číslic), KK (kvalita), Popis
- `GPointPrefix` — globální instance, inicializována v `initialization`
- `BuildPointId()` — sestaví 15místné číslo: KU + ZPMZ + vlastní číslo (max 4 číslice)
- `LoadPrefixToCombos()`, `SavePrefixFromCombos()` — sync s TComboBox
- `NormalizeNumericPrefix()` — padding nulami na pevnou šířku

### Legacy algoritmy v1 (Utils/GeoAlgorithm*.pas)
Tři soubory jsou záměrně odlišné verze od `src/GeoAlgorithms/`:
- **v1 (Utils)**: statické třídní metody a property (`class var Scale`, `class function Calculate`)
- **v2 (GeoAlgorithms)**: instanční metody, konstruktory, závislost na `GeoDataFrame`
- ⚠ v1 verze dočasně nutné protože GUI (`ParcelArea`, `OrthogonalMethod`) je stále používá
- Budou odstraněny až po migraci GUI na GeoComponents + v2 algoritmy

---

## 5) Algoritmy (src/GeoAlgorithms/)

Všechny v2 — instanční design, připravené na dědičnost.

### `GeoAlgorithmBase.pas`
```pascal
TAlgorithm = class abstract
  FScale: Double;           // instanční (ne class var)
  constructor Create;       // Scale := 1.0
  function Calculate(const InputPoints: TPointsArray): TPointsArray; virtual; abstract;
end;
```
Závisí na `Point` a `GeoDataFrame`.

### `GeoAlgorithmPolar.pas`
`TPolarMethodAlgorithm` — polární metoda.
- Instanční `FStation: TPoint`, `FOrientations: TOrientations`
- Vstup: pole orientačních bodů s naměřenými směry ψ [gon]
- Výpočet: střední orientační posun → X, Y každého podrobného bodu z úhlu + délky

### `GeoAlgorithmPolar2.pas`
`TPolarMethodAlgorithm2` — polární metoda nad `TGeoDataFrame`.
- `FStationFrame`, `FOrientationFrame`, `FPointsFrame: TGeoDataFrame`
- ArcTan2 pro výpočet orientace (správně řeší všechny kvadranty)
- `RequireReady()` ověří všechny vstupní framy před výpočtem

### `GeoAlgorithmOrthogonal.pas`
`TOrthogonalMethodAlgorithm` — ortogonální metoda.
- Instanční `FStartPoint` (P), `FEndPoint` (K)
- Vstup: staničení (x) + kolmice (y)
- Výpočet: jednotkový vektor P→K, transformace do globálních souřadnic

### `GeoAlgorithmTransform*.pas`
- **Base**: abstraktní `ComputeParametersFromPoints()` + `Calculate()`
- **Similarity**: translace + rotace + jednotné měřítko (4 parametry)
- **Congruent**: translace + rotace, FQ=1.0 (3 parametry)
- **Affine**: 6 parametrů (různá měřítka X/Y, rotace, střih) — řeší Gauss-Jordan inverzí matice

---

## 6) GUI formuláře (src/GUI/)

### `GeoSoft.dpr` — hlavní vstupní bod
Vytváří a inicializuje všechny formy:
```
Form1 (MainForm), PointsManagementForm, ParcelAreaForm,
OrthogonalMethodForm, TransformationForm, AddPointForm,
CheckMeasurementForm, PolarMethodForm, Form2 (TestFieldGrid), Form5 (Unit5)
```
Search path: `..\Utils;..\Components;..\DataStructures;..\..\GeoComponents`

### `MainForm.pas` — hlavní menu
- Jen launcher — otevírá ostatní formy přes `Show`
- Interface `uses`: pouze Winapi + VCL (čistě po refaktoringu)
- Implementation `uses`: ParcelArea, OrthogonalMethod, Transformation, CheckMeasurement, PolarMethod, TestFieldGrid, Unit5, PointsManagement

### `PointsManagement.pas` — správa bodů ⭐
Hlavní formulář pro prohlížení a editaci slovníku bodů.

**Grid**: `TGeoPointsGrid` (6 sloupců, FixedCols=0)
| Col | Obsah | Validace |
|-----|-------|---------|
| 0 | Číslo bodu | cdtNone (sestavuje BuildPointIdFromPrefixState) |
| 1 | X | cdtExpression, 3 des. místa |
| 2 | Y | cdtExpression, 3 des. místa |
| 3 | Z | cdtExpression, 3 des. místa |
| 4 | Kvalita | cdtInteger, 0–8, max 1 znak |
| 5 | Popis | cdtNone |

**Klíčové metody:**
- `RefreshGrid()` — načte všechny body ze singletonu seřazené dle čísla
- `TrySaveRow(ARow)` — validuje a ukládá řádek do singletonu; tiše přeskočí neúplné řádky; dialog při duplicitě
- `SelectCell()` — při přechodu na jiný řádek volá `TrySaveRow(FLastRow)`; `FLastRow` sleduje předchozí řádek
- `KeyDown()` — pouze DELETE + sestavení prefixu v col 0; ukládání je v SelectCell
- `UpdateStatusBar()` — zobrazuje "Bodů v paměti: N | cesta"
- `FormActivate()` — `RefreshGrid` + `UpdateStatusBar` (vidíš body přidané z jiných formulářů)

**Toolbar:** ComboBox KU, ZPMZ, KK (výchozí kvalita), Popis — `EnsureQualityOnRow` a `ApplyDescriptionToRow` doplní hodnoty pokud jsou prázdné.

**Bug opravený v refaktoringu:** Původně se ukládalo v `KeyDown` s kontrolou `Col < ColCount-1`. Protože `TGeoGrid` přesouvá focus před tím než `OnKeyDown` formy stihne zareagovat, podmínka nikdy nebyla splněna a body se neukládaly.

### `AddPoint.pas` — dialog přidání bodu
Modální dialog, 1 datový řádek. **Migrován na `TGeoPointsGrid`** (dříve `TMyStringGrid`).

**Execute(PointNumber, out NewP):**
1. Zobrazí formulář s předvyplněným číslem bodu
2. repeat..until smyčka — vrátí uživatele zpět pokud X nebo Y není platné číslo
3. Při OK: commit editoru, StrToFloatDef pro souřadnice, defaults pro kvalitu/popis
4. Zkontroluje duplicitu → dialog "Chcete přepsat?"
5. Uloží do singletonu (AddPoint nebo AddOrUpdatePoint)
6. Vrátí True + výsledný bod v `NewP`

**Validace sloupců (přes ColumnFilters):**
| Col | DataType | OnInvalidCommit |
|-----|----------|----------------|
| 0 Číslo bodu | cdtNone | ciaBlock |
| 1 X | cdtExpression, 3 des. | ciaBlock |
| 2 Y | cdtExpression, 3 des. | ciaBlock |
| 3 Z | cdtExpression, 3 des. | ciaBlock |
| 4 Kvalita | cdtInteger 0–8, OnGetDefaultText | ciaBlock |
| 5 Popis | cdtNone | ciaBlock |

**Závislosti:** `PointsUtilsSingleton`, `GeoPointsGrid`, `GeoColumnValidation`, `PointPrefixState`  
(Odstraněno: `MyStringGrid`, `StringGridValidationUtils`, `InputFilterUtils`)

### `PolarMethod.pas` — polární metoda (nová)
Tři gridy: stanovisko, orientace, podrobné body.

**Lookup flow:**
```
Uživatel zadá číslo bodu → LookupOrPromptPoint()
  → PointExists? → GetPoint → FillRowFromPoint (X,Y,Z,Kvalita,Popis)
  → Neexistuje?  → otevře AddPoint dialog → uloží do singletonu
```

**Data ukládání (tlačítko Uložit):**
- Plní 3x `TGeoDataFrame` (stanovisko, orientace, podrobné body) z gridů
- Ukládá do CSV + BIN souborů: `Polar_Station`, `Polar_Orient`, `Polar_Detail`
- ⚠ Výsledky výpočtu se **NEUKLÁDAJÍ** automaticky do slovníku bodů

**Závislosti:** `TGeoDataFrame`, `TGeoRow`, `MyStringGrid`, `PointsUtilsSingleton`, `PointPrefixState`

### `OrthogonalMethod.pas` — ortogonální metoda
Grid s kotevními body (ř. 1-2) a podrobnými body (ř. 3+).

**Lookup:**
- Ř. 1-2 (P, K): `LoadOrPromptAnchor` → dialog pokud neexistuje
- Ř. 3+: `MaybeFillFromDict` → tiše doplní pokud existuje, jinak nic

**Výpočet (Enter v col 2-3 podrobného řádku):**
- `TryComputeDetailRow(R)` volá `TOrthogonalMethodAlgorithm.Calculate` (Utils v1)
- Zapíše X, Y do cols 4-5
- **Po výpočtu uloží výsledný bod do slovníku:** `TPointDictionary.GetInstance.AddOrUpdatePoint(OutPts[0])`

**Závislosti:** `GeoAlgorithmBase`, `GeoAlgorithmOrthogonal` (Utils v1), `GeoPointsGrid`, `PointsUtilsSingleton`

### `ParcelArea.pas` — polární metoda (stará)
Podobná OrthogonalMethod — stanovisko A (ř.1), orientace B (ř.2), podrobné body (ř.3+).

**Výpočet (Enter v cols 2-3):**
- `TryComputePolarForRow(R)` volá `TPolarMethodAlgorithm.Calculate` (Utils v1)
- Staví `TOrientations` z B + ψ_B
- Zapíše X, Y do cols 4-5

**Závislosti:** `GeoAlgorithmBase`, `GeoAlgorithmPolar` (Utils v1), `PointsUtilsSingleton`

### `Transformation.pas` — transformace souřadnic
- Grid s checkboxy pro výběr bodů
- Cols: výběr, cílové souřadnice, zdrojové souřadnice, výsledky (dX, dY, měřítko)
- Grid je read-only (goEditing vypnuto)
- `FChecked` array sleduje stav checkboxů
- ⚠ Transformační algoritmy (`GeoAlgorithmTransform*`) jsou v projektu ale formulář je přímo nevolá

### `CheckMeasurement.pas` — ověření měření
- Minimal forma pro testování `AddPoint` dialogu
- `MyFieldsStringGrid1` zobrazuje pole [CB, X, Y, Z, HZ, SS, Poznamka]
- Button1 → otevře AddPoint dialog
- Button2 → prázdný handler (TestFieldGrid odpojen v refaktoringu)

### `TestFieldGrid.pas` (Form2) — vývojová forma
- Testuje `TMyFieldsStringGrid` (src/Components)
- CheckListBox pro výběr aktivních `TGeoField` polí
- Stále v `GeoSoft.dpr` a CreateForm — viditelná za běhu
- Závislost z `CheckMeasurement` odstraněna

### `Unit5.pas` (Form5) — vývojová forma
- Testuje `TGeoFieldsGrid` (GeoComponents)
- Stejná logika jako TestFieldGrid ale nová komponentová větev
- Aktivní kód (ne zakomentovaný), plně funkční
- Přidána do CreateForm v `GeoSoft.dpr`

---

## 7) Komponenty (GeoComponents/)

Samostatný reusable package, **nezávisí na ničem z `src/`**.  
Package: `GeoComponentsR.dpk`, paleta `MyComponents`. Search path: `..\` (relativní).

### `GeoGrid.pas` — TGeoGrid
Base grid s vlastním inplace editorem.

**`TGeoInplaceEdit`:**
- `KeyDown` — zachytí VK_RETURN/VK_TAB; volá `CommitCurrentCell` → pokud False (ciaBlock), Key:=0, Exit; pokud True, volá `MoveToNextCell`
- `KeyPress` — spotřebuje `#13` (Enter char) **← klíčová oprava blokování**
  - Windows posílá `WM_CHAR(13)` po každém `WM_KEYDOWN(VK_RETURN)`
  - `TInplaceEdit.KeyPress` zpracovává `#13` voláním `EditorMode := False` — obchází validaci
  - Spotřebování `#13` zde zajistí že editor řídí navigaci pouze přes `KeyDown`

**`TGeoGrid`:**
- `FLastCommitFailed: Boolean` — `protected` flag; nastavuje potomek v `CommitCell` při ciaBlock
- `CommitCurrentCell: Boolean` — volá `CommitCell`, vrací `not FLastCommitFailed`, resetuje flag
- `KeyDown` — volá `CommitCurrentCell` před `MoveToNextCell`; pokud False, Key:=0, Exit (pro Tab přes SendMessage)
- `SelectCell` — při přechodu myší volá `CommitCell`; pokud `FLastCommitFailed` → `Result:=False`, znovu otevře editor
- `MoveToNextCell` — kontroluje `FLastCommitFailed` po `CommitCell` jako záložní mechanismus
- `MoveToNextCell` je `protected virtual` → potomci mohou přepsat navigaci
- `IsHeaderCell`, `IsDataCell` — virtuální helpery pro DrawCell
- `ColumnHeaders`, `RowHeaders` — published, auto-nastaví `FixedRows`/`FixedCols`
- `ebMoveFocusNext` → `PostMessage(WM_NEXTDLGCTL)` pro správný tab-order

### `GeoColumnValidation.pas`
Validační engine bez COM, vlastní recursive-descent parser.
- `TColumnDataType`: cdtNone, cdtInteger, cdtFloat, cdtExpression
- `TCommitInvalidAction`: `ciaBlock` (výchozí), `ciaBeepAndClear`
  - `ciaBlock` — pípne, smaže neplatný obsah, zablokuje navigaci (editor zůstane otevřený)
  - `ciaBeepAndClear` — pípne, smaže obsah, navigace pokračuje
  - **Výchozí hodnota je `ciaBlock`** (změněno z původního `ciaBeepAndClear`)
- `TColumnFilter`: pravidla 1 sloupce (DataType, MinLength, MaxLength, HasMin/MaxValue, DecimalPlaces, OnInvalidCommit, OnGetDefaultText)
- `TColumnFilters`: `TOwnedCollection`, `EnsureCount(N)`
- `FilterKeyPress()` — real-time char filtering
- `TryCommitText()` — full validation + formátování při opuštění buňky
- Parser gramatika: Expression → Term → Factor → Unary → Primary → Number
- Mocnění `^` je pravě asociativní; dělení nulou = False
- ⚠ Nepodporuje: funkce (sin, sqrt), konstanty (pi), vědecký zápis (1e-3), implicitní násobení

### `GeoFieldsDef.pas`
Definice geodetických polí pro GeoComponents (nezávislé na `src/DataStructures/GeoRow.pas`).
- `TGeoField` enum (18 polí — musí být ručně synchronní s `GeoRow.pas`)
- `TColumnFilterData` — plain record s metadaty (bez tříd)
- `GeoFieldColumns: array[TGeoField]` — globální defaults inicializované v `initialization`
- `ApplyFieldColumnToFilter()` — kopíruje metadata do runtime `TColumnFilter`
- Helpery: `MakeFloat`, `MakeMin`, `MakeRange`, `MakeText`, `MakeInteger`

### `GeoFieldsGrid.pas` — TGeoFieldsGrid
Field-driven grid dědící z `TGeoGrid`.
- `GeoFields: TGeoFields` — set aktivních sloupců, `RebuildColumns` při změně
- `FColToField` — mapování datového indexu sloupce na `TGeoField`
- `FColumnData` — per-instance kopie `GeoFieldColumns` (lze přepsat bez změny globálních defaults)
- `FColumnFilters: TColumnFilters` — runtime filtry synchronizované přes `RefreshFilters`
- `SelectCell` — commit při opuštění buňky přes `TryCommitText`
- `FieldToCol()`, `ColToField()` — bezpečné mapování, vrací -1 pro neaktivní pole
- ⚠ Chybí `SetGeoRow`/`GetGeoRow` (na rozdíl od `MyFieldsStringGrid`) — plánované doplnění

### `GeoPointsGrid.pas` — TGeoPointsGrid
Tenký potomek `TGeoGrid` s published `ColumnFilters` pro design-time konfiguraci.
- Filtry indexovány od 0 = první datový sloupec (ne fixed)
- `SizeChanged` → `EnsureFilterCount` udržuje počet filtrů
- Vlastní inplace editor `TGeoPointsInplaceEdit` pro keypress filtraci
- `CommitCell` override: validuje přes `TryCommitText` + `OnGetDefaultText`
  - `ciaBeepAndClear` → smaže buňku + editor, navigace pokračuje
  - `ciaBlock` → pípne, smaže buňku + editor, nastaví `FLastCommitFailed := True` (blokování řeší `TGeoGrid`)
- Používán v `PointsManagement` a `AddPoint`

### `MyGrid.pas` — TMyGrid
Jednodušší generic base grid.
- `CommitCell` je virtuální hook před opuštěním buňky
- `FNavigating` pojistka proti dvojímu zpracování Enter/Tab (VCL quirk)
- ⚠ `MoveToNextCell` je private — potomci ho nemohou přepsat (narozdíl od TGeoGrid)

---

## 8) Deprecated (src/Components/ + src/Packages/)

Označeno soubory `Bude_smazano_zatim_zusva_kvuli_funkcnosti.txt` a `taky_bude_smazano.txt`.

### src/Components/
Starší komponentová větev — stále používaná GUI formuláři.
- `MyStringGrid` — dual validace (callback + ColumnFilters), `EnterEndBehavior`
- `MyFieldsStringGrid` — field-driven grid s `SetGeoRow`/`GetGeoRow`; závisí na `GeoRow`
- `ColumnValidation` — validační engine s **COM/VBScript** (`MSScriptControl`)
- `GeoFieldColumn` — mapování `TGeoField` → display name + `TColumnFilter`; závisí na `GeoRow`

### src/Packages/
- `GeoSoftComponentsR.dpk` — package pro src/Components; search paths relativní (opraveno)
- `dclusr.dpk` — závislý na GeoSoftComponentsR

---

## 9) Testy (tests/)

Všechny search paths sjednoceny na Windows styl (`\`).

| Projekt | Co testuje | Search path |
|---------|-----------|------------|
| `DataModel/TestGeoRow` | `TGeoRow` - vytvoření, I/O | `..\..\src\DataStructures` |
| `DataModel/TestGeoDataFrame` | `TGeoDataFrame` - CSV, BIN | `..\..\src\DataStructures` |
| `Algorithms/PolarTest` | Polární metoda v1 | `..\..\src\Utils` |
| `Algorithms/PolarTest2` | Polární metoda v2 (GeoDataFrame) | `..\..\src\Utils;..\..\src\DataStructures` |
| `Algorithms/OrthogonalTest` | Ortogonální metoda v1 | `..\..\src\Utils` |
| `Algorithms/TransformTest` | Transformace | `..\..\src\Utils` |
| `Algorithms/TransformTestTXT` | Transformace z TXT | `..\..\src\Utils;..\..\src\DataStructures` |
| `Algorithms/TestReadTXT` | Čtení TXT souborů | `..\..\src\Utils;..\..\src\DataStructures` |
| `Console/GeoSoftConsole` | Konzolová varianta aplikace | `..\..\src\Utils;..\..\src\DataStructures` |

---

## 10) Datový tok a architektura

### Přidání bodu — kompletní tok
```
Uživatel zadá data do gridu (PointsManagement nebo AddPoint dialog)
    ↓
Real-time validace: InputFilterUtils.Filter* → blokuje špatné znaky
    ↓
Navigace na jiný řádek → SelectCell → TrySaveRow(FLastRow)
    ↓
Commit editoru, EnsureQualityOnRow, ApplyDescriptionToRow
    ↓
Čtení hodnot z buněk → StrToIntDef, StrToFloatDef
    ↓
Validace dat: PointNumber > 0, X/Y/Z nejsou NaN
    ↓
Kontrola duplicit: TPointDictionary.GetInstance.PointExists(N)
    ├─ Existuje → MessageDlg "Chcete přepsat?"
    │   ├─ Ano → AddOrUpdatePoint (přepíše)
    │   └─ Ne  → Exit (neuloží)
    └─ Neexistuje → AddPoint (přidá)
    ↓
UpdateStatusBar → "Bodů v paměti: N"
```

### Výpočet — lookup bodu z formuláře
```
Uživatel zadá číslo bodu → zmáčkne Enter
    ↓
LookupOrPromptPoint(N) [PolarMethod] nebo MaybeFillFromDict(R) [Ortogonální/Parcelní]
    ↓
TPointDictionary.GetInstance.PointExists(N)?
    ├─ ANO → GetPoint(N) → FillRowFromPoint(R, P) → doplní X,Y,Z
    └─ NE  →  PolarMethod: otevře AddPoint dialog → uloží + doplní
              Ortogonální/Parcelní (podrobné body): tiše nic
              Ortogonální/Parcelní (kotevní body 1-2): LoadOrPromptAnchor → dialog
```

### Prefix systém
```
GPointPrefix: TPointPrefixState (globální)
  KU:    '000000'  (6 číslic, katastrální území)
  ZPMZ:  '00000'   (5 číslic, zápisník parcelního měření)
  KK:    '3'       (výchozí kód kvality)
  Popis: ''        (šablona popisu)

Výsledné číslo bodu (15 číslic):
  KU(6) + ZPMZ(5) + vlastní(4) = např. 751261478500012
  Pokud vlastní > 4 číslice → vrátí jen vlastní číslo

Sync:
  FormCreate/Activate → LoadPrefixToCombos
  Combo.OnExit        → SavePrefixFromCombos
  Při zadání bodu     → BuildPointIdFromPrefixState(vlastní číslo)
```

### Dependency flow
```
GUI formuláře
  ↓ uses
DataStructures (Point, PointsUtils*, GeoRow, GeoDataFrame)
  +
Utils (ValidationUtils, InputFilterUtils, StringGridValidationUtils, PointPrefixState)
  +
GeoComponents (GeoGrid, GeoPointsGrid, GeoColumnValidation)
  +
src/Components (MyStringGrid, MyFieldsStringGrid...) ← deprecated
  +
Utils/legacy algoritmy v1 (dočasně)
  ↓ (po migraci na GeoComponents)
GeoAlgorithms v2 (instanční algoritmy)
```

GeoComponents nezávisí na ničem z `src/` — je přenositelný do jiného projektu.

---

## 11) Historie změn

### Refaktoring struktury projektu (červen 2026 — konverzace 1)

| Oblast | Co se změnilo |
|--------|--------------|
| **Struktura root** | `Test_gdf/` → `tests/`, `GeoComponents/` zůstalo, absolutní cesty → relativní |
| **tests/** | Rozděleno na `DataModel/`, `Algorithms/`, `Console/`; search paths sjednoceny na `\` |
| **src/DataStructures/** | Nová složka; sem přesunuty: `GeoRow`, `GeoDataFrame` (z tests/), `Point`, `PointsUtils*` (z Utils/) |
| **src/Utils/** | Přesunuto ven: `Point`, `PointsUtils*`; přesunuto sem z GUI: `StringGridValidationUtils` |
| **src/GeoAlgorithms/** | Testovací `.dpr` přesunuty do `tests/Algorithms/` |
| **PointsUtilsSingleton** | Přidána metoda `AddOrUpdatePoint()` |
| **PointsManagement** | Ukládání přesunuto z `KeyDown` do `SelectCell.TrySaveRow()` (opravena race condition s TGeoGrid); přidán `UpdateStatusBar`, `FLastRow` tracking; dialog při duplicitě |
| **AddPoint** | Dialog při duplicitě "Chcete přepsat?"; přidán `Vcl.Dialogs` |
| **MainForm** | Interface `uses` vyčistěn — algoritmy a GeoComponents přesunuty pryč; `PointsManagement` přesunuto do implementation |
| **CheckMeasurement** | Odstraněna závislost na `TestFieldGrid`; Button2 zachován ale prázdný |
| **GeoFieldsDef.pas** | Smazáno ~336 řádků zakomentovaného starého kódu |
| **GeoFieldsGrid.pas** | Smazáno ~323 řádků zakomentovaného starého kódu |
| **Absolutní cesty** | Opraveny v GeoSoftComponentsR.dproj, dclusr.dproj, GeoComponents/test/Project1.dproj |

---

### Opravy validace, kódování, migrace (červen 2026 — konverzace 2)

| Oblast | Co se změnilo |
|--------|--------------|
| **Kódování souborů** | Všechny `.pas` soubory převedeny na UTF-8 s BOM; Delphi IDE nastaveno na UTF-8; opraveny rozsypané diakritické znaky (U+FFFD) v 8 souborech |
| **GeoColumnValidation** | `ciaBlock` nově výchozí hodnota `OnInvalidCommit` (dříve `ciaBeepAndClear`); `ciaBlock` přesunut na první pozici enumu |
| **GeoGrid — blokování navigace** | `FLastCommitFailed: Boolean` přesunut do `protected` předka `TGeoGrid` (dříve jen v `TGeoPointsGrid`) |
| **GeoGrid — KeyPress oprava** ⭐ | `TGeoInplaceEdit.KeyPress` spotřebuje `#13` — klíčová oprava: `TInplaceEdit.KeyPress` volal `EditorMode := False` po každém Enter přes `WM_CHAR(13)`, čímž obcházel veškerou validaci |
| **GeoGrid — KeyDown** | `TGeoGrid.KeyDown` volá `CommitCurrentCell` před `MoveToNextCell` (pro Tab přes SendMessage) |
| **GeoGrid — SelectCell** | Přidáno blokování pro kliknutí myší: pokud `FLastCommitFailed` po `CommitCell`, navigace se zablokuje a editor se znovu otevře |
| **GeoGrid — MoveToNextCell** | Přidána záložní kontrola `FLastCommitFailed` po `CommitCell` |
| **GeoGrid — CommitCurrentCell** | Nová veřejná metoda: volá `CommitCell`, vrací `not FLastCommitFailed`, resetuje flag |
| **GeoPointsGrid** | `CommitCell` ciaBlock: smaže obsah buňky + editoru (aby `UpdateText` nezapsalo neplatnou hodnotu), nastaví `FLastCommitFailed` |
| **GeoFieldsGrid** | `CommitCell` doplněn o kompletní ciaBlock/ciaBeepAndClear logiku (dříve chyběla) |
| **PointsManagement** | `StringGrid1KeyDown` odstraněno `EditorMode := False` pro všechny sloupce; sestavování prefixu přesunuto do `TrySaveRow`; explicitní `ciaBlock` pro X, Y, Z sloupce; přidán `System.UITypes` |
| **AddPoint** | Migrováno z `TMyStringGrid` na `TGeoPointsGrid`; validace přes `ColumnFilters`; přidána repeat..until validace X/Y v `Execute`; `ciaBlock` explicitně pro X, Y, Z; odstraněny `StringGridValidationUtils`, `InputFilterUtils`, `MyStringGrid` z uses |
| **OrthogonalMethod** | Po výpočtu uloží výsledný bod do slovníku přes `AddOrUpdatePoint` |
| **System.UITypes** | Přidán do `AddPoint.pas` a `PointsManagement.pas` (hint H2443) |

---

## 12) Plánované další kroky (backlog)

### Krátkodobé
- **Dokončit `GeoFieldsGrid`** — přidat `SetGeoRow`/`GetGeoRow` (na rozdíl od MyFieldsStringGrid chybí)
- **Migrace GUI na GeoComponents** — přepsat formuláře z `src/Components` na `GeoComponents`; pak smazat `src/Components/` a `src/Packages/`
- **Ukládání výsledků výpočtu do slovníku** — PolarMethod stále neukladá výsledky (OrthogonalMethod opraveno)
- **Transformation formulář** — dokončit napojení na `GeoAlgorithmTransform*` algoritmy

### Střednědobé
- **Odstranit COM závislost** v `StringGridValidationUtils` — nahradit `MSScriptControl` vlastním parserem (stejným jako v `GeoColumnValidation`)
- **Sjednotit TGeoField enum** — jeden autoritativní zdroj místo dvou kopií (`GeoRow.pas` + `GeoFieldsDef.pas`); architektonická diskuze viz konverzace 2
- **Import duplicit** — přidat `ImportDuplicateDialog` pro import ze souborů (návrh připraven v konverzaci 2)

### Dlouhodobé
- **Odstranit legacy v1 algoritmy** z `src/Utils/` — po migraci GUI na GeoComponents + v2
- **Dependency injection místo singletonu** — zvážit až při větší refakturaci; pro desktop single-user app je singleton OK

---

## 13) Riziková místa

| Riziko | Popis | Závažnost |
|--------|-------|-----------|
| **Dva TGeoField enumy** | `GeoRow.pas` a `GeoFieldsDef.pas` musí být ručně synchronní při přidání pole | Střední |
| **COM závislost** | `MSScriptControl` v `StringGridValidationUtils` + `ColumnValidation` — nemusí fungovat všude | Střední |
| **Globální stav** | `TPointDictionary.GetInstance`, `GPointPrefix`, globální instance formulářů | Nízké (pro desktop app akceptovatelné) |
| **PolarMethod bez uložení výsledků** | Vypočítané body nejdou automaticky do slovníku (OrthogonalMethod opraveno) | Nízké |
| **Unit5 a TestFieldGrid v CreateForm** | Testovací formy se vytváří při startu — mírná paměťová zátěž | Nízké |
| **Import bez duplicit dialogu** | Import ze souborů stále používá starý `AddPoint` bez možnosti rozhodnutí per-bod | Střední |

---

## 14) Jak funguje blokování neplatné hodnoty v GeoGrid (technický detail)

### Problém
Při stisku Enter v inplace editoru Windows posílá dva signály:
1. `WM_KEYDOWN(VK_RETURN)` — zpracován v `KeyDown`
2. `WM_CHAR(#13)` — zpracován v `KeyPress`

Standardní `TInplaceEdit.KeyPress` pro `#13` volá `TCustomGrid(Owner).EditorMode := False`, což editor bezpodmínečně zavře — obchází veškerou validaci.

### Řešení (vrstvené)

```
Enter stisknut v editoru
  │
  ├─► WM_KEYDOWN(VK_RETURN)
  │     └─ TGeoInplaceEdit.KeyDown
  │           └─ CommitCurrentCell → False (ciaBlock + neplatná)?
  │                 ├─ ANO: Key:=0, Exit → žádná navigace
  │                 └─ NE:  MoveToNextCell → navigace proběhne
  │
  └─► WM_CHAR(#13)  ← druhý signál od Windows
        └─ TGeoInplaceEdit.KeyPress
              └─ Key = #13 → Key:=#0, Exit  ← SPOTŘEBUJE
                   (TInplaceEdit.KeyPress se nikdy nedostane k EditorMode := False)
```

### Tab (fungoval před opravou Enter)
Tab posílá Delphi `TInplaceEdit.WndProc` do gridu přes `SendMessage` → `TGeoGrid.KeyDown` → `CommitCurrentCell` → blokuje. Enter tuto cestu neměl — proto Tab fungoval a Enter ne.

### Myš
Kliknutí na jinou buňku → `SelectCell` → `CommitCell` → pokud `FLastCommitFailed` → `Result:=False`, editor znovu otevřen.
