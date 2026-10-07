# Seznam souřadnic

Seznam souřadnic je slovník bodů: klíčem je číslo bodu, hodnotou záznam
`TPoint`. Existuje jediný seznam pro celý program, takže okno seznamu
i všechny výpočty pracují se stejnými body.

Seznam se skládá z vrstev, od nejmenší po okno:

| vrstva | stránka | unit |
|---|---|---|
| jeden bod | [Bod](bod.md), [Validace](validace.md) | `Point.pas`, `ValidationUtils.pas` |
| všechny body | [Seznam bodů](seznam-bodu.md) | `PointsUtilsSingleton.pas` |
| soubory | [Ukládání](ukladani.md), [Import a export](import-export.md) | `PointsUtilsSingleton.pas` |
| pomocné | [Pořadí souřadnic](poradi-souradnic.md), [Čísla bodů](cisla-bodu.md) | `CoordOrderState.pas`, `PointPrefixState.pas` |
| okna | [Formulář](formular.md), [Přidat bod](pridat-bod.md) | `PointsManagement.pas`, `AddPoint.pas` |

Každá vrstva používá jen vrstvy nad sebou: okno pracuje se seznamem,
seznam s body, bod se o seznamu ani o okně nedozví.
