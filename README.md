# BRouter Engine

Backend pro výpočet cyklistických tras. Používá [BRouter](https://github.com/abrensch/brouter) - open-source routing engine optimalizovaný pro cyklistiku.

## Funkce

- Výpočet tras pro cyklistiku (silnice, MTB, trekking)
- Podpora vlastních routing profilů
- Automatické stahování mapových segmentů při prvním spuštění
- Optimalizováno pro nasazení na Railway s persistent volume

## Lokální spuštění (Docker)

```bash
docker-compose up --build
```

Server poběží na `http://localhost:17777`

## Nasazení na Railway

### 1. Vytvoř GitHub repozitář

```bash
cd brouter-engine
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/TVUJ_USERNAME/brouter-engine.git
git push -u origin main
```

### 2. Vytvoř nový projekt na Railway

1. Jdi na [railway.app](https://railway.app) a přihlas se
2. Klikni na **New Project**
3. Vyber **Deploy from GitHub repo**
4. Vyber svůj `brouter-engine` repozitář
5. Railway automaticky detekuje Dockerfile a začne build

### 3. Přidej Persistent Volume (DŮLEŽITÉ!)

Mapové segmenty (~900 MB) se stahují při prvním spuštění. Bez volume by se stahovaly při každém restartu.

1. V Railway dashboardu klikni na svůj service
2. Jdi do záložky **Settings**
3. Scrolluj dolů na sekci **Volumes**
4. Klikni **Add Volume**
5. Nastav:
   - **Mount Path:** `/data`
   - **Size:** 2 GB (nebo více)
6. Klikni **Add**

### 4. Nastav proměnné prostředí (volitelné)

V záložce **Variables** můžeš nastavit:

| Proměnná | Výchozí hodnota | Popis |
|----------|-----------------|-------|
| `STORAGE_DIR` | `/data` | Cesta k volume pro mapové segmenty |
| `JAVA_OPTS` | `-Xmx512m -Xms128m` | Java heap size |

### 5. Nastav port

Railway by mělo automaticky detekovat port 17777. Pokud ne:

1. Jdi do **Settings** → **Networking**
2. Klikni **Generate Domain** pro veřejnou URL
3. Ověř že port je nastaven na `17777`

### 6. První deploy

Po přidání volume Railway automaticky restartuje service. První spuštění trvá déle (stahování map ~900 MB).

Sleduj logy v záložce **Deployments** → **View Logs**:

```
============================================
BRouter Engine - Railway Edition
============================================
[MISSING] E10_N50.rd5
[MISSING] E15_N50.rd5
...
[DOWNLOAD] Stahuji E10_N50.rd5...
[OK] E10_N50.rd5 úspěšně stažen
...
Spouštím BRouter server...
```

### 7. Ověř funkčnost

Po úspěšném startu navštiv:

```
https://TVOJE-RAILWAY-URL.railway.app/brouter/profile
```

Měl bys vidět seznam dostupných routing profilů.

## API Endpoints

### Seznam profilů
```
GET /brouter/profile
```

### Výpočet trasy
```
GET /brouter?lonlats={lon1},{lat1}|{lon2},{lat2}&profile={profil}&alternativeidx=0&format=geojson
```

**Příklad:**
```
GET /brouter?lonlats=14.4378,50.0755|14.2632,50.1012&profile=trekking&alternativeidx=0&format=geojson
```

### Parametry

| Parametr | Popis |
|----------|-------|
| `lonlats` | Body trasy ve formátu `lon,lat` oddělené `\|` |
| `profile` | Routing profil (`trekking`, `fastbike`, `car-eco`, ...) |
| `alternativeidx` | Index alternativní trasy (0 = hlavní) |
| `format` | Výstupní formát (`geojson`, `gpx`, `kml`) |

## Pokryté oblasti

Server stahuje mapové segmenty pro střední Evropu:

| Segment | Oblast |
|---------|--------|
| E10_N50 | ČR západ, Německo |
| E15_N50 | ČR východ, Polsko |
| E10_N45 | Rakousko, Slovinsko |
| E15_N45 | Rakousko východ, Maďarsko, Chorvatsko sever |
| E15_N40 | Chorvatsko jih, Bosna |
| E5_N45 | Sever Itálie |

Pro přidání dalších oblastí uprav pole `SEGMENTS` v `start.sh`.

Mapa segmentů: [brouter.de/brouter/segments4/](http://brouter.de/brouter/segments4/)

## Vlastní profily

Vlastní routing profily můžeš přidat do složky `customprofiles/`. Profily jsou soubory s příponou `.brf`.

Dokumentace profilů: [BRouter Profiles](https://github.com/abrensch/brouter/tree/master/misc/profiles2)

## Troubleshooting

### Server neodpovídá
- Zkontroluj logy v Railway dashboardu
- Ověř že volume je správně připojený na `/data`
- První start může trvat 5-10 minut (stahování map)

### Trasa nenalezena
- Ověř že souřadnice jsou v pokryté oblasti
- Zkontroluj zda jsou segmenty stažené (v logu `[OK]`)

### Málo paměti
- Zvyš `JAVA_OPTS` na `-Xmx1g` v Railway Variables
- Nebo upgraduj Railway plan

## Struktura projektu

```
brouter-engine/
├── Dockerfile          # Docker image pro produkci
├── docker-compose.yml  # Lokální development
├── start.sh           # Startup script (stahování map + spuštění)
├── customprofiles/    # Vlastní routing profily
├── segments/          # Lokální mapové segmenty (ignorováno v git)
└── README.md          # Tento soubor
```
