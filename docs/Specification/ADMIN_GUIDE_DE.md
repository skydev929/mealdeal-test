# Administratorhandbuch

## Administrator-Zugriff

### Administrator-Zugriff erhalten

1. **Registrieren/Anmelden:**
   - Erstellen Sie ein Konto oder melden Sie sich mit einem bestehenden Konto an
   - Standardrolle ist "Benutzer"

2. **Administrator-Rolle zuweisen:**
   - Kontaktieren Sie den Systemadministrator
   - Administrator muss SQL ausführen, um die Rolle zuzuweisen:
     ```sql
     INSERT INTO user_roles (user_id, role)
     VALUES ('ihre-benutzer-id', 'admin');
     ```

3. **Dashboard-Zugriff:**
   - Melden Sie sich mit dem Administrator-Konto an
   - Navigieren Sie zu `/admin/dashboard`

## Admin-Dashboard Übersicht

### Navigation

- **Daten importieren Tab:** CSV-Import-Funktionalität
- **Daten anzeigen Tab:** Datenbanktabellen durchsuchen
- **Abmelden:** Abmelde-Button im Header

## CSV-Import-System

### Übersicht

Das CSV-Import-System ermöglicht Administratoren den Massenimport von Daten in die Datenbank. Es unterstützt Validierung, Fehlerberichterstattung und Dry-Run-Modus.

### Unterstützte Tabellen

1. **Nachschlagetabellen:**
   - `lookups_categories` - Gerichtskategorien
   - `lookups_units` - Maßeinheiten

2. **Standortdaten:**
   - `chains` - Supermarktketten
   - `ad_regions` - Werberegionen
   - `stores` - Filialstandorte
   - `postal_codes` - Postleitzahl-Zuordnungen
   - `store_region_map` - Filiale-Region-Beziehungen

3. **Produktdaten:**
   - `ingredients` - Zutaten
   - `dishes` - Gerichte/Rezepte
   - `dish_ingredients` - Gericht-Zutat-Beziehungen
   - `product_map` - Produktzuordnungen

4. **Angebote:**
   - `offers` - Aktuelle Supermarkt-Angebote

### Import-Prozess

#### Schritt 1: CSV-Datei vorbereiten

**Anforderungen:**
- CSV-Format (kommagetrennt)
- Erste Zeile muss Header (Spaltennamen) enthalten
- Header müssen exakt mit Datenbankspaltennamen übereinstimmen
- UTF-8-Kodierung empfohlen

**Beispiel-CSV (Angebote):**
```csv
region_id,ingredient_id,price_total,pack_size,unit_base,valid_from,valid_to,source,source_ref_id
500,I001,2.99,500,g,2025-01-13,2025-01-19,aldi,OFFER123
500,I002,1.49,1,l,2025-01-13,2025-01-19,lidl,OFFER456
```

#### Schritt 2: CSV hochladen

1. Gehen Sie zum Tab "Daten importieren"
2. Klicken Sie auf "Datei auswählen" oder ziehen Sie die Datei per Drag & Drop
3. Wählen Sie die CSV-Datei von Ihrem Computer aus
4. Wählen Sie den Tabellentyp aus dem Dropdown-Menü
5. Wählen Sie den Modus:
   - **Dry Run:** Validiert ohne zu importieren
   - **Importieren:** Validiert und importiert Daten

#### Schritt 3: Ergebnisse prüfen

**Dry-Run-Ergebnisse:**
- Anzahl gültiger Zeilen
- Liste der Fehler (falls vorhanden)
- Keine Daten importiert

**Import-Ergebnisse:**
- Anzahl gültiger Zeilen
- Anzahl importierter Zeilen
- Liste der Fehler (falls vorhanden)

### CSV-Format-Spezifikationen

#### Angebote CSV

**Erforderliche Spalten:**
- `region_id` - Ganzzahl (muss in ad_regions existieren)
- `ingredient_id` - Text (I001-Format) oder Ganzzahl (automatisch konvertiert)
- `price_total` - Dezimal (z. B. 2.99 oder 2,99)
- `pack_size` - Dezimal (z. B. 500.0)
- `unit_base` - Text (muss in lookups_units existieren)
- `valid_from` - Datum (JJJJ-MM-TT)
- `valid_to` - Datum (JJJJ-MM-TT)

**Optionale Spalten:**
- `source` - Text
- `source_ref_id` - Text

**Beispiel:**
```csv
region_id,ingredient_id,price_total,pack_size,unit_base,valid_from,valid_to,source
500,I001,2.99,500,g,2025-01-13,2025-01-19,aldi
501,I002,1.49,1,l,2025-01-13,2025-01-19,lidl
```

#### Gerichte CSV

**Erforderliche Spalten:**
- `dish_id` - Text (eindeutige Kennung)
- `name` - Text
- `category` - Text (muss in lookups_categories existieren)
- `is_quick` - Boolean (WAHR/FALSCH)
- `is_meal_prep` - Boolean (WAHR/FALSCH)

