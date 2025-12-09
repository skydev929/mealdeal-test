# Benutzerhandbuch

## Erste Schritte

### Konto erstellen

1. **Zur Anmeldeseite navigieren**
   - Klicken Sie auf "Registrieren" oder navigieren Sie zu `/login`
   - Wechseln Sie bei Bedarf in den "Registrieren"-Modus

2. **Informationen eingeben**
   - **E-Mail:** Ihre E-Mail-Adresse (erforderlich)
   - **Passwort:** Mindestens 6 Zeichen (erforderlich)
   - **Benutzername:** Optionaler Anzeigename
   - **PLZ:** Optionale Postleitzahl (kann später festgelegt werden)

3. **Absenden**
   - Klicken Sie auf "Registrieren"
   - Falls eine E-Mail-Bestätigung erforderlich ist, prüfen Sie Ihr E-Mail-Postfach
   - Melden Sie sich nach der Bestätigung an

### Anmelden

1. Geben Sie Ihre E-Mail-Adresse und Ihr Passwort ein
2. Klicken Sie auf "Anmelden"
3. Sie werden zur Hauptseite weitergeleitet

## Hauptfunktionen

### Standort festlegen

**Warum ist das wichtig:**
- Supermarkt-Angebote variieren je nach Region
- Preise werden basierend auf Angeboten in Ihrer Region berechnet
- Es werden nur Gerichte mit verfügbaren Angeboten in Ihrer Region angezeigt

**So legen Sie Ihren Standort fest:**
1. Auf der Hauptseite finden Sie das PLZ-Eingabefeld im Hero-Bereich
2. Geben Sie Ihre deutsche Postleitzahl ein (z. B. "10115" für Berlin)
3. Klicken Sie auf "Aktualisieren" oder drücken Sie Enter
4. Das System validiert Ihre PLZ und aktualisiert Ihren Standort

**Hinweis:** Wenn Ihre PLZ nicht gefunden wird, ist sie möglicherweise noch nicht in unserer Datenbank. Kontaktieren Sie den Support, um Ihren Bereich hinzuzufügen.

### Gerichte durchsuchen

**Hauptansicht:**
- Raster mit Gerichtskarten, die verfügbare Mahlzeiten anzeigen
- Jede Karte zeigt:
  - Gerichtsname
  - Kategorie-Badge
  - Aktueller Preis (mit angewendeten Angeboten)
  - Grundpreis (falls abweichend)
  - Ersparnisbetrag und -prozentsatz
  - Anzahl verfügbarer Angebote
  - Favoriten-Button

**Gerichte filtern:**

1. **Kategorie-Filter:**
   - Wählen Sie eine Kategorie aus dem Dropdown-Menü
   - Optionen: Alle, Hauptgericht, Dessert, etc.
   - "Alle" zeigt Gerichte aus allen Kategorien

2. **Ketten-Filter:**
   - Wählen Sie eine Supermarktkette
   - Zeigt nur Gerichte mit Angeboten von dieser Kette
   - Optionen hängen von Ihrer PLZ-Region ab

3. **Preis-Filter:**
   - Verwenden Sie den Schieberegler, um den Maximalpreis festzulegen
   - Es werden nur Gerichte zu diesem Preis oder darunter angezeigt
   - Standard: €30

4. **Schnelle Mahlzeiten umschalten:**
   - Aktivieren, um nur schnelle Mahlzeiten (< 30 Min. Zubereitung) anzuzeigen
   - Nützlich für geschäftige Wochentage

5. **Meal Prep umschalten:**
   - Aktivieren, um nur Meal-Prep-Gerichte anzuzeigen
   - Gut für Wochenend-Kochen

**Gerichte sortieren:**
- **Preis (Niedrig):** Günstigste Gerichte zuerst
- **Ersparnis (Hoch):** Beste Ersparnisse zuerst
- **Name (A-Z):** Alphabetische Reihenfolge

### Gerichtsdetails anzeigen

1. **Klicken Sie auf eine Gerichtskarte**, um Details anzuzeigen
2. **Gerichtsinformationen:**
   - Vollständiger Gerichtsname
   - Kategorie und Tags (Schnell, Meal Prep, Küche, Saison)
   - Preiszusammenfassung mit Ersparnissen
   - Notizen (falls verfügbar)

