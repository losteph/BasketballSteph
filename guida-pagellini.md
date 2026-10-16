# 🎙️ Guida Ufficiale per il Telecronista / Statistico a Bordo Campo

Questa guida spiega esattamente come funziona l'algoritmo di valutazione di **Basket Steph** (ispirato a *Flashscore*) e stabilisce le regole pratiche per chi tiene il tabellone durante la partita. 

Poiché c'è **una sola persona** a bordo campo a inserire i dati in tempo reale, l'obiettivo non è registrare ogni singolo respiro come in NBA, ma **catturare le giocate evidenti che spostano la partita** in modo equo e coerente per tutti.

---

## 📊 Tabella Ufficiale Bonus / Malus (Singolo Decimale)

Ogni giocatore parte da un **Voto Base di 6.0**.
*(Nota: chi gioca meno di 3 minuti e non registra punti, assist, rimbalzi o buone azioni riceve **SV - Senza Voto**).*

| Azione / Evento | Tasto App | Variazione Voto | Note |
| :--- | :--- | :---: | :--- |
| **Vittoria Squadra** | *(Automatico)* | **+0.2** | Assegnato a fine gara ai vincitori |
| **Sconfitta Squadra** | *(Automatico)* | **-0.1** | Assegnato a fine gara agli sconfitti |
| **Tripla (+3 PT)** | `🎯 Tripla (+3)` | **+0.4** | +0.2 extra a chi fa l'eventuale assist |
| **Canestro (+2 PT)** | `🏀 Canestro (+2)` | **+0.3** | +0.2 extra a chi fa l'eventuale assist |
| **Tiro Libero (+1 PT)** | `☄️ Libero (+1)` | **+0.1** | Tiro libero o punto singolo realizzato |
| **Assist** | *(Menu a tendina)* | **+0.2** | Selezionato prima di premere +2 o +3 |
| **Rimbalzo** | `🖐️ Rimbalzo` | **+0.2** | Resetta anche lo Shot Clock a 14s |
| **Buona Azione** | `⭐ Buona Azione` | **+0.3** | Recupero, stoppata, grande difesa |
| **Errore / Palla Persa** | `❌ Errore / Persa` | **-0.2** | Palla persa o forzatura/tiro sbagliato |
| **Fallo Personale** | `⚠️ Fallo Personale` | **-0.3** | Incrementa anche il conteggio falli (max 5) |

*Il voto finale è sempre arrotondato a un singolo decimale e bloccato nel range tra **1.0** (minimo) e **9.9** (massimo).*

---

## 🧠 Regole d'Oro per i Casi Critici (Quando assegnare cosa)

I punti (`+3`, `+2`, `+1`) e i falli sono oggettivi. Ecco invece come comportarsi senza esitazioni sulle voci che possono generare dubbi durante il gioco:

### 1. Quando assegnare `⭐ Buona Azione` (+0.3)?
Questo tasto esiste per **premiare chi difende forte e fa il lavoro sporco** anche se segna zero punti. Assegnalo **SOLO** in questi casi netti:
* **Palla Rubata / Intercetto (Steal)**: Il difensore strappa la palla dalle mani dell'avversario o intercetta un passaggio avviando il contropiede.
* **Stoppata (Block)**: Il difensore stoppa regolarmente un tiro avversario.
* **Difesa Decisiva / Sfondamento Preso**: Il difensore tiene un 1 contro 1 difficilissimo costringendo l'attaccante a buttare la palla fuori, a far scadere i 24 secondi o a commettere fallo di sfondamento.
* **Salvataggio in Tuffo (Hustle Play)**: Recupero di un pallone vagante buttandosi a terra e dandolo a un compagno.
> **NON assegnarlo** per un normale passaggio a metà campo o per una difesa ordinaria senza recupero.

---

### 2. Quando assegnare `❌ Errore / Persa` (-0.2)?
Questo tasto unifica le **Palle Perse (Turnover)** e i **Tiri Sbagliati Gravi**, evitando che chi tira 20 volte facendo solo 3 canestri prenda 8 in pagella. Assegnalo in questi casi:
* **Passaggio Regalato / Palla Persa**: Passaggio mandato direttamente fuori dal campo o in mano agli avversari, palleggio sul piede, infrazione di passi o doppio palleggio.
* **Airball o Tiro Forzatissimo Egoista**: Un tiro da tre punti sparato fuori misura (airball) con i compagni liberi, o un'entrata suicida contro tre difensori che finisce in nulla.
* **Errore Sotto Canestro Clamoroso**: Sbagliare un appoggio (layup) facilissimo tutto solo sotto il ferro.
* **Serie di Tiri Sbagliati**: Se un tiratore sta chiaramente forzando e sbaglia 2-3 tiri di fila, assegnagli un `❌ Errore` per bilanciare la sua percentuale.
> **NON assegnare errore** su ogni singolo tiro normale che gira sul ferro ed esce durante un'azione ben costruita, altrimenti i voti crolleranno tutti sotto il 5.0! Penalizza **le palle perse vere** e **i tiri sbagliati netti/forzati**.

---

### 3. Quando assegnare `🖐️ Rimbalzo` (+0.2)?
Al campetto ci sono decine di rimbalzi: non serve segnarli tutti se la palla cade semplicemente in mano a un giocatore da solo. Assegna il rimbalzo quando:
* **Rimbalzo Conteso nel Traffico**: Il giocatore salta in mezzo agli avversari e cattura con forza la palla (sia in difesa che in attacco).
* **Rimbalzo Offensivo (Extra-Possesso)**: Qualsiasi rimbalzo preso in attacco dopo un tiro sbagliato da un compagno (vale doppio a livello morale perché regala un nuovo tiro alla squadra!).

---

### 4. Quando assegnare l'`🅰️ Assist` (+0.2)?
* Assegna l'assist **solo se il passaggio porta direttamente al canestro** (il compagno riceve e tira subito, oppure fa al massimo un palleggio/terzo tempo per appoggiare a canestro).
* Se il compagno riceve palla a metà campo, palleggia per 8 secondi scartando due uomini e segna, **non è assist** ma azione personale di chi ha segnato.

---

### 5. Gestione del `⚠️ Fallo Personale` (-0.3)
* Ogni fallo chiamato (difensivo o in attacco) va registrato sul giocatore che lo ha commesso.
* Se c'è un fallo duro o antisportivo/tecnico evidente per proteste, puoi premere `⚠️ Fallo` + `❌ Errore` sullo stesso giocatore per dargli una penalità complessiva di **-0.5**.

---

## 🏆 Come viene scelto l'MVP a parità di voto?
Se a fine partita due giocatori hanno esattamente lo stesso voto numerico più alto (es. entrambi `8.4`), l'app applica automaticamente questa gerarchia:
1. Vince chi appartiene alla **squadra vincitrice**.
2. A parità di esito squadra, vince chi ha segnato **più punti totali**.
3. A parità di punti, vince chi ha fatto **più assist**.
4. A parità ulteriore, vince chi ha commesso **meno errori/falli**.