**Optionale Spalten:**
- `season` - Text
- `cuisine` - Text
- `notes` - Text

**Beispiel:**
```csv
dish_id,name,category,is_quick,is_meal_prep,season,cuisine
D001,Spaghetti Carbonara,Hauptgericht,FALSCH,FALSCH,,
D002,Schnelle Pasta,Hauptgericht,WAHR,FALSCH,,
```

#### Zutaten CSV

**Erforderliche Spalten:**
- `ingredient_id` - Text (I001-Format)
- `name_canonical` - Text
- `unit_default` - Text (muss in lookups_units existieren)

**Optionale Spalten:**
- `price_baseline_per_unit` - Dezimal
- `allergen_tags` - Text (kommagetrennt)
- `notes` - Text

**Beispiel:**
```csv
ingredient_id,name_canonical,unit_default,price_baseline_per_unit,allergen_tags
I001,Tomaten,kg,2.99,"Gluten,Soja"
I002,Milch,l,1.29,"Milch"
```

#### Gericht-Zutaten CSV

**Erforderliche Spalten:**
- `dish_id` - Text (muss in dishes existieren)
- `ingredient_id` - Text (muss in ingredients existieren)
- `qty` - Dezimal
- `unit` - Text (muss in lookups_units existieren)
- `optional` - Boolean (WAHR/FALSCH)

**Optionale Spalten:**
- `role` - Text

**Beispiel:**
```csv
dish_id,ingredient_id,qty,unit,optional,role
D001,I001,500,g,FALSCH,main
D001,I002,2,stück,FALSCH,
D001,I003,1,TL,WAHR,
```

### Import-Reihenfolge

**Kritisch:** Importieren Sie Daten in dieser Reihenfolge, um Fremdschlüssel-Fehler zu vermeiden:

1. **Nachschlagetabellen:**
   - `lookups_categories`
   - `lookups_units`

2. **Standortdaten:**
   - `chains`
   - `ad_regions`
   - `stores`
   - `postal_codes`
   - `store_region_map`

3. **Produktdaten:**
   - `ingredients`
   - `dishes`
   - `dish_ingredients`
   - `product_map`

4. **Angebote:**
   - `offers` (zuletzt, hängt von allen oben genannten ab)

### Häufige Fehler & Lösungen

#### "Foreign key constraint violation" (Fremdschlüssel-Verletzung)

**Ursache:** Referenzierte Daten existieren nicht

**Lösungen:**
- Importieren Sie referenzierte Tabellen zuerst
- Überprüfen Sie, dass IDs exakt übereinstimmen
- Verifizieren Sie, dass Daten in der übergeordneten Tabelle existieren

**Beispiel:**
- Fehler: `ingredient_id "I999" nicht gefunden`
- Lösung: Importieren Sie zuerst die Zutaten-CSV, stellen Sie sicher, dass I999 existiert

#### "Ungültiges Datumsformat"

**Ursache:** Datum nicht im Format JJJJ-MM-TT

**Lösungen:**
- Verwenden Sie das Format: `2025-01-13`
- Keine Schrägstriche oder Punkte
- Führende Nullen einschließen

**Beispiel:**
- Falsch: `1/13/2025`, `13.01.2025`
- Richtig: `2025-01-13`

#### "Ungültige Zahl"

**Ursache:** Nicht-numerischer Wert in Zahlenfeld

**Lösungen:**
- Verwenden Sie nur Zahlen (Dezimalzahlen mit Punkt oder Komma)
- Keine Währungssymbole
- Kein Text in Zahlenfeldern

**Beispiel:**
- Falsch: `€2.99`, `2,99 EUR`
- Richtig: `2.99` oder `2,99`

#### "Einheit nicht gefunden"

**Ursache:** Einheit existiert nicht in lookups_units

**Lösungen:**
- Importieren Sie zuerst die Einheiten-Nachschlagetabelle
- Überprüfen Sie, dass der Einheitenname exakt übereinstimmt (Groß-/Kleinschreibung beachten)
- Häufige Einheiten: `g`, `kg`, `ml`, `l`, `stück`, `st`

#### "Falsche Anzahl von Spalten"

**Ursache:** Zusätzliche Kommas oder fehlende Werte

**Lösungen:**
- Prüfen Sie auf nachgestellte Kommas
- Stellen Sie sicher, dass alle Zeilen die gleiche Spaltenanzahl haben
- Verwenden Sie leere Werte (nicht fehlend) für optionale Felder

### Best Practices

1. **Immer zuerst Dry Run verwenden:**
   - Validiert Daten vor dem Import
   - Behebt Fehler vor dem Live-Import
   - Spart Zeit und verhindert fehlerhafte Daten

2. **In Reihenfolge importieren:**
   - Befolgen Sie die Import-Reihenfolge-Anleitung
   - Überspringen Sie keine Schritte
   - Verifizieren Sie jeden Schritt vor dem Fortfahren

