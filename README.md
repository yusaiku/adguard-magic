# AdGuard Home Magic Container

Minimaler AdGuard Home Container mit DoH + DoT und automatischer Zertifikatserneuerung für Bunny.net.

## Environment Variables

| Variable        | Beschreibung             | Beispiel                  |
|-----------------|--------------------------|---------------------------|
| `DOMAIN`        | Deine Subdomain          | `adguard.example.com`     |
| `EMAIL`         | E-Mail für Let's Encrypt | `mail@example.com`        |
| `BUNNY_API_KEY` | Bunny DNS API Key        | `xxxxxxxx`                |

## Volumes

- `certs` → `/etc/nginx/ssl`
- `adguard-data` → `/opt/adguardhome`

## Ports

- `443` (DoH)
- `853` (DoT)

## Automatische Erneuerung

Das System erneuert Zertifikate automatisch über einen täglichen Cron-Job. Du musst nicht manuell redeployen.
