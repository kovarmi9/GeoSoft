# Bod `TPoint`

`TPoint` je záznam (`record`), tedy hodnotový typ: vzniká deklarací proměnné,
neuvolňuje se a přiřazením se kopíruje celý obsah. Seznam souřadnic proto
vrací kopii bodu; změna kopie se v seznamu projeví až jejím uložením.

Záznam obsahuje číslo bodu (`Int64`, 15 číslic), souřadnice `X`, `Y`, `Z`
(`Double`), kód kvality 0–8 a popis do 32 znaků.
Má pevnou velikost 69 bajtů (`packed`), v této podobě se ukládá do binárního souboru.

Jedinou metodou je konstruktor, který zkontroluje hodnoty a vrátí hotový bod:
`P := TPoint.Create(Cislo, X, Y, Z, KK, 'popis');`