3. **Datenqualität validieren:**
   - Prüfen Sie auf Duplikate
   - Stellen Sie sicher, dass Datumsbereiche gültig sind
   - Überprüfen Sie Fremdschlüssel-Referenzen

4. **Backups behalten:**
   - Exportieren Sie Daten vor größeren Imports
   - Behalten Sie CSV-Dateien als Referenz
   - Dokumentieren Sie Import-Daten

5. **Mit kleinen Dateien testen:**
   - Beginnen Sie mit 10-20 Zeilen
   - Verifizieren Sie Ergebnisse
   - Skalieren Sie hoch, sobald bestätigt

## Daten anzeigen

### Daten-Tabellen-Browser

1. **Tabelle auswählen:**
   - Wählen Sie Tabelle aus dem Dropdown-Menü
   - Klicken Sie auf "Daten laden"

2. **Daten anzeigen:**
   - Tabelle zeigt Zeilen an
   - Paginierung für große Tabellen
   - Suche und Filter (falls implementiert)

### Verfügbare Tabellen

Alle Datenbanktabellen sind einsehbar:
- Produktdaten (Gerichte, Zutaten)
- Standortdaten (Ketten, Filialen, Regionen)
- Angebotsdaten
- Nachschlagetabellen
- Benutzerdaten (Profile, Rollen, Favoriten)

## Datenverwaltung

### Daten aktualisieren

**Methode 1: CSV-Import (Upsert)**
- Importieren Sie CSV mit bestehenden IDs
- System aktualisiert bestehende Zeilen
- Fügt neue Zeilen hinzu, wenn ID nicht existiert

**Methode 2: Direkter Datenbankzugriff**
- Verwenden Sie Supabase SQL-Editor
- Führen Sie UPDATE-Anweisungen aus
- Mehr Kontrolle, erfordert jedoch SQL-Kenntnisse

### Daten löschen

**Kaskadierte Löschungen:**
- Löschen eines Gerichts löscht dish_ingredients
- Löschen einer Kette löscht Filialen und Regionen
- Seien Sie vorsichtig bei Löschungen

**Sicheres Löschen:**
- Prüfen Sie Abhängigkeiten zuerst
- Verwenden Sie Soft Deletes (als inaktiv markieren), wenn möglich
- Behalten Sie Backups

### Datenvalidierung

**Regelmäßige Prüfungen:**
- Verifizieren Sie, dass Angebotsdaten aktuell sind
- Prüfen Sie auf verwaiste Datensätze
- Validieren Sie Preisberechnungen
- Überwachen Sie Fehlerprotokolle

## Fehlerbehebung

### Import schlägt vollständig fehl

**Prüfen:**
- Dateiformat (muss CSV sein)
- Dateikodierung (UTF-8)
- Dateigröße (nicht zu groß)
- Netzwerkverbindung

### Teilweiser Import-Erfolg

**Fehler prüfen:**
- Einige Zeilen importiert, einige fehlgeschlagen
- Prüfen Sie Fehlerliste auf Muster
- Beheben Sie Fehler und importieren Sie fehlgeschlagene Zeilen erneut

### Daten werden in App nicht angezeigt

**Mögliche Ursachen:**
- Angebote abgelaufen (Daten prüfen)
- Fehlende Regionszuordnung
- RLS-Richtlinien blockieren Zugriff

**Lösungen:**
- Verifizieren Sie Daten in der Datenbank
- Prüfen Sie RLS-Richtlinien
- Testen Sie mit Administrator-Konto

### Leistungsprobleme

**Große Imports:**
- Aufteilen in kleinere Dateien
- Importieren Sie in Batches
- Überwachen Sie Datenbankleistung

**Langsame Abfragen:**
- Prüfen Sie Datenbankindizes
- Optimieren Sie Abfragen
- Kontaktieren Sie Supabase-Support

## Sicherheitsüberlegungen

### Zugriffskontrolle

- Nur Administratoren können auf Dashboard zugreifen
- RLS-Richtlinien gelten weiterhin
- Edge-Funktion verwendet Service-Rollen-Schlüssel

### Datenschutz

- Exportieren Sie keine Benutzerdaten ohne Genehmigung
- Bewahren Sie CSV-Dateien sicher auf
- Teilen Sie keine Administrator-Anmeldedaten

### Audit-Trail

- Dokumentieren Sie alle Imports
- Behalten Sie Import-Protokolle
- Verfolgen Sie Datenänderungen

## Support

**Bei Administrator-Problemen:**
- Prüfen Sie dieses Handbuch zuerst
- Überprüfen Sie Fehlermeldungen sorgfältig
- Kontaktieren Sie den Systemadministrator
- Prüfen Sie Supabase-Protokolle

**Bei technischen Problemen:**
- Überprüfen Sie Datenbankschema
- Prüfen Sie Migrationsdateien
- Konsultieren Sie technische Dokumentation

---

**Denken Sie daran:** Verwenden Sie immer zuerst den Dry-Run-Modus und importieren Sie Daten in der richtigen Reihenfolge!


















