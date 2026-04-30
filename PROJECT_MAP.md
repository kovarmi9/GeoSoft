# PROJECT MAP

Aktualizováno: **30. dubna 2026**. Mapa popisuje aktuální stav souborů v repozitáři; VCL/System unity nejsou vypisované úplně.

## 1) Struktura projektu

### Root
- `README.md`: zatím jen minimální placeholder.
- `icons/`: ikona aplikace a obrázek `zorpracovane.png`.
- `PROJECT_MAP.md`: tato mapa projektu.

### Hlavní GUI aplikace (`src/GUI`)
- `GeoSoft.dpr`: hlavní VCL aplikace. Vytváří `TForm1`, `TPointsManagementForm`, `TParcelAreaForm`, `TOrthogonalMethodForm`, `TTransformationForm`, `TAddPointForm`, `TCheckMeasurementForm`, `TPolarMethodForm`, `TForm2` a `TForm5`.
- `MainForm.pas`: hlavní menu (`TForm1`). Otevírá správu bodů, parcelní/polární výpočet, ortogonální metodu, transformace, kontrolní formulář a test gridu. V interface `uses` má i experimentální/design-time komponenty `MyGrid`, `GeoGrid`, `GeoFieldsGrid`, `MyFieldsStringGrid` a staré DB/Web dependency (`Data.DB`, `Vcl.DBGrids`, `Web.*`).
- `PointsManagement.pas`: správa seznamu bodů v `TMyPointsStringGrid`. Pracuje nad singletonem `TPointDictionary`, import/export TXT/CSV/BIN, globální prefix state z `PointPrefixState`, callback filtry z `InputFilterUtils` a vlastní logiku Enter/navigace.
- `ParcelArea.pas`: formulář `TParcelAreaForm` pro výpočet z polární metody nad obyčejným `TStringGrid`. Načítá stanovisko/orientaci z `TPointDictionary`, chybějící bod řeší přes `AddPoint`, volá utils variantu `GeoAlgorithmPolar`.
- `PolarMethod.pas`: aktuální formulář `TPolarMethodForm` pro novější polární zadání nad `TMyStringGrid`/`TMyPointsStringGrid`, `TGeoDataFrame` a `TGeoRow`. Ukládá pracovní data, validuje vstupy a pracuje s prefix comboboxy.
- `OrthogonalMethod.pas`: formulář `TOrthogonalMethodForm` pro ortogonální metodu. Používá `TMyPointsStringGrid`, lookup/doplnění bodů, validace a `GeoAlgorithmOrthogonal` z `src/Utils`.
- `Transformation.pas`: formulář `TTransformationForm` pro transformační tabulku bodů nad singletonem bodů. Transformační algoritmy jsou v projektu, ale tento formulář je přímo neimportuje.
- `AddPoint.pas`: dialog `TAddPointForm` pro ruční doplnění bodu, postavený nad `TMyStringGrid`. Má `Execute(PointNumber, out Point)` workflow a zároveň globální instanci `AddPointForm`.
- `CheckMeasurement.pas`: pomocný formulář `TCheckMeasurementForm`. Otevírá `AddPoint` a testovací `Form2`.
- `TestFieldGrid.pas`: GUI test pro produkční `TMyFieldsStringGrid` (`src/Components`), checklist vybírá aktivní `TGeoField`.
- `Unit5.pas`: GUI test pro novou komponentovou větev `TGeoFieldsGrid` z `Komponenty/`.
- `StringGridValidationUtils.pas`: sdílené validační helpery pro `TStringGrid` a custom gridy.
- `*.dfm`: formuláře k uvedeným unitám.

Poznámka: `PolarMethodNew.pas` a `CalcFormBase.pas` už v aktuálním stromu nejsou. Starší role „nové polární metody“ je dnes v `PolarMethod.pas`.

### Utils (`src/Utils`)
- `Point.pas`: základní datový typ `TPoint` (`PointNumber`, `X`, `Y`, `Z`, `Quality`, `Description`) + `PPoint`.
- `ValidationUtils.pas`: statické validační funkce pro čísla bodů, souřadnice, kvalitu a text.
- `InputFilterUtils.pas`: keypress filtry pro gridy.
- `PointPrefixState.pas`: globální `GPointPrefix` a helpery pro KÚ/ZPMZ/KK/Popis comboboxy.
- `PointsUtils.pas`: nesingleton správa kolekce bodů + import/export TXT/CSV/BIN.
- `PointsUtilsSingleton.pas`: singleton `TPointDictionary.GetInstance`, centrální mutable slovník bodů pro GUI.
- `GeoAlgorithmBase.pas`: abstrakce algoritmu nad `TPointsArray`.
- `GeoAlgorithmPolar.pas`: polární výpočet se statickými property `A` a `B` (`TOrientation`, `TOrientations`).
- `GeoAlgorithmOrthogonal.pas`: ortogonální výpočet se statickými property `StartPoint` a `EndPoint`.

### GeoAlgorithms (`src/GeoAlgorithms`)
- `GeoAlgorithmBase.pas`: rozšířená algoritmická abstrakce, navíc referencuje `GeoDataFrame`.
- `GeoAlgorithmPolar.pas`: objektová varianta polární metody (`Station`, `Orientations`).
- `GeoAlgorithmPolar2.pas`: polární metoda pracující přímo s `TGeoDataFrame` (`StationFrame`, `OrientationFrame`, `PointsFrame`).
- `GeoAlgorithmOrthogonal.pas`: objektová varianta ortogonální metody.
- `GeoAlgorithmTransformBase.pas`: abstraktní základ transformačních algoritmů.
- `GeoAlgorithmTransformSimilarity.pas`: podobnostní transformace.
- `GeoAlgorithmTransformCongruent.pas`: shodnostní transformace.
- `GeoAlgorithmTransformAffine.pas`: afinní transformace, obsahuje maticové helpery.
- Testovací DPR: `PolarTest.dpr`, `PolarTest2.dpr`, `OrthogonalTest.dpr`, `TransformTest.dpr`, `TransformTestTXT.dpr`, `TestReadTXT.dpr`.

### Produkční komponenty (`src/Components`)
- `MyStringGrid.pas`: hlavní custom grid nad `TStringGrid`. Má starší callback validaci (`SetColumnValidator`) i novější `ColumnFilters`/`ColumnValidation`.
- `MyPointsStringGrid.pas`: specializace `TMyStringGrid` pro body, výchozí `EnterEndBehavior := ebAddRow`.
- `MyFieldsStringGrid.pas`: field-driven grid pro `TGeoField` ze `Test_gdf/GeoRow.pas`. Umí `GeoFields`, mapování `FieldToCol`/`ColToField`, per-instance metadata sloupců a `SetGeoRow`/`GetGeoRow`.
- `ColumnValidation.pas`: record-based validační systém `TColumnFilter` + kolekce pro `MyStringGrid`; obsahuje i expression evaluaci.
- `GeoFieldColumn.pas`: mapování `TGeoField` na display name + `TColumnFilter`, globální `GeoFieldColumnData`.
- `MyStringGridReg.pas`: registrace `TMyStringGrid` a `TMyPointsStringGrid` do IDE.

