<h1 align="center">Recopilación de Información · OSINT & Recon</h1>

<p align="center">
  <img src="https://img.shields.io/badge/OSINT-58A6FF?style=flat-square" />
  <img src="https://img.shields.io/badge/Nmap-4682B4?style=flat-square&logo=nmap&logoColor=white" />
  <img src="https://img.shields.io/badge/Nuclei-00ADD8?style=flat-square" />
  <img src="https://img.shields.io/badge/Maltego-1a1a2e?style=flat-square" />
</p>

---

## Sobre este módulo

Antes de cualquier ataque o auditoría hay que **conocer al objetivo**. El reconocimiento avanza de lo menos intrusivo (fuentes públicas que no tocan al objetivo) a lo más intrusivo (interacción directa que deja rastro), estrechando el foco hasta un listado priorizado de objetivos.

**Temas cubiertos:** footprinting pasivo y activo · reconocimiento horizontal y vertical · fingerprinting · análisis de vulnerabilidades · OSINT sobre personas y organizaciones · mapeo a MITRE ATT&CK (fase Reconnaissance).

---

## Flujo de reconocimiento

De la huella pública al mapa de la superficie de ataque. Cuanto más a la derecha, mayor la interacción con el objetivo y mayor la probabilidad de ser detectado.

![Flujo de reconocimiento](flujo-reconocimiento.png)

---

## Práctica — Reconocimiento de Mercado Libre (programa público en HackerOne)

Informe de inteligencia completo sobre `*.mercadolibre.com` (scope autorizado, HackerOne), aplicando las cuatro fases del módulo de principio a fin.

### Footprinting — de 0 a 51 subdominios

DNS brute force con doble diccionario (`shuffledns`, 4.6K y 110K términos), correlación por Google Analytics ID (`analyticsrelationships`), TLS SAN probing (`cero`), web scraping recursivo (`katana` + `unfurl`) y URLs históricas de Wayback/Common Crawl (`gau`) — consolidados y deduplicados en **51 subdominios únicos resueltos**.

### Fingerprinting — arquitectura y hallazgo crítico

Validación de hosts vivos (`httpx`), escaneo de los 10.000 puertos más comunes (`masscan` — solo 80/443 abiertos, consistente con arquitectura cloud detrás de balanceadores), capturas y stack tecnológico (`gowitness` — AWS + CloudFront + Tengine/Nginx, backend Rails, SSO Okta) y detección de WAF (`wafw00f` — CloudFront, ALB, Cloudflare, Akamai, Fastly según subdominio).

**Hallazgo de mayor severidad:** `artifacts.mercadolibre.com` exponía públicamente una instancia de **Sonatype Nexus Repository** con artefactos internos descargables (dependencias Android/iOS, SDKs de MercadoPago relacionados con `CardToken`), y metadatos que confirmaban su uso en pipelines de CI. Este tipo de exposición puede filtrar arquitectura interna de desarrollo y lógica de procesamiento de pagos.

### Análisis de vulnerabilidades — nuclei, takeover, TLS, email

- **nuclei:** sin vulnerabilidades críticas; hallazgos informativos (headers de seguridad ausentes, stack tecnológico expuesto).
- **Subdomain takeover (`subzy`):** dos candidatos evaluados manualmente — un **dangling DNS real hacia SendGrid** (`url8202.mercadolibre.com`, riesgo medio-alto si el recurso ya no está reclamado) y un falso positivo descartado (protegido por AWS ALB).
- **SSL/TLS (Qualys SSL Labs):** configuración sólida — TLS 1.2/1.3 únicamente, Forward Secrecy, HSTS, sin Heartbleed/POODLE/ROBOT; observaciones menores (cipher suites CBC, sin OCSP Stapling).
- **DMARC/SPF/DKIM:** `p=reject` — la política más estricta posible. Mercado Libre **no es vulnerable a email spoofing**.

### OSINT — personas y metadatos

Grafo de relaciones con Maltego para identificar personal vinculado al dominio, cruce con HaveIBeenPwned sobre un correo corporativo (múltiples brechas de terceros confirmadas para esa dirección), Google Dorking para mapear cargos clave en LinkedIn, y extracción de metadatos (`exiftool`) de documentos públicos del CDN (autor, software de producción, fechas) — todo con foco en qué expone a la organización a phishing dirigido, sin publicar datos personales identificables de terceros.

### Resumen de severidad

| Hallazgo | Riesgo |
|---|---|
| Nexus Repository expuesto (artefactos móviles + SDK de pagos) | **Alto** |
| Dangling DNS hacia SendGrid (posible subdomain takeover) | **Medio-Alto** |
| Empleado con correo corporativo en múltiples brechas de terceros | **Alto** |
| Cargos clave identificables por OSINT/LinkedIn | Medio |
| WAF ausente en algunos subdominios | Medio |
| Cipher suites CBC / sin OCSP Stapling / security headers faltantes | Bajo |
| DMARC `p=reject`, SSL/TLS sólido, solo 80/443 expuestos | Positivo |

---

## Stack

`shuffledns` · `httpx` · `masscan` · `gowitness` · `wafw00f` · `nuclei` · `subzy` · `Qualys SSL Labs` · `Maltego` · `HaveIBeenPwned` · `exiftool` · `ffuf`

---

## Objetivos cumplidos

- [x] Reconocimiento vertical completo respetando scope y reglas de compromiso de un programa real de Bug Bounty
- [x] 51 subdominios enumerados y validados combinando 5 técnicas de footprinting distintas
- [x] Hallazgo de severidad alta identificado y documentado con evidencia (Nexus Repository expuesto)
- [x] Vulnerabilidad de subdomain takeover distinguida correctamente de un falso positivo
- [x] Auditoría SSL/TLS y de autenticación de correo (DMARC/SPF/DKIM) completa
- [x] OSINT sobre personas y metadatos documentos, con foco en riesgo organizacional, no en exposición de terceros

---

## Módulos relacionados

- **[Pentesting](https://github.com/juanmalbran/Pentesting)** — la fase siguiente: la inteligencia recopilada alimenta la explotación.
- **[Red-Team](https://github.com/juanmalbran/Red-Team)** — el OSINT sobre personas y cargos clave es la base de campañas de phishing dirigido.

---

<div align="center">
  <sub>Parte del portfolio de <a href="https://github.com/juanmalbran">Juan Malbrán · M4LBYTE</a></sub>
</div>