3. **Zutatenliste:**
   - **Erforderliche Zutaten:**
     - Zutatenname
     - Menge und Einheit
     - Aktueller Preis (mit Angebot, falls verfügbar)
     - Grundpreis (falls abweichend)
     - "Im Angebot"-Badge, wenn ein Angebot existiert
   - **Optionale Zutaten:**
     - Gleiche Informationen wie bei erforderlichen
     - Als "Optional" markiert

4. **Preisaufschlüsselung:**
   - Gesamtkosten der Zutaten
   - Aktueller Preis vs. Grundpreis
   - Ersparnisbetrag und -prozentsatz

### Favoriten verwenden

**Zu Favoriten hinzufügen:**
1. Klicken Sie auf das Herz-Symbol auf einer beliebigen Gerichtskarte
2. Das Herz füllt sich rot
3. Eine Erfolgsmeldung erscheint

**Aus Favoriten entfernen:**
1. Klicken Sie auf das gefüllte Herz-Symbol
2. Das Herz wird leer
3. Eine Erfolgsmeldung erscheint

**Favoriten anzeigen:**
1. Klicken Sie auf den "Favoriten"-Tab auf der Hauptseite
2. Sehen Sie alle Ihre favorisierten Gerichte
3. Badge zeigt die Anzahl der Favoriten
4. Filter und Sortierung funktionieren wie bei "Alle Gerichte"

**Anwendungsfälle:**
- Speichern Sie Gerichte, die Sie diese Woche kochen möchten
- Erstellen Sie eine persönliche Rezeptsammlung
- Schneller Zugriff auf Ihre bevorzugten Mahlzeiten

## Preise verstehen

### Wie Preise berechnet werden

1. **Grundpreis:**
   - Summe aller Grundpreise der erforderlichen Zutaten
   - Verwendet Standard-Marktpreise
   - Repräsentiert die "normale" Kosten

2. **Angebotspreis:**
   - Verwendet aktuelle Supermarkt-Angebote, wenn verfügbar
   - Berechnet pro Zutat:
     - Wenn Angebot existiert: `(Menge / Packungsgröße) × Angebotspreis`
     - Wenn kein Angebot: Verwendet Grundpreis
   - Summe aller Zutaten-Angebotspreise

3. **Ersparnis:**
   - Differenz: `Grundpreis - Angebotspreis`
   - Prozentsatz: `(Ersparnis / Grundpreis) × 100`

### Preisanzeige

- **Grünes Badge:** Zeigt Ersparnisbetrag und -prozentsatz
- **Durchgestrichen:** Grundpreis, wenn Angebotspreis niedriger ist
- **"Im Angebot"-Badge:** Einzelne Zutaten mit Angeboten
- **"N/V":** Preis nicht verfügbar (fehlende Grund- oder Angebotsdaten)

### Wichtige Hinweise

- Preise aktualisieren sich automatisch, wenn sich Angebote ändern
- Es werden nur Gerichte mit mindestens einem aktiven Angebot angezeigt
- Preise sind Schätzungen basierend auf aktuellen Angeboten
- Tatsächliche Ladenpreise können leicht abweichen

## Tipps für das beste Erlebnis

### Ersparnisse maximieren

1. **Regelmäßig prüfen:**
   - Angebote ändern sich wöchentlich
   - Aktualisieren Sie die Seite, um neue Angebote zu sehen

2. **Filter verwenden:**
   - Filtern Sie nach Kette, um spezifische Supermarkt-Angebote zu sehen
   - Legen Sie einen Maximalpreis fest, um budgetfreundliche Optionen zu finden

3. **Nach hohen Ersparnissen suchen:**
   - Sortieren Sie nach "Ersparnis (Hoch)", um die besten Angebote zuerst zu sehen
   - Grüne Badges zeigen erhebliche Ersparnisse an

4. **Vorausplanen:**
   - Markieren Sie Gerichte, die Sie kochen möchten, als Favoriten
   - Prüfen Sie den Favoriten-Tab für schnellen Zugriff

### Das richtige Gericht finden

1. **Schnelle Mahlzeiten:**
   - Aktivieren Sie den "Schnelle Mahlzeiten"-Filter für schnelle Zubereitung
   - Perfekt für Wochentags-Abendessen