### Design-time komponenty (`Komponenty/`)
Samostatná komponentová větev pro package `MyComponentsR.dpk`, paleta `MyComponents`. Nezávisí na `src/Components`.

- `MyComponentsR.dpk`: package obsahuje `MyGrid`, `GeoGrid`, `GeoColumnValidation`, `GeoFieldsDef`, `GeoFieldsGrid`, `MyGridReg`.
- `MyGrid.pas`: jednodušší `TMyGrid = class(TStringGrid)` s `ColumnHeaders`, `RowHeaders`, `EnterEndBehavior`, `CommitCell` a vlastní navigací Enter/Tab.
- `GeoGrid.pas`: základní `TGeoGrid` s vlastním `TGeoInplaceEdit`, virtuálním `MoveToNextCell`, `IsHeaderCell`/`IsDataCell`, header renderingem a `ColumnHeaders`/`RowHeaders`.
- `GeoColumnValidation.pas`: novější class-based validace `TColumnFilter`/`TColumnFilters`; má vlastní recursive-descent parser výrazů bez COM/MSScriptControl.
- `GeoFieldsDef.pas`: samostatná definice `TGeoField`, `TGeoFields`, `TColumnFilterData`, `TGeoFieldColumn` a globální `GeoFieldColumns`.
- `GeoFieldsGrid.pas`: `TGeoFieldsGrid = class(TGeoGrid)`, dynamické sloupce podle `GeoFields`, per-instance kopie `GeoFieldColumns`, filtrování v inplace editoru a commit validace/formatování.
- `GeoPointsGrid.pas`: `TGeoPointsGrid = class(TGeoGrid)`, ručně konfigurovatelný grid s published `ColumnFilters` pro datové sloupce. Používá `GeoColumnValidation`, vlastní inplace editor pro keypress filtr a commit validaci před Enter/Tab navigací. Nevalidní hodnota při commitu vymaže buňku a navigace pokračuje.
- `MyGridReg.pas`: registruje `TMyGrid`, `TGeoGrid`, `TGeoFieldsGrid` a `TGeoPointsGrid`.

Poznámka: `GeoFieldsDef.pas` i `GeoFieldsGrid.pas` obsahují nahoře starší zakomentované verze stejné unity. Aktivní unit začíná až později v souboru (`GeoFieldsDef` kolem druhé poloviny, `GeoFieldsGrid` kolem řádku 324).

#### Detail: `Komponenty/GeoColumnValidation.pas`

`GeoColumnValidation` je validační a formátovací engine pro novou komponentovou větev okolo `TGeoGrid`/`TGeoFieldsGrid`. Na rozdíl od staršího `src/Components/ColumnValidation.pas` je postavený na `TCollectionItem` třídách vhodných pro vlastněnou kolekci a má vlastní parser výrazů bez COM/MSScriptControl. Unit nemá závislost na VCL gridech; řeší pouze pravidla, text a čísla. Konkrétní grid mu předává aktuální text buňky, stisknutou klávesu nebo text při commitu.

**Veřejné typy:**
- `TColumnDataType`: typ obsahu sloupce.
  - `cdtNone`: libovolný text, řeší se jen délkové limity.
  - `cdtInteger`: celé nezáporné číslo; filtr i validace dovolují jen číslice `0..9`.
  - `cdtFloat`: desetinné číslo; dovoluje číslice a jeden desetinný oddělovač podle `FormatSettings.DecimalSeparator`.
  - `cdtExpression`: aritmetický výraz, který se při commitu vyhodnotí a nahradí výsledkem.
- `TColumnFilter = class(TCollectionItem)`: pravidla jednoho sloupce.
  - `Column`: read-only index odvozený z pozice v kolekci (`Index`), neukládá se (`stored False`).
  - `DataType`: typ validace.
  - `MinLength`, `MaxLength`: délkové limity; `0` znamená vypnuto.
  - `HasMinValue`, `MinValue`, `HasMaxValue`, `MaxValue`: volitelné numerické hranice.
  - `DecimalPlaces`: formátování při commitu; `-1` nechá raw výstup, `0` zaokrouhlí na celé číslo, `N > 0` formátuje na přesně N desetinných míst.
- `TColumnFilters = class(TOwnedCollection)`: kolekce `TColumnFilter` položek, typicky jedna položka na jeden datový sloupec gridu. `EnsureCount(AColCount)` dorovná počet položek na počet sloupců a `OnChanged` se volá z overridu `Update`.

**Životní cyklus filtru:**
1. Grid nebo field definice vytvoří `TColumnFilters`.
2. Při změně aktivních sloupců zavolá `EnsureCount`.
3. Metadata z `GeoFieldsDef` se zkopírují přes `ApplyFieldColumnToFilter(...)` do konkrétních `TColumnFilter` instancí.
4. Během psaní grid volá `FilterKeyPress(Filter, Text, Key)`.
5. Při opuštění buňky nebo navigaci grid volá `TryCommitText(Filter, Text)`.
6. Pokud commit projde, grid zapíše případně přepsaný/formátovaný text zpět do buňky.

**Keypress filtr (`FilterKeyPress`):**
- `nil` filtr nic neblokuje.
- Řídicí znaky (`Key < #32`) vždy projdou, takže backspace a klávesové zkratky nejsou useknuté.
- Pokud je `MaxLength > 0` a aktuální text už má délku alespoň `MaxLength`, další tisknutelný znak se potlačí (`Key := #0`).
- `cdtNone`: nefiltruje obsah, jen délku.
- `cdtInteger`: dovolí jen číslice.
- `cdtFloat`: `.` i `,` přepíše na aktuální locale separator a dovolí jen jeden separator v textu.
- `cdtExpression`: dovolí číslice, desetinný oddělovač, operátory `+ - * / ^`, závorky a mezeru. Neřeší syntaxi v průběhu psaní, pouze znakovou množinu.

**Full-text validace (`ValidateText`):**
- Nejprve zkontroluje délku přes `CheckLengthBounds`.
- Potom podle `DataType` kontroluje celý text:
  - integer musí být neprázdný a obsahovat jen číslice,
  - float musí být neprázdný, obsahovat alespoň jednu číslici a nejvýše jeden aktuální desetinný separator,
  - expression musí jít úspěšně vyhodnotit přes parser.
- Hodnotové meze (`HasMinValue`/`HasMaxValue`) se aplikují jen pro numerické typy (`cdtInteger`, `cdtFloat`, `cdtExpression`).
- Důležitý detail: pokud je zapnutá hodnota min/max a `TryGetNumericValue` z nějakého důvodu nevrátí číslo, samotná kontrola mezí se přeskočí. U běžných typů tomu předchází typová validace, takže prakticky by invalidní číslo mělo spadnout už dřív.

