#!/bin/bash
set -e

# Persistent storage directory (Railway Volume)
STORAGE_DIR="${STORAGE_DIR:-/data}"
SEGMENTS_URL="http://brouter.de/brouter/segments4"

# Seznam segmentů pro střední Evropu a Jadran
SEGMENTS=(
    "E10_N50"  # ČR západ, Německo
    "E15_N50"  # ČR východ, Polsko
    "E10_N45"  # Rakousko, Slovinsko
    "E15_N45"  # Rakousko východ, Maďarsko, Chorvatsko sever
    "E15_N40"  # Chorvatsko jih, Bosna
    "E5_N45"   # Sever Itálie
)

echo "============================================"
echo "BRouter Engine - Railway Edition"
echo "============================================"
echo "Storage directory: $STORAGE_DIR"
echo "============================================"

# Vytvoření adresáře pro segmenty pokud neexistuje
mkdir -p "$STORAGE_DIR/segments4"

# Kontrola existence segmentů
NEEDS_DOWNLOAD=false
for segment in "${SEGMENTS[@]}"; do
    FILE="${segment}.rd5"
    FILEPATH="${STORAGE_DIR}/segments4/${FILE}"

    if [ ! -f "$FILEPATH" ]; then
        NEEDS_DOWNLOAD=true
        echo "[MISSING] $FILE"
    else
        SIZE=$(stat -c%s "$FILEPATH" 2>/dev/null || stat -f%z "$FILEPATH" 2>/dev/null || echo "0")
        if [ "$SIZE" -lt 1000 ]; then
            NEEDS_DOWNLOAD=true
            echo "[CORRUPTED] $FILE (size: $SIZE bytes)"
        else
            echo "[OK] $FILE ($(( SIZE / 1024 / 1024 )) MB)"
        fi
    fi
done

# Stažení chybějících segmentů
if [ "$NEEDS_DOWNLOAD" = true ]; then
    echo "============================================"
    echo "Stahuji chybějící segmenty..."
    echo "============================================"

    for segment in "${SEGMENTS[@]}"; do
        FILE="${segment}.rd5"
        FILEPATH="${STORAGE_DIR}/segments4/${FILE}"

        # Přeskočit pokud existuje a má správnou velikost
        if [ -f "$FILEPATH" ]; then
            SIZE=$(stat -c%s "$FILEPATH" 2>/dev/null || stat -f%z "$FILEPATH" 2>/dev/null || echo "0")
            if [ "$SIZE" -gt 1000 ]; then
                continue
            fi
        fi

        echo "[DOWNLOAD] Stahuji $FILE..."
        if curl -f -L --progress-bar -o "$FILEPATH" "${SEGMENTS_URL}/${FILE}"; then
            echo "[OK] $FILE úspěšně stažen"
        else
            echo "[ERROR] Nepodařilo se stáhnout $FILE"
            rm -f "$FILEPATH"
        fi
    done
else
    echo "============================================"
    echo "Všechny segmenty jsou dostupné, přeskakuji stahování."
    echo "============================================"
fi

# Výpis stažených segmentů
echo "============================================"
echo "Dostupné segmenty:"
echo "============================================"
ls -lh "$STORAGE_DIR/segments4"/*.rd5 2>/dev/null || echo "Žádné segmenty nenalezeny!"
echo "============================================"

# Najdi JAR soubor
BROUTER_JAR=$(find /app -name "brouter-*.jar" -type f | head -1)
if [ -z "$BROUTER_JAR" ]; then
    BROUTER_JAR="/app/brouter.jar"
fi

echo "JAR: $BROUTER_JAR"
echo "Segments: $STORAGE_DIR/segments4"
echo "Profiles: /app/profiles2"
echo "Custom profiles: /app/customprofiles"
echo "Port: 17777"
echo "============================================"
echo "Spouštím BRouter server..."
echo "============================================"

# Java memory settings
JAVA_XMX="${JAVA_XMX:-512m}"
JAVA_XMS="${JAVA_XMS:-128m}"

# Zkopíruj customprofiles do profiles2 (BRouter očekává relativní cestu)
mkdir -p /app/profiles2/customprofiles
cp -r /app/customprofiles/* /app/profiles2/customprofiles/ 2>/dev/null || true

# Spuštění Java serveru
exec java \
    -Xmx${JAVA_XMX} \
    -Xms${JAVA_XMS} \
    -cp "$BROUTER_JAR" \
    btools.server.RouteServer \
    "$STORAGE_DIR/segments4" \
    /app/profiles2 \
    customprofiles \
    17777 \
    1