2. **Meal Prep:**
   - Aktivieren Sie den "Meal Prep"-Filter für Batch-Kochen
   - Großartig für Wochenend-Mahlzeitenvorbereitung

3. **Nach Kategorie durchsuchen:**
   - Durchsuchen Sie nach Kategorie, um spezifische Mahlzeittypen zu finden
   - Entdecken Sie neue Küchen und Gerichte

### Konto verwalten

**Standort aktualisieren:**
- Ändern Sie die PLZ jederzeit von der Hauptseite
- Das System aktualisiert Gerichte automatisch
- Vorheriger Standort wird gespeichert

**Profilinformationen:**
- Benutzername und E-Mail werden im Benutzermenü angezeigt
- Klicken Sie auf das Benutzer-Avatar, um das Profil zu sehen
- Abmelden über das Benutzermenü

## Fehlerbehebung

### "Keine Gerichte gefunden"

**Mögliche Ursachen:**
- Keine PLZ festgelegt: Geben Sie Ihre Postleitzahl ein
- Keine Angebote in Ihrer Region: Angebote sind möglicherweise noch nicht verfügbar
- Filter zu restriktiv: Versuchen Sie, Filter zu entfernen
- Keine gültigen Angebote: Schauen Sie später für neue Angebote vorbei

**Lösungen:**
- Geben Sie Ihre PLZ ein oder aktualisieren Sie sie
- Entfernen oder passen Sie Filter an
- Versuchen Sie eine andere Kategorie oder Kette
- Kontaktieren Sie den Support, wenn das Problem weiterhin besteht

### "Postleitzahl nicht gefunden"

**Ursache:** Ihre PLZ ist nicht in unserer Datenbank

**Lösungen:**
- Versuchen Sie eine nahegelegene Postleitzahl
- Kontaktieren Sie den Support, um Ihren Bereich hinzuzufügen
- Überprüfen Sie, dass Sie das richtige Format eingegeben haben (5 Ziffern für Deutschland)

### Preise scheinen falsch zu sein

**Mögliche Ursachen:**
- Angebote sind möglicherweise abgelaufen
- Einheitenumrechnungsprobleme
- Fehlende Grundpreise

**Lösungen:**
- Aktualisieren Sie die Seite
- Prüfen Sie die Gerichtsdetailseite für Zutatenaufschlüsselung
- Melden Sie das Problem dem Support mit Gerichts-ID

### Kann nicht zu Favoriten hinzufügen

**Mögliche Ursachen:**
- Nicht angemeldet
- Sitzung abgelaufen

**Lösungen:**
- Melden Sie sich an oder aktualisieren Sie die Sitzung
- Versuchen Sie, sich ab- und wieder anzumelden
- Löschen Sie den Browser-Cache, wenn das Problem weiterhin besteht

## Tastenkürzel

- **Enter:** PLZ-Eingabe absenden
- **Tab:** Zwischen Filtern navigieren
- **Escape:** Modals/Dropdowns schließen

## Browser-Kompatibilität

**Unterstützte Browser:**
- Chrome (neueste Version)
- Firefox (neueste Version)
- Safari (neueste Version)
- Edge (neueste Version)

**Mobil:**
- iOS Safari
- Chrome Mobile
- Responsives Design für alle Bildschirmgrößen

## Datenschutz & Daten

**Was wir speichern:**
- E-Mail-Adresse (für Authentifizierung)
- Benutzername (optional)
- Postleitzahl (für standortbasierte Angebote)
- Favorisierte Gerichte

**Was wir nicht speichern:**
- Zahlungsinformationen
- Persönliche Einkaufshistorie
- Standortdaten über PLZ hinaus

**Datenverwendung:**
- Wird nur zur Bereitstellung des Dienstes verwendet
- Wird nicht an Dritte weitergegeben
- Siehe Datenschutzerklärung für Details

## Hilfe erhalten

**Support-Kanäle:**
- E-Mail: [Support-E-Mail]
- In-App: Kontaktformular (falls verfügbar)
- Dokumentation: Prüfen Sie dieses Handbuch

**Probleme melden:**
- Geben Sie Ihre PLZ an
- Beschreiben Sie das Problem
- Screenshots sind hilfreich
- Gerichts-ID, falls relevant

---

**Viel Erfolg beim Kochen und Sparen! 🍽️💰**