**Commit (`TryCommitText`):**
- Nejprve zavolá `ValidateText`; když neprojde, vrací `False` a text nemění.
- `nil` filtr po úspěšné validaci nic dál nedělá.
- `cdtExpression`: výraz se znovu vyhodnotí, znovu se zkontrolují hodnotové meze a text se nahradí výsledkem z `FormatDouble`.
- `cdtFloat`: pokud `DecimalPlaces >= 0`, text se převede na `Double` a zformátuje na požadovaný počet desetinných míst.
- `cdtInteger` se při commitu neformátuje.
- `cdtNone` se při commitu nemění.

**Parser výrazů (`TryEvaluateExpression` / `TExpressionParser`):**
- Parser je privátní recursive-descent implementace, žádný COM ani script engine.
- Podporovaná gramatika:
  - `Expression := Term (('+' | '-') Term)*`
  - `Term := Factor (('*' | '/') Factor)*`
  - `Factor := Unary ('^' Factor)?`
  - `Unary := ('+' | '-') Unary | Primary`
  - `Primary := '(' Expression ')' | Number`
  - `Number := Digit+ (DecimalSep Digit+)?`
- `+`, `-`, `*`, `/` jsou levě asociativní přes smyčky v `ParseExpression` a `ParseTerm`.
- Mocnina `^` je pravě asociativní: `2^3^2` se čte jako `2^(3^2)`.
- Unární `+` a `-` jsou řešené rekurzivně před primární hodnotou.
- Závorky se párují přes `Expect(')')`.
- Dělení nulou vyhodí interní `EExpressionParserError` a výsledek je `False`.
- Po vyhodnocení se kontroluje, že parser došel na konec textu; zbylý neparsovaný text znamená neplatný výraz.
- Parser akceptuje jen mezery `' '`, ne obecný whitespace.
- Čísla podporují `.` i `,`; před `TryStrToFloat` se oba znaky normalizují na `FormatSettings.DecimalSeparator`.

**Formátování čísel:**
- `FormatDouble(Value, -1)` používá `FloatToStr`.
- `FormatDouble(Value, 0)` používá `FormatFloat('0', Value)`.
- `FormatDouble(Value, N)` používá masku `0.` + N nul, tedy fixní počet desetinných míst.
- Formátování používá aktuální globální `FormatSettings`, takže výstupní desetinný oddělovač závisí na locale aplikace/procesu.

**Napojení na `TGeoFieldsGrid`:**
- `TGeoFieldsGrid` drží `FColumnFilters: TColumnFilters`.
- `RefreshFilters` dorovnává kolekci podle aktivních fieldů a kopíruje metadata z `GeoFieldsDef`.
- `EditorKeyPress` volá `FilterKeyPress` podle aktuálního datového sloupce (`Col - FixedCols`).
- `SelectCell` při opuštění buňky bere `InplaceEditor.Text`, volá `TryCommitText` a při úspěchu zapisuje upravený text do `Cells[Col, Row]`.
- Pokud commit neprojde, současná implementace selection neblokuje; nechá v buňce původní/nevalidní text. To je UX rozhodnutí, ale je dobré ho vědět při ladění.

**Limity a poznámky:**
- Integer ani float filtr nepodporuje záporná čísla. Záporné hodnoty lze zadat jako expression (`-5`) jen ve sloupci `cdtExpression`.
- `ValidateFloatText` přijímá pouze aktuální locale separator, zatímco parser výrazů normalizuje `.` i `,`. U `cdtFloat` může tedy paste s jiným oddělovačem projít keypressem při ručním psaní, ale nemusí projít validací, pokud text neodpovídá `FormatSettings.DecimalSeparator`.
- `FilterExpressionKey` dovolí více desetinných separatorů v jednom výrazu; syntaktickou chybu zachytí až `TryEvaluateExpression`.
- Parser nepodporuje funkce (`sin`, `sqrt`), konstanty (`pi`), vědecký zápis (`1e-3`) ani implicitní násobení (`2(3+4)`).
- `Power` ze `System.Math` může pro některé kombinace hodnot vyvolat numerické problémy nebo vrátit hodnoty mimo očekávaný rozsah; unit nad tím nemá extra ochranu.
- `MinLength` a `MaxLength` počítají délku textu před commitem; výraz `1+2` má délku 3, i když výsledkem je `3`.

#### Detail: starší produkční větev `src/Components`

Tato větev je dnes blíž reálným formulářům aplikace. Používají ji `PointsManagement`, `AddPoint`, `OrthogonalMethod`, `PolarMethod`, `TestFieldGrid` a část hlavního formuláře. Je praktičtější a užitečná, ale nese s sebou několik historických vrstev: staré callback validátory, novější `ColumnFilters`, geodetické field metadata navázané na `Test_gdf/GeoRow.pas` a registraci do package `GeoSoftComponentsR`.

**`MyStringGrid.pas`: základní stavební kámen**
- `TMyStringGrid = class(TStringGrid)` rozšiřuje standardní VCL `TStringGrid`.
- V konstruktoru zapíná `goEditing`, `goTabs`, `goColSizing`, `goRowSizing`.
- Drží `EnterEndBehavior`, tedy co se stane na poslední datové buňce po Enter/Tab:
  - `ebStayOnLastCell`: zůstane na poslední buňce,
  - `ebWrapToStart`: skočí na první datovou buňku,
  - `ebAddRow`: přidá nový řádek,
  - `ebMoveFocusNext`: přesune focus na další komponentu podle tab orderu.
- Má `ColumnHeaders` a `RowHeaders` jako `TStrings`. Při nastavení automaticky doplní `FixedRows`/`FixedCols` a zapíše texty do fixních buněk.
- Vykresluje header buňky tučně, centrovaně a s `clBtnFace`; datové buňky nechává na inherited kreslení.
- Má dvě validační vrstvy:
  - starší callbacky `SetColumnValidator(ACol, AValidator)`,
  - novější kolekci `ColumnFilters: TColumnFilters`.
- Starší callback má prioritu. Pokud je pro sloupec callback nastavený, `ColumnFilters` se pro keypress ani commit nepoužije.
- Při `KeyPress` řeší Enter/Tab jako navigaci a ne jako znak.
- Při `KeyDown` na Enter/Tab nejdřív zavolá `ClearCellIfInvalid(Col, Row)`, pak naviguje.
- Při `SelectCell` při přechodu na jinou buňku také volá `ClearCellIfInvalid` na opouštěnou buňku.
- Pokud validace neprojde, `ApplyFilterToCell` pípne přes `MessageBeep(MB_ICONWARNING)` a `ClearCellIfInvalid` buňku vymaže.

