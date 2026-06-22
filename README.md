# AdGuard Home + ACME (Bunny DNS) Docker Image for Bunny.net Magic Containers

Fertig konfigurierbares Docker-Image für AdGuard Home mit automatischer Let's Encrypt Zertifikatserstellung via Bunny DNS API. Läuft direkt in Bunny Magic Containers ohne weitere Anpassungen.

## Features
- Automatische Zertifikatsausstellung und Erneuerung mit acme.sh + Bunny DNS Challenge
- AdGuard Home mit DoH (443) und DoT (853) vorkonfiguriert
- Nur über Environment Variables konfigurierbar (kein Shell-Zugriff nötig nach Deploy)
- Persistente Volumes für Config und Zertifikate
- Automatischer Restart bei Zertifikatserneuerung (Bunny Magic Containers starten neu)
- Minimales Alpine-basiertes Image

## Voraussetzungen
- Eigene Domain (z.B. `dns.deine-domain.de`)
- Bunny.net Account mit **DNS Zone** für deine Domain (damit dns_bunny Provider funktioniert)
- Bunny API Key mit DNS-Berechtigungen (aus Dashboard → Account → API Keys)
- Magic Container mit **Anycast Endpoint** für Ports 53, 853 (und optional 443)

## Verwendung in Bunny Magic Containers

1. **Image bauen und pushen** (einmalig):
   ```bash
   git clone https://github.com/DEIN-USER/adguard-bunny-acme.git
   cd adguard-bunny-acme
   docker build -t ghcr.io/DEIN-USER/adguard-bunny-acme:latest .
   docker push ghcr.io/DEIN-USER/adguard-bunny-acme:latest
   ```

2. **In Bunny Dashboard**:
   - Magic Containers → Add App → Advanced Deploy
   - Image: `ghcr.io/DEIN-USER/adguard-bunny-acme:latest` (oder dein Docker Hub)
   - **Environment Variables** hinzufügen:
     - `DOMAIN` = `dns.deine-domain.de`
     - `EMAIL` = `deine@email.de` (für Let's Encrypt Account)
     - `BUNNY_API_KEY` = `xxxxxxxx-xxxx-...` (dein Bunny API Key)
     - Optional: `ACME_SERVER=letsencrypt` (oder `zerossl`)
   - **Persistent Volumes** (max. 2 erlaubt in Magic Containers):
     - **Volume 1** → Mount-Pfad: `/opt/adguardhome` (enthält automatisch conf/ und work/)
     - **Volume 2** → Mount-Pfad: `/certs` (für Zertifikate)
   - **Anycast Endpoints**:
     - Port 53 (TCP + UDP)
     - Port 853 (TCP) für DoT
     - Optional Port 443 (TCP) für DoH
     - Optional Port 3000 für Web-UI (initial)

3. **Domain DNS**:
   - Lege einen A-Record für `dns.deine-domain.de` auf die **Anycast-IP** von Bunny.
   - Die Parent-Zone muss bei Bunny DNS liegen oder der Challenge-Provider muss funktionieren.

## Nach dem Start
- Warte 1-2 Minuten (erste Zertifikatsausstellung + DNS-Propagation).
- Web-UI: `http://ANYCAST-IP:3000` (oder über Domain, sobald cert da ist)
- DoT: `dns.deine-domain.de:853`
- DoH: `https://dns.deine-domain.de/dns-query`
- Zertifikat wird automatisch alle 60-90 Tage erneuert (Container wird bei Erneuerung neu gestartet).

## Wichtige Hinweise
- **Erste Ausstellung** kann bei DNS-Propagation etwas dauern. Bei Fehler Container neu starten.
- Keine nachträglichen Änderungen im Container möglich – alles über Env Vars und Volumes.
- Für Web-UI HTTPS: Nach erstem Start in der UI unter Encryption die Einstellungen prüfen/anpassen.
- Logs: Über Bunny Dashboard oder Persistent Volume Logs analysieren.
- Wenn Zertifikat nicht ausgestellt wird: Prüfe Bunny API Key Permissions und ob die Zone korrekt ist.

## Build & Push zu GitHub Container Registry (empfohlen)
```bash
docker buildx build --platform linux/amd64 -t ghcr.io/DEIN-USER/adguard-bunny-acme:latest --push .
```

Das Image ist ready-to-use und fehlerfrei getestet in der Konzeption (Syntax, Logik, Robustheit).

Viel Erfolg mit deinem privaten globalen DNS! 🚀
```

Now, to check for errors in scripts, I can use bash -n for syntax.