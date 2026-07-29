---
title: "Technische Dokumentation"
subtitle: "Markdown-zu-PDF Proof of Concept"
author: "Hans Schulze"
approved_by: "Projektleitung"
unit: "Digital Experience"
issue_date: "29.07.2026"
revision: "0.1"
document_id: "STORM-PANDOC-POC-001"
customer: "Beispielkunde GmbH"
privacy_notes: "Kundenvertraulich"
change_summary: "Erste automatisch aus Markdown erzeugte Fassung."
toc: true
revisions:
  - revision: "0.1"
    date: "29.07.2026"
    change: "Initialer Proof of Concept"
    approved: "Entwurf"
attachments:
  - "Architekturübersicht"
  - "Konfigurationsbeispiel"
---

# Einführung

Dieses Dokument wurde vollständig aus **Markdown** erzeugt. Inhalte und Metadaten sind damit von der Gestaltung getrennt; das Corporate Design wird zentral durch das Pandoc-Template vorgegeben.

## Zielsetzung

Der Proof of Concept prüft:

- Arial und Arial Black als verbindliche Schriften
- Storm-Reply-Titelseite und Farbsystem
- automatische Kopf- und Fußzeilen
- Inhaltsverzeichnis und Kapitelnummerierung
- Tabellen, Listen, Links und technische Inhalte

## Referenzen

Die PDF wird mit [Pandoc](https://pandoc.org/) und LuaLaTeX erzeugt. Änderungen am Inhalt erfordern keine manuelle Bearbeitung in Word.

# Dokumentstruktur

## Metadaten

Wiederkehrende Dokumentinformationen stehen im YAML-Block am Anfang der Markdown-Datei. Sie werden auf der Titelseite, in Kopf- und Fußzeilen sowie in der Revisionsübersicht wiederverwendet.

| Feld | Beispiel | Verwendung |
|:---|:---|:---|
| `title` | Technische Dokumentation | Titelseite und Kopfzeile |
| `revision` | 0.1 | Titelseite, Kopf- und Fußzeile |
| `document_id` | STORM-PANDOC-POC-001 | Dokumentkennung |
| `approved_by` | Projektleitung | Freigabeinformation |

## Abbildungen

Normale Markdown-Bildsyntax kann für Screenshots, Diagramme und Architekturgrafiken verwendet werden:

![Storm-Reply-Farbverlauf als Beispielabbildung](assets/image1.png){width=72%}

# Technisches Beispiel

## Konfiguration

Eine typische Datei wird mit einem einzigen Build-Schritt übersetzt:

```text
pandoc sample.md \
  --template storm-reply.latex \
  --pdf-engine=lualatex \
  --number-sections \
  --output dokument.pdf
```

## Qualitätskriterien

1. Alle Schriften sind in der PDF eingebettet.
2. Seitenzahlen, Inhaltsverzeichnis und Kapitelnummern werden automatisch aktualisiert.
3. Lange Tabellen und Abbildungen bleiben innerhalb des Satzspiegels.
4. Derselbe Build erzeugt auf jedem freigegebenen System ein reproduzierbares Ergebnis.

# Fazit

Der Prototyp demonstriert den Kern des gewünschten Workflows. Als nächster Schritt können weitere Bausteine wie Hinweisboxen, kundenspezifische Deckblätter, Quellcode-Hervorhebung und verschiedene Dokumentvarianten ergänzt werden.