**Jak teče validace v `TMyStringGrid`:**
1. Uživatel píše do buňky.
2. `KeyPress` zjistí, zda je buňka datová (`Row >= FixedRows`, `Col >= FixedCols`).
3. Pokud existuje starý callback validátor pro sloupec, zavolá ho.
4. Pokud callback není, zavolá `ApplyColumnFilter`, který najde `TColumnFilter` přes `ResolveColumnFilter`.
5. Při opuštění buňky se volá `ClearCellIfInvalid`.
6. `ClearCellIfInvalid` volá `ApplyFilterToCell`.
7. `ApplyFilterToCell` přes `TryApplyColumnFilter` ověří celý text, případně vyhodnotí výraz a přepíše text.
8. Když validace selže, obsah buňky se smaže.

**Co je na `TMyStringGrid` dobré:**
- Centralizuje navigaci Enter/Tab. Formuláře nemusí každé znovu řešit poslední buňku a přidávání řádků.
- Header API (`ColumnHeaders`, `RowHeaders`) je použitelné v Object Inspectoru a jednoduše streamovatelné do DFM.
- `ColumnFilters` je published kolekce, takže se dá nastavovat design-time bez kódu.
- Má fallback pro starší formuláře přes `SetColumnValidator`; to usnadnilo migraci.
- `SizeChanged` udržuje délku validátorů a filtrů podle `ColCount`.
- `SaveDC/RestoreDC` v `DrawCell` chrání canvas stav při kreslení hlaviček.

**Co je slabší a co bych zlepšil:**
- Míchá dva validační modely. Callback validátory a `ColumnFilters` se navzájem přebíjejí; pro nového čtenáře není hned jasné, který styl má být „správný“.
- Neplatná hodnota se maže. To je jednoduché, ale pro uživatele docela tvrdé: přijde o text a neví přesně proč. Lepší by bylo buňku nechat, zvýraznit ji a zobrazit chybu/status.
- `ClearCellIfInvalid` je volané i při navigaci a výběru. Je to funkční, ale může překvapit při kliknutí myší mimo buňku.
- `AutoSizeDataColumns` existuje, ale v `Resize` je zakomentované. Buď ho zapnout a dotáhnout, nebo odstranit, aby nemátl.
- `ApplyFilterToCell` při existenci callback validátoru vůbec nepoužije filter-based commit; callbacky tedy neumí stejně bohatý commit/formatting lifecycle.
- `EnterEndBehavior <> ebMoveFocusNext` podmínka po navigaci znovu otevře editor i v případě, kdy `ebMoveFocusNext` nebylo aktuálně použité, ale jen nastavené. U běžného pohybu uvnitř gridu s `ebMoveFocusNext` se editor nemusí otevřít tak, jak by uživatel čekal.
- `ColumnFilters` jsou indexované přímo podle vizuálního `Col`, tedy včetně fixed columns. U field gridů je potřeba myslet na posun `FixedCols`.

**`ColumnValidation.pas`: starší validační engine**
- Definuje `TColumnDataType = fNone/fInteger/fFloat/fExpression`.
- `TColumnFilter` je record, nikoli class. Limity `MinValue` a `MaxValue` jsou uložené jako string.
- `TColumnFilterItem` je design-time wrapper nad recordem pro `TCollection`.
- `TColumnFilters` je `TOwnedCollection` položek `TColumnFilterItem`.
- `ApplyColumnFilterKeyPress` filtruje znaky při psaní.
- `ValidateTextByColumnFilter` kontroluje celý text.
- `TryApplyColumnFilter` validuje, pro `fExpression` vyhodnotí výraz a nahradí text výsledkem.
- Výrazy se vyhodnocují přes `MSScriptControl.ScriptControl` a VBScript (`CreateOleObject('MSScriptControl.ScriptControl')`).

**Dobré na `ColumnValidation`:**
- Je bohatší než úplně jednoduché keypress filtry; řeší délku, min/max hodnotu i výrazy.
- `NormalizeDecimalText` a `NormalizeDecimalKeyChar` počítají s čárkou i tečkou.
- `ApplyExpressionKeyPress` už při psaní brání některým očividně špatným kombinacím operátorů.
- `CheckMaxValueWhileTyping` umí blokovat překročení maxima už při psaní.

**Slabší místa `ColumnValidation`:**
- COM závislost na `MSScriptControl` je křehká. Na moderních Windows/64bit prostředích nemusí být dostupná nebo může komplikovat distribuci.
- `MinValue`/`MaxValue` jako string jsou flexibilní pro Object Inspector, ale typově slabé. Novější `GeoColumnValidation` je v tomhle čistší (`Double` + `HasMinValue/HasMaxValue`).
- `ValidateIntegerText` a `ValidateFloatText` u prázdného textu vrací `True`, pokud délkové limity neřeknou opak. To může být záměr, ale je dobré to mít vědomě.
- `fFloat` nepovoluje záporné hodnoty, i když metadata některých úhlů mají `MinValue := '-400'`. Ručně zadat záporný float tedy nejde běžnou float validací.
- Expression validace kontroluje syntaxi ručně a potom se reálně vyhodnocuje přes VBScript. To jsou dva různé zdroje pravdy.

**`MyPointsStringGrid.pas`: bodový grid**
- Velmi tenká specializace `TMyStringGrid`.
- V konstruktoru nastaví `EnterEndBehavior := ebAddRow`.
- Hodí se pro seznamy bodů, kde Enter na konci přirozeně zakládá další řádek.
- Dobré: jednoduché, jasné, bez dalšího stavu.
- Co by šlo zlepšit: pokud by grid měl být opravdu „points-aware“, mohl by nést výchozí hlavičky a výchozí filtry pro číslo bodu, X/Y/Z, kvalitu a popis. Dnes je spíš navigační specializace.

**`GeoFieldColumn.pas`: metadata pro `TGeoField`**
- Mapuje `TGeoField` z `Test_gdf/GeoRow.pas` na:
  - `DisplayName`,
  - `TColumnFilter`.
- Globální `GeoFieldColumnData: array[TGeoField] of TGeoFieldColumn` se plní v `initialization`.
- Je to jednoduchá lookup tabulka pro `MyFieldsStringGrid`.
- Dobré: všechny výchozí popisky a validace fieldů jsou na jednom místě.
- Slabší: závisí na `GeoRow` z testovací složky `Test_gdf`, což rozmazává hranici mezi produkční komponentou a test podporou.
- Slabší: některé názvy jsou bez diakritiky a některé filtry mají limity, které starší `ColumnValidation` neumí pohodlně zadat ručně (například záporný úhel).

**`MyFieldsStringGrid.pas`: field-driven grid**
- Dědí z `TMyStringGrid`.
- Published property `GeoFields: TGeoFields` určuje, které geodetické fieldy se zobrazí.
- V konstruktoru nastaví `FixedRows := 1`, zkopíruje globální `GeoFieldColumnData` do per-instance `FColumnData` a začíná s prázdnou sadou fieldů.
- `RebuildColumns`:
  - spočítá aktivní fieldy,
  - vytvoří `FColToField`,
  - nastaví `ColCount`,
  - vyčistí data, hlavičky, filtry a šířky datových sloupců,
  - nastaví hlavičky a filtry podle `FColumnData`,
  - při nulové sadě fieldů schová placeholder sloupec.
