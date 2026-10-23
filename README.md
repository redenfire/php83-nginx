# PHP-FPM + Nginx migliorato

Immagine Docker **Alpine** con **Nginx** + **PHP-FPM** gestiti da **Supervisor**.
Ottimizzata per applicazioni web che richiedono molte estensioni PHP (Imagick, XSL, mysqli, ecc.) senza pesare sull'immagine finale.

## Cosa include

- **Nginx** come web server
- **PHP-FPM** come process manager PHP (modello FastCGI)
- **Supervisor** per mantenere entrambi attivi
- **Estensioni PHP** abilitate: `calendar`, `ctype`, `dom`, `exif`, `fileinfo`, `filter`, `ftp`, `gettext`, `mbstring`, `mysqli`, `pdo_mysql`, `shmop`, `sockets`, `sysvmsg`, `sysvsem`, `sysvshm`, `xsl`, `opcache`, `curl`, `imagick`
- **GD** (con JPEG/FreeType/PNG) solo nelle varianti con GD (`WITH_GD=1`, tag `*-gd`)

## Struttura

| File            | Ruolo                                       |
|-----------------|---------------------------------------------|
| `Dockerfile`    | Build dell'immagine                         |
| `nginx.conf`    | Configurazione server Nginx                |
| `supervisord.conf` | Gestione dei processi Nginx e PHP-FPM   |

## Build manuale dell'immagine

Dalla root del repository, variante normale (senza GD):

```bash
docker build -t nginx-fpm .
```

Variante con GD (JPEG, FreeType, PNG):

```bash
docker build --build-arg WITH_GD=1 -t nginx-fpm-gd .
```

Puoi specificare un nome/tag diverso:

```bash
docker build -t mio-nome/nginx-fpm:v1 .
```

Se usi un'architettura diversa da quella host (es. ARM su Intel):

```bash
docker build --platform linux/amd64 -t nginx-fpm .
```

> L'immagine base `php:8.3.36-fpm-alpine3.23` viene scaricata automaticamente dal registry se non è già presente localmente.

## Usare l'immagine prebuild da GitHub

L'immagine viene compilata automaticamente su GitHub Actions ad ogni push su `main` o tag `v*` e pubblicata su GitHub Container Registry in due varianti: **normale** (senza GD) e **con GD** (JPEG/FreeType/PNG).

| Tag                        | Architettura | Variante |
|----------------------------|--------------|----------|
| `ghcr.io/redenfire/php83-nginx:latest`    | **amd64** (x86_64) | normale |
| `ghcr.io/redenfire/php83-nginx:arm`       | **arm64** | normale |
| `ghcr.io/redenfire/php83-nginx:latest-gd` | **amd64** (x86_64) | con GD |
| `ghcr.io/redenfire/php83-nginx:arm-gd`    | **arm64** | con GD |

Pull per architettura amd64:

```bash
docker pull ghcr.io/redenfire/php83-nginx:latest       # normale
docker pull ghcr.io/redenfire/php83-nginx:latest-gd    # con GD
```

Pull per architettura arm64 (es. Raspberry Pi, Apple Silicon):

```bash
docker pull ghcr.io/redenfire/php83-nginx:arm          # normale
docker pull ghcr.io/redenfire/php83-nginx:arm-gd       # con GD
```

Per una versione con tag specifico (es. `v1`):

```bash
docker pull ghcr.io/redenfire/php83-nginx:v1            # amd64 normale
docker pull ghcr.io/redenfire/php83-nginx:arm-v1        # arm64 normale
docker pull ghcr.io/redenfire/php83-nginx:gd-v1         # amd64 con GD
docker pull ghcr.io/redenfire/php83-nginx:arm-gd-v1     # arm64 con GD
```

> Se il package non è pubblico, devi prima fare login con `docker login ghcr.io -u NOME_UTENTE --password-stdin`.
> I tag `latest` e `arm` sono **senza** GD; per GD usa `latest-gd` e `arm-gd`.

## Esecuzione

Dopo la build avvia il container:

```bash
docker run -d --name nginx-fpm -p 8080:80 nginx-fpm
```

Il container espone la porta **80**. Con questo esempio accedi su `http://localhost:8080`.

Il documento root è `/var/www/html`. Per montare il tuo codice dal host:

```bash
docker run -d --name nginx-fpm -p 8080:80 -v /path/del/tuo/codice:/var/www/html nginx-fpm
```

## Verifica

Senza un file `index.php`/`index.html` nel document root la home restituisce `403`. Per testare che PHP-FPM funzioni:

```bash
docker exec nginx-fpm sh -c 'echo "<?php echo \"ok \" . PHP_VERSION; ?>" > /var/www/html/index.php'
curl http://localhost:8080/
```

## Arresto e pulizia

```bash
docker stop nginx-fpm
docker rm nginx-fpm
```

Per rimuovere anche l'immagine locale:

```bash
docker rmi nginx-fpm
```

## Note

- Il container esegue come `root` perché Nginx e Supervisor richiedono privilegi elevati; i worker Nginx girano come `nginx`, quelli PHP-FPM come `www-data`.
- `COPY . /var/www/html` copia il codice sorgente all'interno dell'immagine. Se usi un volume basta ignorarlo.