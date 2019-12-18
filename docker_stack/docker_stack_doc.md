# Doku Docker Stack 0.1

## Dockerfiles
    Während Download von (insb. Alpine) packages prüfen, ob APKINDEX (tar.gz) Download erfolgreich oder timeout durch Barracuda. 

## TimescaleDB

### TSDB BACKUP, RESTORE

1. Restore vorbereiten

    `ALTER DATABASE sauber_test SET timescaledb.restoring='on';`
    `SELECT timescaledb_pre_restore();`

2. Backup durchführen

    `\! pg_restore -Fc -d here here_db.backup` etc

3. Post-restore

    `SELECT timescaledb_post_restore();`

4. Hypertables müssen ggf. manuell neu erzeugt werden.


## Datenbank 

### Image: Alpine Linux 3.10.2, PostgreSQL 11.5, TSDB 1.5.1, PostGIS 3.0.0

    Base-Image: TimescaleDB 1.5.1-pg11

    PostGIS Dependencies

    PostGIS aus Source	

    **Image nicht überschreiben:** APK Repo enthält nur aktuellste Versionen von Packages. Ggf. Probleme bei Kompatibilität zw. TSDB und Postgres. Neues Image entsprechend taggen.

### Updates: 
    
    PostgreSQL, Timescale: Base-Image anpassen. ‘Latest’ Syntax bei TSDB beachten. 

    PostGIS innerhalb DB (ALTER EXTENSION postgis UPDATE…).
    Automatisches Update in initdb möglich. Aber: Error bsp. bei Update 2.5.2 -> 3.0.0., container crasht. 



    |    000    |    Erweiterungen ts,postgis,postgis-topo,   fuzzystrmatch in postgres, template1    |    Input                             |
    |-----------|-------------------------------------------------------------------------------------|--------------------------------------|
    |    001    |    hba.conf ->   Host auf trust                                                     |    -                                 |
    |    002    |    timescale tune                                                                   |    -                                 |
    |    010    |    Create User und   Passwörter                                                     |    Neue User +   Passwörter          |
    |    011    |    Struktur für   LUBW Messst.                                                      |    Bei Änderung   backup einfügen    |
    |    012    |    Struktur für   HERE                                                              |    s.o.                              |
    |    013    |    Struktur für   Rasterdaten                                                       |    s.o.                              |
    |    01x    |    Ggf. Weitere DBs                                                                 |                                      |
    |    020    |    PGrest basic   auth + JWT pro DB                                                 |    Neue DBs                          |


## Stack

### Secrets

    Docker erlaubt keine Änderung des Inhalts eines Secrets.

    Inhalt von Secret File ändern, Version in Name anpassen. 

### FTP_Download

    Cron-Job innerhalb Container: Download von  Datei 'Aktuelledaten.xml' der Messstationen von LUBW-FTP-Server alle xx:30h 

    Einfügen der Datei in Import-Tabelle (1x1 xml) in Datenbank. XML kann nicht mit Linebreaks in DB eingefügt werden. Linebreaks werden durch Skript entfernt.

    Start von DB-Funktion zum Parsen der Datei, Einfügen von Daten, Löschen aus temp Table.

### Geoserver


### Postgrest

    Zwei pgREST Instanzen für DBs HERE und LUBW. Bisher gleicher JWT Token. 

    Möglichkeiten: Verwendung verschieden Token, Basic Auth je Datenbank, etc.

### Universal Messaging Server

### Universal Messaging Subscriber
    
    In bisheriger Form (Container nur mit jar) per tty-Flag offengehalten.

    Log Clutter durch fehlgeschlagene Verbindungen bis UM Server gestartet ist. Todo: wait-for-it Script.

    Läd noch jede Datei herunter, die in Publisher event data als Value von "url" vorhanden ist. Todo: UM channel sichern. 