- `SetColumnData` umožňuje přepsat display name a filtr jen pro konkrétní instanci.
- `ResetColumnData`/`ResetAllColumnData` vrací metadata zpět na globální defaulty.
- `FieldToCol` a `ColToField` převádějí mezi doménovým fieldem a vizuálním sloupcem.
- `SetGeoRow` zapisuje hodnoty z `TGeoRow` do aktivních sloupců.
- `GetGeoRow` čte aktivní sloupce zpět do `TGeoRow`.

**Dobré na `MyFieldsStringGrid`:**
- Výborně odděluje „jaká pole chci zobrazit“ od ruční práce se sloupci.
- Per-instance kopie metadat je správný směr: jeden formulář může přejmenovat sloupec nebo změnit filtr bez změny globálních defaultů.
- `FieldToCol`/`ColToField` šetří spoustu křehkého kódu typu „sloupec 7 znamená HZ“.
- `SetGeoRow`/`GetGeoRow` dávají gridu doménové API, ne jen stringové buňky.

**Slabší místa `MyFieldsStringGrid`:**
- `RebuildColumns` při změně `GeoFields` čistí datové buňky. To je bezpečné pro testovací/prototypové UI, ale v produkci může uživatel snadno přijít o rozepsaná data.
- `GetGeoRow` ignoruje návratovou hodnotu `TryStrToInt`/`TryStrToFloat`; při chybě zůstane default hodnota z `ClearGeoRow`. Chyby čtení tedy nejsou vidět.
- `SetGeoRow` a `GetGeoRow` používají aktuální `FormatSettings`; není tam explicitní formát pro souřadnice.
- Komponenta je navázaná na `Test_gdf/GeoRow.pas`, který názvem působí jako testovací model, ale fakticky se používá produkčně.
- Published `GeoFields` jako set enumu je fajn, ale pro dlouhodobé použití by se hodil vlastní property editor nebo helper UI.

**`MyStringGridReg.pas` a package stav:**
- Registruje `TMyStringGrid`, `TMyPointsStringGrid`, `TMyFieldsStringGrid` do IDE palety `GeoSoft`.
- `src/Packages/GeoSoftComponentsR.dpk` má být package pro tuto větev.
- Podezřelé je, že v `.dpk` jsou `MyFieldsStringGrid in 'MyFieldsStringGrid.pas'` a `GeoFieldColumn in 'GeoFieldColumn.pas'`, ale reálné soubory jsou v `src/Components`. Buď existoval starší přesun, nebo package v aktuálním stavu nemusí buildit bez úprav search path.

#### Detail: nová větev `Komponenty`

Tato větev působí jako čistší redesign komponent. Je samostatná v root adresáři `Komponenty/`, má vlastní package `MyComponentsR.dpk`, vlastní validační engine `GeoColumnValidation`, vlastní field definice `GeoFieldsDef` a registruje komponenty do palety `MyComponents`. Oproti `src/Components` méně závisí na zbytku aplikace.

**`MyGrid.pas`: jednoduchý obecný grid**
- `TMyGrid = class(TStringGrid)`.
- Má `MyGridDefaultOptions`, kde jsou zapnuté linky, range select, editace, taby a sizing.
- Má `ColumnHeaders`, `RowHeaders`, `EnterEndBehavior`.
- `CommitCell` je virtuální hook před opuštěním buňky. Základní implementace zapíše `InplaceEditor.Text` do `Cells[Col, Row]`.
- `SelectCell` funguje jako safety-net commit pro jakoukoli změnu výběru.
- `KeyDown` řeší Enter/Tab, commitne aktuální buňku a volá `MoveToNextCell`.
- `KeyPress` obsahuje `FNavigating` pojistku proti dvojímu zpracování Enter/Tab, protože VCL `TStringGrid` a inplace editor umí poslat kombinaci keydown/keypress ne úplně intuitivně.
- `MoveToNextCell` je private, ne virtual. Validaci má řešit spíš `CommitCell`.

**Dobré na `TMyGrid`:**
- Má jasně oddělený commit hook. To je lepší rozšiřovací bod než rozesetá validace v `KeyDown`/`SelectCell`.
- `FNavigating` řeší praktický VCL problém s dvojí navigací.
- Je obecný a nezávislý na geodetických datech.

**Co bych zvážil u `TMyGrid`:**
- `MoveToNextCell` je private. Pokud má být grid základem dalších navigačních variant, dávalo by smysl udělat ho `protected virtual`, podobně jako v `TGeoGrid`.
- `Options default MyGridDefaultOptions` je hezké pro OI, ale je potřeba ověřit, že set konstanta přesně odpovídá výchozímu runtime stavu po streamování.
- Header API je podobné jako v `TGeoGrid`, takže dlouhodobě by neměly existovat dva skoro stejné základy.

**`GeoGrid.pas`: lepší základ pro geodetické gridy**
- `TGeoGrid = class(TStringGrid)`.
- Definuje vlastní `TEnterEndBehavior` nezávisle na `MyGrid`.
- Definuje `TGeoInplaceEdit = class(TInplaceEdit)`.
- Přepisuje `CreateEditor`, aby grid používal vlastní inplace editor.
- `TGeoInplaceEdit.KeyDown` zachytí Enter/Tab přímo uvnitř editoru a deleguje na `TGeoGrid.MoveToNextCell`.
- `TGeoGrid.KeyDown` zachytí Enter/Tab i na úrovni gridu.
- `MoveToNextCell` je `protected virtual`, což je dobrý extension point pro potomky.
- `IsHeaderCell` a `IsDataCell` jsou virtuální helpery pro odlišení fixed/data buněk.
- `DrawCell` používá `IsHeaderCell`, takže potomci mohou změnit logiku hlaviček přepsáním jednoho helperu.
- `ColumnHeaders` a `RowHeaders` jsou published.
- `UpdateHeaders` je virtual a volá se i v `Loaded`.
- Pro `ebMoveFocusNext` používá `PostMessage(GetParentForm(Self).Handle, WM_NEXTDLGCTL, Ord(ssShift in Shift), 0)`.
- Po navigaci znovu otevře editor jen pro Enter, ne pro Tab.

**Dobré na `TGeoGrid`:**
- Vlastní inplace editor je čistší řešení než řešit Enter/Tab až přes `KeyPress`.
- `MoveToNextCell` je virtual, takže `TGeoFieldsGrid` nebo budoucí potomci mohou navigaci upravit.
- `IsHeaderCell`/`IsDataCell` jsou malé, ale užitečné extension pointy.
- `PostMessage` pro přesun focusu je rozumný, protože odloží tab-order navigaci až po dokončení aktuálního zpracování.
- Základ je bez znalosti `TGeoField`, validace nebo `GeoDataFrame`.

