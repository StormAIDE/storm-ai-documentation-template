# Storm Reply Markdown-to-PDF Proof of Concept

## Voraussetzungen

- macOS mit Arial und Arial Black unter `/System/Library/Fonts/Supplemental/`
- Pandoc 3
- LuaLaTeX

## PDF erzeugen

```bash
bash build.sh
```

Die Inhalte und Dokumentmetadaten stehen in `sample.md`. Das Corporate Design
wird zentral in `storm-reply.latex` definiert. Die Datei
`assets/image1.png` stammt aus dem bestehenden Storm-Reply-Word-Template und
wird als Hintergrund der Titelseite verwendet.

Für einen späteren plattformübergreifenden oder CI-basierten Build sollten die
freigegebenen Arial-Dateien kontrolliert bereitgestellt und die Schriftpfade im
Template entsprechend konfiguriert werden.
