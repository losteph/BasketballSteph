# 🏀 Basketball Steph - Official App & Scoreboard

**Basketball Steph** è un'applicazione multipiattaforma (Android APK & Web PWA) progettata per la gestione completa di partite, tornei, statistiche e pagelle di basket (5v5 o 3v3 da campetto). Ispirata ai sistemi professionali e alle card *FUT/NBA 2K*, trasforma ogni partita tra amici o torneo amatoriale in un'esperienza ufficiale con dati reali e cronaca live.

---

## 🚀 Funzionalità Principali

### 1. ⏱️ Scoreboard & Regia Live
* **Doppio Cronometro Professionale**: Timer principale per i Quarti (modalità Conto alla Rovescia o In Avanti, personalizzabile es. 10m o 5m per gli Overtime) affiancato dallo **Shot Clock ufficiale 24s / 14s** con sirene acustiche automatiche.
* **Gestione Quarti & Overtime**: Passaggio rapido tra `1°Q`, `2°Q`, `3°Q`, `4°Q`, `1°OT` e `2°OT` con azzeramento automatico dei falli di squadra a ogni nuovo periodo.
* **Bonus Falli**: Indicatore visivo automatico di **🚨 BONUS** al raggiungimento del 5° fallo di squadra nel quarto e avviso immediato al 5° fallo personale del singolo giocatore.
* **Azioni Giocatore Rapide**: Modale immediata per registrare Punti (`+3`, `+2`, `+1`) con eventuale Assist, Rimbalzi, Buone Azioni difensive, Errori/Palle Perse, Falli e Sostituzioni in tempo reale.
* **Cronaca Live & Condivisione WhatsApp**: Feed degli eventi con possibilità di annullare qualsiasi canestro o fallo per errore di battuta. Esportazione istantanea a fine gara del tabellino (Cronaca Saliente o Completa) e delle Pagelle formattate per WhatsApp.

### 2. 👥 Database Giocatori & Card Stile NBA/FUT
* **I 5 Ruoli del Basket**:
  * **PG** (Playmaker / Point Guard)
  * **SG** (Guardia / Shooting Guard)
  * **SF** (Ala Piccola / Small Forward)
  * **PF** (Ala Grande / Power Forward)
  * **C** (Centro / Pivot)
* **Sistema Attributi in Lettere (`C-` ➔ `A+`)**: Ogni giocatore è valutato su 6 parametri chiave: **TIR** (Tiro), **PAS** (Passaggio), **DRI** (Dribbling), **DIF** (Difesa), **RIM** (Rimbalzo) e **FIS** (Fisico).
* **Calcolo Automatico OVR & Tier**: L'app calcola l'Overall (OVR) pesando gli attributi in base al ruolo specifico del giocatore e assegna automaticamente la rarità della card (**🥇 GOLD** 80+, **🥈 SILVER** 70-79, **🥉 BRONZE** <70).

### 3. 🛡️ Gestione Squadre & Rose
* Creazione di squadre personalizzate con scelta tra gli **8 colori sociali ufficiali** (`🔵 Blu`, `🔴 Rosso`, `🟢 Verde`, `🟡 Giallo`, `🟠 Arancio`, `🟣 Viola`, `⚫ Nero`, `⚪ Bianco`).
* Assegnazione dei numeri di maglia personalizzati e distinzione tra quintetto base (**IN**) e panchina (**OUT**).

### 4. 🏆 Storico Partite, Tornei & Statistiche
* **Classifica Ufficiale**: Calcolo automatico con regole FIBA/NBA (Vittoria **+2 pt**, Sconfitta **0 pt**) e risoluzione automatica degli ex-aequo (1. Scontro Diretto, 2. Differenza Canestri `DC`, 3. Punti Fatti `PF`).
* **Leaderboard Statistiche**: Classifica combinata dei giocatori per Punti (`PTS`), Rimbalzi (`RIM`) e Assist (`ASS`).
* **Pagelle & MVP**: Calcolo matematico del voto da `1.0` a `9.9` con assegnazione automatica del premio **MVP** (o `SV` per chi gioca meno di 3 minuti senza incidere).

---

## 💾 Backup & Integrazione con il Portale Web

L'app funziona al 100% offline salvando i dati in memoria locale, ma include un motore universale di **Import/Export JSON**:
* **`player.json`**: Esporta/Importa l'intero database atleti.
* **`teams.json`**: Esporta/Importa le squadre e le rose.
* **`match.json`**: Esporta/Importa lo storico completo delle partite giocate.

I file JSON esportati dall'app possono essere caricati direttamente nella cartella `data/` del **Portale Web Ufficiale Basket Steph** per aggiornare online classifiche, tabelloni playoff e statistiche per tutti gli spettatori.

---

## 🛠️ Compilazione & Deploy (GitHub Actions)

Il progetto include due workflow automatici nella cartella `.github/workflows/`:
1. **`deploy.yml`**: Ad ogni `git push` sul branch `main`, compila la versione Web/PWA e la pubblica automaticamente su GitHub Pages.
2. **`build_apk.yml`**: Avviabile manualmente dal tab *Actions* di GitHub (`Run workflow`) per generare e scaricare il pacchetto di installazione Android **`app-release.apk`**.