**Co bych zlepšil u `TGeoGrid`:**
- `GetParentForm(Self)` může teoreticky vrátit `nil`, pokud komponenta není na formuláři. Bez kontroly to může spadnout.
- `UpdateHeaders` po zápisu headerů nevolá `Invalidate`; většinou to asi funguje přes změnu buněk, ale explicitní invalidate by byl jasnější.
- `TEnterEndBehavior` je definovaný znovu v `MyGrid`, `GeoGrid` i `src/Components/MyStringGrid`. To vede ke třem typům se stejnými názvy hodnot, ale nejsou navzájem kompatibilní.
- `TGeoGrid` neumí obecný `CommitCell`; commit validace je až v `TGeoFieldsGrid.SelectCell`. To je použitelné, ale `TMyGrid` má v tomhle lepší obecný hook.

**`GeoFieldsDef.pas`: field definice pro novou větev**
- Definuje vlastní `TGeoField` a `TGeoFields`.
- Enum záměrně zrcadlí `Test_gdf/GeoRow.pas`, ale nevytváří na něm závislost.
- `TColumnFilterData` je plain record bez tříd: délky, min/max flagy, min/max hodnoty jako `Double`, `DecimalPlaces`.
- `TGeoFieldColumn` drží `DisplayName`, `DataType` a `Filter`.
- Globální `GeoFieldColumns: array[TGeoField] of TGeoFieldColumn` se plní v `initialization`.
- `ApplyFieldColumnToFilter` kopíruje plain metadata do runtime `TColumnFilter` objektu z `GeoColumnValidation`.
- Helpery `MakeFloat`, `MakeMin`, `MakeRange`, `MakeText`, `MakeInteger` zjednodušují inicializaci.

**Dobré na `GeoFieldsDef`:**
- Je samostatný a nemusí sahat do `Test_gdf`.
- `HasMinValue`/`HasMaxValue` je typově čistší než string limity ve starém `ColumnValidation`.
- `DecimalPlaces` je součást metadat, takže grid může rovnou formátovat výstup.
- `ApplyFieldColumnToFilter` dobře odděluje statickou definici fieldů od runtime validačních objektů.

**Co bych zlepšil u `GeoFieldsDef`:**
- Duplicitní `TGeoField` vůči `Test_gdf/GeoRow.pas` znamená nutnost držet dvě definice ručně synchronní.
- V souboru jsou ponechané celé starší zakomentované verze unity. To zhoršuje čitelnost a vyhledávání.
- Názvy fieldů jsou bez diakritiky; může to být záměr kvůli kompatibilitě, ale pro UI by možná stálo za to oddělit interní ASCII identifikátory od lokalizovaných captionů.

**`GeoFieldsGrid.pas`: nová field-driven komponenta**
- Dědí z `TGeoGrid`.
- Má vlastní inplace editor `TGeoFieldsInplaceEdit`, který při `KeyPress` volá `TGeoFieldsGrid.EditorKeyPress`.
- `GeoFields` určuje aktivní sadu sloupců.
- V konstruktoru zkopíruje `GeoFieldColumns` do per-instance `FColumnData`.
- `FColToField` mapuje data-column index na `TGeoField`.
- `FColumnFilters` je runtime kolekce filtrů z `GeoColumnValidation`.
- `RebuildColumns`:
  - spočítá aktivní fieldy,
  - nastaví `FColToField`,
  - nastaví `ColCount`,
  - obnoví default šířky,
  - refreshne hlavičky,
  - refreshne filtry,
  - při nulovém počtu fieldů schová placeholder datový sloupec.
- `RefreshHeaders` plní `ColumnHeaders` včetně placeholderů pro fixed columns a pak volá `UpdateHeaders`.
- `RefreshFilters` dorovnává `FColumnFilters` na počet aktivních fieldů a kopíruje metadata přes `ApplyFieldColumnToFilter`.
- `EditorKeyPress` filtruje podle aktuálního datového sloupce (`Col - FixedCols`).
- `SelectCell` při opuštění buňky volá `TryCommitText`. Pokud commit projde, zapisuje formátovaný text do buňky.
- `FieldToCol`/`ColToField` poskytují bezpečné mapování mezi fieldem a vizuálním sloupcem.
- `SetColumnDisplayName`, `SetColumnFilterData`, `ResetColumnData`, `ResetAllColumnData` podporují per-instance úpravy.
- `ColumnHeaders` a `RowHeaders` jsou znovu deklarované jako public, aby nebyly vidět v Object Inspectoru potomka; u `TGeoFieldsGrid` je má řídit `GeoFields`.

**Dobré na `TGeoFieldsGrid`:**
- Je architektonicky čistší než `TMyFieldsStringGrid`: odděluje field metadata (`GeoFieldsDef`), validaci (`GeoColumnValidation`) a grid (`GeoFieldsGrid`).
- Per-instance kopie field metadat je správně.
- `GeoFields` je jediné hlavní API pro dynamické sloupce.
- Commit formátování je lepší než u staré větve, protože umí `DecimalPlaces`.
- Nepoužívá COM pro výrazy.
- Schování `ColumnHeaders`/`RowHeaders` v OI je dobrý nápad: uživatel komponenty nemá editovat automaticky generované hlavičky ručně.

**Co bych zlepšil u `TGeoFieldsGrid`:**
- Na rozdíl od `TMyFieldsStringGrid` zatím nemá `SetGeoRow`/`GetGeoRow`. Je to tedy výborný grid shell, ale ještě mu chybí doménový import/export řádku.
- `SelectCell` při neplatném commitu neblokuje odchod z buňky ani neukládá nevalidní editor text do `Cells`. Může vzniknout rozdíl mezi tím, co uživatel viděl v editoru, a tím, co zůstalo v buňce.
- `GetColumnFilter(Col - FixedCols)` vrací `nil` pro záporné/špatné indexy přes `ResolveFilter`, což je bezpečné. Přesto by se hodily explicitní guardy u commitů z fixed buněk.
- `RebuildColumns` při změně fieldů neřeší zachování existujících dat. Pro testovací použití stačí, pro produkci by bylo vhodné migrovat hodnoty podle fieldů.
- V souboru je nahoře starší zakomentovaná verze celé unity. Tu bych po stabilizaci odstranil do gitu/tagu, ne držel v aktuálním zdrojáku.

**`MyComponentsR.dpk` a `MyGridReg.pas`:**
- `MyComponentsR.dpk` vyžaduje jen `rtl` a `vcl`, což je dobré: package je lehký a nezávislý na zbytku aplikace.
- Obsahuje všechny nové komponentové unity v jednom adresáři.
- `MyGridReg` registruje `TMyGrid`, `TGeoGrid`, `TGeoFieldsGrid` do palety `MyComponents`.
- `GeoColumnValidation` je v `uses` registrace, ale neregistruje komponentu; pravděpodobně tam je kvůli dostupnosti typů v design-time package. Není to škodlivé.

#### Doporučení ke komponentám

