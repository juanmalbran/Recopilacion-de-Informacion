# Informe de Reconocimiento · OSINT & Recon

> **Nota sobre el objetivo.** Esta práctica se realizó sobre una organización real de e-commerce de gran escala, elegida dentro de su **programa público de Bug Bounty en HackerOne** y respetando estrictamente su *scope* y sus *rules of engagement*. En cumplimiento de las normas de divulgación responsable, **el nombre de la organización y sus activos concretos (subdominios, IPs) se han anonimizado**: el foco de este documento es la **metodología**, no el objetivo. A lo largo del texto se usa `objetivo.com` como marcador del dominio.

---

## 1. Scope y reglas de compromiso

Antes de cualquier escaneo, lo primero es definir qué está permitido tocar. El programa publicaba un *scope* **wildcard** sobre `*.objetivo.com`, lo que autoriza **reconocimiento vertical** (enumerar subdominios dentro del dominio raíz). Reglas respetadas en todo momento:

- **Sin escaneo masivo ruidoso** ni interacción invasiva innecesaria.
- **Prohibido cualquier prueba de DoS** o que afecte la disponibilidad.
- **Respeto absoluto a datos reales:** ante cualquier dato sensible o de usuarios, no descargar, alterar ni manipular.
- Conciencia de los **Tiers de activos**: los dominios principales suelen tener mayores protecciones (WAF, etc.).

**Horizontal vs. vertical:** el reconocimiento horizontal busca la superficie total de una corporación (otros dominios raíz, ASNs, adquisiciones). Como el scope era un wildcard específico, el trabajo se concentró en el **vertical**: profundizar dentro de `objetivo.com` para hallar activos como `api.objetivo.com` o `portal.objetivo.com`.

---

## 2. Fase 1 — Footprinting (pasivo)

Recolección desde fuentes públicas, sin tocar directamente la infraestructura del objetivo:

- **Enumeración de subdominios por certificados** — consulta a *Certificate Transparency* (`crt.sh`, `ctfr`) para extraer subdominios a partir de los certificados TLS emitidos.
- **DNS brute-force controlado** — `shuffledns` y `Amass` con diccionarios, resolviendo contra resolvers fiables.
- **Identidades digitales** — correlación por **Google Analytics / Tag IDs** compartidos entre dominios para descubrir activos del mismo dueño.
- **TLS probing** — análisis de los certificados y sus SAN para revelar nombres de host adicionales.
- **Web scraping y cachés** — extracción de enlaces y referencias desde la web pública y archivos cacheados.

---

## 3. Fase 2 — Fingerprinting (activo controlado)

Interacción directa mínima para validar y caracterizar lo descubierto:

- **Validación de hosts vivos** — `httpx` para separar los subdominios que responden de los que no, con sus códigos, títulos y headers.
- **Escaneo de puertos** — `masscan` sobre los hosts vivos para mapear servicios expuestos.
- **Detección de tecnologías** — identificación del stack (servidores, frameworks, CDNs) por *fingerprinting* de respuestas.
- **Detección de WAF** — `wafw00f` para saber qué activos están detrás de un Web Application Firewall (los Tier 1, típicamente).
- **Fuzzing de directorios** — `ffuf` para descubrir rutas y recursos no enlazados.

---

## 4. Fase 3 — Análisis de vulnerabilidades

- **Escaneo automatizado** — `nuclei` con sus plantillas para detectar exposiciones y *misconfigurations* conocidas.
- **Subdomain takeover** — búsqueda de subdominios que apuntan a servicios de terceros dados de baja (CNAME colgante), un vector clásico de secuestro.
- **Análisis SSL/TLS** — revisión de configuraciones débiles, versiones y cifrados obsoletos.
- **Salud del correo (DMARC / SPF / DKIM)** — evaluación de las políticas anti-spoofing del dominio, que si faltan o están mal permiten suplantación de correo.

---

## 5. Fase 4 — OSINT sobre personas

- **Empleados y cargos clave** — `Maltego` y *Google Dorking* para mapear personas asociadas a la organización y sus roles (útil para entender la superficie humana / phishing en un engagement real).
- **Extracción de metadatos** — `exiftool` sobre documentos e imágenes públicas para revelar información oculta (autores, software, rutas internas).

---

## 6. Resultado

La salida del trabajo es un **mapa priorizado de la superficie de ataque**: subdominios vivos clasificados por valor (portales de autenticación, APIs, entornos de test/beta, paneles de administración), el stack tecnológico identificado, los mecanismos de protección detectados (CDN, WAF, HSTS) y los posibles vectores a profundizar — todo documentado como el plan inicial de un ejercicio ofensivo real, **sin ejecutar ninguna prueba intrusiva** más allá del reconocimiento autorizado.

---

## Stack

`shuffledns` · `Amass` · `httpx` · `masscan` · `nuclei` · `Maltego` · `wafw00f` · `ffuf` · `exiftool` · `crt.sh / ctfr`

---

<div align="center">
  <sub>Parte del portfolio de <a href="https://github.com/juanmalbran">Juan Malbrán · M4LBYTE</a></sub>
</div>
