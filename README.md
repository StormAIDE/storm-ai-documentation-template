# Storm Reply Markdown-to-PDF

Konvertiert Dokumente verschiedener Formate in PDF mit Storm-Reply-Corporate-Design.

## Voraussetzungen

- macOS mit Arial und Arial Black unter `/System/Library/Fonts/Supplemental/`
- Pandoc 3
- LuaLaTeX
- LibreOffice (nur für echte `.doc`-Binärdateien)

## PDF erzeugen

```bash
bash build.sh [eingabedatei]
```

Ohne Argument wird `sample.md` verwendet.

### Unterstützte Formate

| Erweiterung | Verarbeitung |
|---|---|
| `.md`, `.markdown` | Pandoc Markdown |
| `.rst` | reStructuredText |
| `.html`, `.htm` | HTML |
| `.docx` | Word Open XML |
| `.doc` | MIME/HTML-Export (z. B. Confluence) oder Word-Binärformat via LibreOffice |
| `.tex` | LaTeX |

### Beispiele

```bash
bash build.sh sample.md
bash build.sh Anforderungen.docx
bash build.sh Export-aus-Confluence.doc
```

Die Ausgabedatei wird automatisch aus dem Eingabeinamen abgeleitet (z. B.
`Anforderungen.pdf`).

## Dokumentmetadaten

Storm-spezifische Metadaten werden als YAML-Frontmatter in `.md`-Dateien
oder als Pandoc-Metadaten übergeben. Alle Felder sind optional — fehlen sie,
werden die entsprechenden Abschnitte (Dokumentstatus, Änderungsübersicht,
Anlagen) im PDF ausgelassen.

| Feld | Beschreibung |
|---|---|
| `title` | Dokumenttitel |
| `subtitle` | Untertitel |
| `author` | Erstellt von |
| `approved_by` | Freigegeben von |
| `revision` | Revisionsnummer |
| `issue_date` | Ausgabedatum |
| `document_id` | Dokumentnummer |
| `unit` | Bereich |
| `privacy_notes` | Vertraulichkeitshinweis |
| `change_summary` | Änderungsübersicht |
| `revisions` | Liste der Revisionseinträge |
| `attachments` | Liste der Anlagen |

Beispiel siehe `sample.md`.

## Projektstruktur

| Datei | Zweck |
|---|---|
| `build.sh` | Build-Skript mit Formaterkennung |
| `storm-reply.latex` | Pandoc-Template mit Corporate Design |
| `drop-raw.lua` | Lua-Filter: bereinigt eingebettetes HTML/CSS aus Word-Exporten und konvertiert Confluence-Codeblöcke |
| `assets/image1.png` | Titelbild (aus Storm-Reply-Word-Template) |
| `sample.md` | Beispieldokument mit allen Metadatenfeldern |

## Hinweise

- `--number-sections` wird nur für Textformate (Markdown, RST, LaTeX) gesetzt;
  Word- und HTML-Dokumente haben häufig bereits nummerierte Überschriften.
- Temporäre Zwischendateien (`.docx`, `_mime.html`) werden nach dem Build
  automatisch gelöscht.
- Für einen plattformübergreifenden oder CI-basierten Build müssen die
  Arial-Schriftdateien kontrolliert bereitgestellt und die Schriftpfade im
  Template konfiguriert werden.
