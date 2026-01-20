# BRouter Engine - Production Image for Railway
FROM eclipse-temurin:17-jre-alpine

# Instalace potřebných nástrojů
RUN apk add --no-cache curl bash

# Vytvoření pracovního adresáře
WORKDIR /app

# Stažení BRouter
ARG BROUTER_VERSION=1.7.7
RUN curl -L -o brouter.zip "https://github.com/abrensch/brouter/releases/download/v${BROUTER_VERSION}/brouter-${BROUTER_VERSION}.zip" && \
    unzip brouter.zip && \
    mv brouter-${BROUTER_VERSION}/* . && \
    rm -rf brouter.zip brouter-${BROUTER_VERSION} && \
    apk del curl && \
    rm -rf /var/cache/apk/*

# Reinstalace curl (potřebujeme pro runtime stahování segmentů)
RUN apk add --no-cache curl

# Kopírování start skriptu a custom profilů
COPY start.sh /app/start.sh
COPY customprofiles /app/customprofiles

# Nastavení práv
RUN chmod +x /app/start.sh

# Proměnné prostředí
ENV STORAGE_DIR=/data
ENV JAVA_OPTS="-Xmx512m -Xms128m"

# Exponování portu
EXPOSE 17777

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=3 \
    CMD curl -f http://localhost:17777/brouter/profile || exit 1

# Spuštění
CMD ["/app/start.sh"]