**Co je podle mě nejpovedenější:**
- Směr `TGeoGrid` + `TGeoFieldsGrid` + `GeoColumnValidation` je čistší a perspektivnější než starý `TMyStringGrid` stack.
- Per-instance kopie field metadat v obou field gridech je správná architektura.
- Oddělení statických field definic (`GeoFieldsDef`) od runtime filtrů (`GeoColumnValidation`) je dobré a škálovatelné.
- Vlastní recursive-descent parser v `GeoColumnValidation` je výrazně lepší než COM/VBScript ve starém `ColumnValidation`.
- `FieldToCol`/`ColToField` je přesně typ helperu, který zabraňuje křehkým magickým indexům ve formulářích.

**Co bych sjednotil jako první:**
- Vybrat jeden budoucí základní grid. Za mě je lepší kandidát `TGeoGrid`, ale přenesl bych do něj koncept `CommitCell` z `TMyGrid`.
- Vybrat jeden validační engine. Za mě `GeoColumnValidation`.
- Rozhodnout, jestli `TGeoField` žije v datovém modelu, nebo v komponentové definici. Dvě kopie enumu budou dlouhodobě bolet.
- Přidat do nové větve ekvivalent `SetGeoRow`/`GetGeoRow`, ale navrhnout ho tak, aby nebyl natvrdo závislý na testovací složce.
- Odstranit staré zakomentované celé unity ze souborů v `Komponenty/`, jakmile bude jisté, že historie je v gitu.

**Možný migrační plán:**
1. Nechat `src/Components` stabilní pro existující formuláře.
2. Dopsat do `TGeoFieldsGrid` čtení/zápis řádku nebo adapter na `TGeoRow`.
3. Přidat jasné chování při neplatném commitu: blokovat odchod, zvýraznit buňku, nebo uložit nevalidní text a označit chybu. Hlavně to sjednotit.
4. Převést nový formulář/prototyp (`Unit5`) na cílové UX a ověřit navigaci, paste, desetinné oddělovače a záporné hodnoty.
5. Teprve potom migrovat produkční formuláře ze `src/Components` na `Komponenty`.
6. Po migraci odstranit COM-based `ColumnValidation` nebo ho ponechat jen jako legacy.

**Konkrétní technické resty, které stojí za backlog:**
- Opravit/přehodnotit záporné hodnoty pro `cdtFloat`/`fFloat`.
- Přidat validaci paste scénářů, nejen keypress.
- Přidat chybovou zprávu nebo vizuální stav místo tichého mazání hodnoty.
- Ověřit package cesty v `src/Packages/GeoSoftComponentsR.dpk`.
- Sjednotit názvy palet (`GeoSoft` vs `MyComponents`) podle toho, co má být finální.
- Dopsat malé testy pro `GeoColumnValidation.TryEvaluateExpression`, hlavně precedence, závorky, dělení nulou, locale separator a `DecimalPlaces`.

#### `GeoPointsGrid`

`GeoPointsGrid` je jednoduchý potomek `TGeoGrid` v `Komponenty/GeoPointsGrid.pas`. Má dělat jednu věc navíc: umožnit v Object Inspectoru nastavit validační filtry pro datové sloupce. Je přidaný do `Komponenty/MyComponentsR.dpk` a registrovaný v `Komponenty/MyGridReg.pas`.

**Aktuální přístup:**
- Komponenta zůstává co nejtenčí.
- Dědí navigaci, hlavičky a základní editor z `TGeoGrid`.
- Používá `GeoColumnValidation`.
- Neobsahuje staré callback validátory.
- `ColumnFilters` jsou published, takže se dají nastavovat v návrháři přes collection editor.
- Filtry se počítají jen pro datové sloupce: `ColumnFilters[0]` odpovídá grid sloupci `FixedCols`.
- Validace je záměrně rozdělená na dvě vrstvy: filtrování psaného znaku a commit celé buňky.

**Jednoduchá struktura unity:**
```pascal
TGeoPointsGrid = class(TGeoGrid)
private
  FColumnFilters: TColumnFilters;

  function DataColumnCount: Integer;
  function FilterForCol(ACol: Integer): TColumnFilter;
  procedure EnsureFilterCount;
  procedure SetColumnFilters(const Value: TColumnFilters);
  procedure ColumnFiltersChanged(Sender: TObject);
  procedure FilterTypedChar(const AText: string; var Key: Char);
  procedure ValidateCurrentCell;
protected
  function CreateEditor: TInplaceEdit; override;
  procedure Loaded; override;
  procedure SizeChanged(OldColCount, OldRowCount: Longint); override;
  procedure MoveToNextCell(PressedKey: Word; Shift: TShiftState); override;
published
  property ColumnFilters: TColumnFilters
    read FColumnFilters write SetColumnFilters;
end;
```

**Postup implementace:**
1. Vytvořit `TGeoPointsInplaceEdit = class(TGeoInplaceEdit)`.
2. Přepsat jen `KeyPress`, aby editor zavolal první validační vrstvu `FilterTypedChar`.
3. V `TGeoPointsGrid.CreateEditor` vracet `TGeoPointsInplaceEdit`.
4. V konstruktoru vytvořit `TColumnFilters.Create(Self)`.
5. V `Loaded` a `SizeChanged` dorovnat počet filtrů podle `ColCount - FixedCols`.
6. Ve `FilterTypedChar` najít filtr pro aktuální datový sloupec a zavolat `FilterKeyPress`.
7. V `MoveToNextCell` před inherited navigací zavolat druhou validační vrstvu `ValidateCurrentCell`.
8. Ve `ValidateCurrentCell` zavolat `TryCommitText`; při chybě buňku vymazat a nechat navigaci pokračovat.

**Dvě vrstvy validace:**
- První vrstva běží při psaní v `TGeoPointsInplaceEdit.KeyPress`.
- Tato vrstva volá `FilterKeyPress` a brání uživateli napsat zjevně špatný znak, například písmeno do `cdtInteger`.
- Druhá vrstva běží při Enter/Tab navigaci v `TGeoPointsGrid.MoveToNextCell`.
- Tato vrstva volá `TryCommitText` nad celým textem buňky, takže zachytí i paste nebo syntakticky špatný výraz.
- Když commit projde, zapíše se případně formátovaný text.
- Když commit neprojde, buňka se vymaže, grid pípne přes `MessageBeep(MB_ICONWARNING)` a navigace pokračuje.
- Odchod z buňky se neblokuje ani při chybě.

**Co je záměrně vynechané kvůli přehlednosti:**
- Žádné staré `SetColumnValidator` callbacky.
- Žádná `InvalidCellBehavior` property zatím.
- Žádné automatické bodové hlavičky.
- Žádné `GeoRow`/`TPoint` API.
- Žádná další mezivrstva `TGeoFilteredGrid`.

**Další možné kroky:**
- Pokud se ukáže potřeba, přidat později vizuální označení nevalidních buněk.
- Pokud se bude opakovat potřeba filtrovat i jiné gridy, vyčlenit obecný `TGeoFilteredGrid`.
- Pokud má být `GeoPointsGrid` opravdu bodový grid, přidat později metodu/property pro výchozí sloupce `Číslo bodu`, `X`, `Y`, `Z`, `Kvalita`, `Popis`.

