# Ukládání

Seznam souřadnic se ukládá do binárního souboru: body jsou zapsány
za sebou přesně tak, jak leží v paměti (69 bajtů na bod), bez hlavičky.
Pořadí souřadnic určuje přípona: `.yxz` ukládá Y před X (výchozí),
`.xyz` ukládá X před Y. Soubor s jinou příponou program odmítne.
Souřadnice se ukládají v plné přesnosti.
Soubor se při otevření nejdřív celý přečte; když se to nepovede,
otevřený seznam zůstane beze změny.

Ukládá `ExportToBinary`, otevírá `LoadFromBinary`; pořadí z přípony
zjistí `FileOrder`. Popis bodu se ukládá jeden znak na bajt v kódování
Windows, znaky mimo něj se změní na `?`.