### Packages (`src/Packages`)
- `GeoSoftComponentsR.dpk`: starší runtime/design package pro `src/Components`. V `contains` aktuálně odkazuje `MyFieldsStringGrid in 'MyFieldsStringGrid.pas'` a `GeoFieldColumn in 'GeoFieldColumn.pas'`, přestože soubory leží v `src/Components`; je to podezřelé a stojí za ověření v Delphi.
- `dclusr.dpk`: uživatelský package závislý na `GeoSoftComponentsR`.

### Test_gdf
- `GeoRow.pas`: enum `TGeoField`, set `TGeoFields`, record `TGeoRow`, pole názvů a CSV/BIN helpery.
- `GeoDataFrame.pas`: tabulkový kontejner `TGeoDataFrame` nad `TGeoRowArray`, CSV/BIN serializace a tisk.
- `TestGeoRow.dpr`, `TestGeoDataFrame.dpr`: konzolové testy datového modelu.

### Test_FieldGrid
- `GeoFieldColumn.pas`: lokální kopie field metadata pro testovací projekt.
- `GeoFieldsStringGrid.pas`: starší field-driven grid pro `TGeoField`, dnes produkčně nahrazovaný `src/Components/MyFieldsStringGrid.pas`.
- `Test_FieldGrid.pas`: testovací formulář se `CheckListBox` pro výběr polí.
- `TestFieldGrid.dpr`: samostatný VCL testovací projekt.

### Console (`src/Console`)
- `GeoSoftConsole.dpr`: konzolový vstupní bod.
- `PolarTest.dpr`, `OrthogonalTest.dpr`: konzolové testy algoritmů z `src/Utils`.

## 2) Hlavní vstupní body

### DPR programy
- Hlavní GUI: `src/GUI/GeoSoft.dpr`
- Console app: `src/Console/GeoSoftConsole.dpr`
- Console testy: `src/Console/PolarTest.dpr`, `src/Console/OrthogonalTest.dpr`
- Algoritmické testy: `src/GeoAlgorithms/PolarTest.dpr`, `src/GeoAlgorithms/PolarTest2.dpr`, `src/GeoAlgorithms/OrthogonalTest.dpr`, `src/GeoAlgorithms/TransformTest.dpr`, `src/GeoAlgorithms/TransformTestTXT.dpr`, `src/GeoAlgorithms/TestReadTXT.dpr`
- GDF testy: `Test_gdf/TestGeoRow.dpr`, `Test_gdf/TestGeoDataFrame.dpr`
- FieldGrid test: `Test_FieldGrid/TestFieldGrid.dpr`

### Formy vytvořené v `GeoSoft.dpr`
- `TForm1` / `Form1` (`MainForm`)
- `TPointsManagementForm` / `PointsManagementForm`
- `TParcelAreaForm` / `ParcelAreaForm`
- `TOrthogonalMethodForm` / `OrthogonalMethodForm`
- `TTransformationForm` / `TransformationForm`
- `TAddPointForm` / `AddPointForm`
- `TCheckMeasurementForm` / `CheckMeasurementForm`
- `TPolarMethodForm` / `PolarMethodForm`
- `TForm2` / `Form2` (`TestFieldGrid`)
- `TForm5` / `Form5` (`Unit5`)

Datamodul v projektu nebyl nalezen.

## 3) Důležité vazby

- `MainForm` otevírá hlavní formuláře a zároveň tahá do interface řadu komponent i staré DB/Web unity.
- `PointsManagement`, `AddPoint`, `OrthogonalMethod` a `PolarMethod` sdílejí `PointPrefixState`, `PointsUtilsSingleton`, `InputFilterUtils` a grid validace.
- `ParcelArea` a utils `OrthogonalMethod` používají algoritmy ze `src/Utils`.
- `PolarMethod` pracuje s `GeoRow`/`GeoDataFrame` z `Test_gdf` a ukládá polární vstupy do souborů.
- `MyFieldsStringGrid` používá `GeoRow`, `GeoFieldColumn`, `ColumnValidation` a `MyStringGrid`.
- `TGeoFieldsGrid` používá samostatné definice z `Komponenty/GeoFieldsDef.pas` a validace z `Komponenty/GeoColumnValidation.pas`.
- `GeoAlgorithmBase`, `GeoAlgorithmPolar` a `GeoAlgorithmOrthogonal` existují duplicitně ve `src/Utils` i `src/GeoAlgorithms`; stejně pojmenované unity se liší implementací.

## 4) Riziková a křehká místa

- **Globální stav:** `TPointDictionary.GetInstance`, `GPointPrefix`, globální instance formulářů a globální proměnné v `PointsManagement`.
- **Duplicitní názvy unit:** `GeoAlgorithmBase`, `GeoAlgorithmPolar`, `GeoAlgorithmOrthogonal` jsou ve dvou adresářích. Výsledek závisí na search path / explicitním `in`.
- **Dvě komponentové větve:** `src/Components` a `Komponenty` řeší podobné problémy jinak (`ColumnValidation` vs `GeoColumnValidation`, `GeoFieldColumnData` vs `GeoFieldColumns`).
- **Podezřelé package cesty:** `src/Packages/GeoSoftComponentsR.dpk` má u některých `contains` cestu bez `..\Components\`.
- **Zakomentované staré verze:** `Komponenty/GeoFieldsDef.pas`, `Komponenty/GeoFieldsGrid.pas` a `src/GUI/Unit5.pas` obsahují celé starší zakomentované unity před aktivním kódem.
- **Stará DB/Web závislost v GUI:** `MainForm.pas` stále importuje `Data.DB`, `Vcl.DBGrids`, `Web.HTTPApp`, `Web.DBWeb`, `Web.DBXpressWeb`.
- **Synchronní souborové I/O v GUI:** import/export bodů a ukládání `GeoDataFrame` běží přímo z formulářů.

## 5) Změny proti předchozí mapě

- `PolarMethod.pas` už není mrtvá/zakomentovaná unit; je to aktivní `TPolarMethodForm`.
- `PolarMethodNew.pas` a `CalcFormBase.pas` nejsou v aktuálním stromu.
- Přibyl/je aktivní `ParcelArea.pas` jako `TParcelAreaForm`.
- Přibyl GUI test `src/GUI/TestFieldGrid.pas` pro `TMyFieldsStringGrid`.
- Přibyl GUI test `src/GUI/Unit5.pas` pro `TGeoFieldsGrid`.
- V `Komponenty/` jsou nově klíčové `GeoColumnValidation.pas`, `GeoFieldsDef.pas` a `GeoFieldsGrid.pas`; package `MyComponentsR.dpk` registruje i `TGeoFieldsGrid`.
- Mapa je přepsaná do čitelné češtiny v UTF-8, protože původní soubor měl rozpadlou diakritiku.
