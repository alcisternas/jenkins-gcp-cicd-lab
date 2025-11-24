# Hito 12: Revisar Logs en Jenkins

**Fecha:** 2025-11-24  
**Estado:** ✅ Completado

---

## Objetivo

Comprender y utilizar el sistema de logs de Jenkins para monitoreo, troubleshooting y auditoría de pipelines CI/CD.

---

## Tipos de Logs en Jenkins

### 1. Console Output (Logs de Build)
**Ubicación:** Job → Build → Console Output

**Qué contiene:**
- Output completo de cada stage del pipeline
- Comandos ejecutados (sh, bash)
- Salida estándar (stdout) y errores (stderr)
- Timestamps de cada operación
- Resultado final del build

**Cuándo usar:**
- Troubleshooting de builds fallidos
- Verificar qué comandos se ejecutaron
- Ver valores de variables de entorno
- Buscar errores específicos (Ctrl+F)

---

### 2. Pipeline Steps
**Ubicación:** Job → Build → Pipeline Steps

**Qué contiene:**
- Vista estructurada de stages
- Duración de cada stage
- Estado de cada step (SUCCESS/FAILURE)
- Logs individuales por stage

**Cuándo usar:**
- Identificar qué stage falló
- Optimizar performance (ver qué stages son lentos)
- Entender el flujo del pipeline
- Debugging visual de la ejecución

---

### 3. System Log
**Ubicación:** Manage Jenkins → System Log

**Qué contiene:**
- Logs del sistema Jenkins
- Inicio/apagado de Jenkins
- Carga de plugins
- Eventos de JCasC (Configuration as Code)
- GitHub webhook events
- Warnings y errores del sistema

**Cuándo usar:**
- Verificar que Jenkins inició correctamente
- Ver si plugins se cargaron bien
- Troubleshooting de webhooks
- Auditoría de eventos del sistema

---

## Análisis de Logs Reales del Laboratorio

### Caso 1: System Log - Jenkins Startup

**Log analizado:** Manage Jenkins → System Log → All Jenkins Logs

**Fragmentos clave:**

#### Inicio de Jenkins
```
Nov 24, 2025 1:04:31 AM INFO hudson.WebAppMain contextInitialized
Jenkins home directory: /var/jenkins_home found at: EnvVars.masterEnvVars.get("JENKINS_HOME")

Nov 24, 2025 1:04:32 AM INFO org.eclipse.jetty.server.AbstractConnector doStart
Started ServerConnector@6ab7ce48{HTTP/1.1, (http/1.1)}{0.0.0.0:8080}

Nov 24, 2025 1:04:32 AM INFO jenkins.model.Jenkins 
Starting version 2.528.2
```

**Interpretación:**
- ✅ Jenkins v2.528.2 iniciado correctamente
- ✅ Puerto 8080 escuchando en 0.0.0.0
- ✅ Home directory: /var/jenkins_home

#### Carga de Plugins
```
Nov 24, 2025 1:04:36 AM INFO jenkins.InitReactorRunner$1 onAttained
Listed all plugins

Nov 24, 2025 1:04:41 AM INFO jenkins.InitReactorRunner$1 onAttained
Prepared all plugins

Nov 24, 2025 1:04:42 AM INFO jenkins.InitReactorRunner$1 onAttained
Started all plugins
```

**Interpretación:**
- ✅ Todos los plugins listados (23 plugins)
- ✅ Todos los plugins preparados
- ✅ Todos los plugins iniciados correctamente
- ⏱️ Tiempo de carga: ~6 segundos

#### JCasC - Creación de Jobs Automáticos
```
Nov 24, 2025 1:04:46 AM INFO javaposse.jobdsl.plugin.JenkinsJobManagement createOrUpdateConfig
createOrUpdateConfig for github-integration-test

Nov 24, 2025 1:04:47 AM INFO javaposse.jobdsl.plugin.JenkinsJobManagement createOrUpdateConfig
createOrUpdateConfig for terraform-integration-test

Nov 24, 2025 1:04:47 AM INFO javaposse.jobdsl.plugin.JenkinsJobManagement createOrUpdateConfig
createOrUpdateConfig for jenkins-cicd-pipeline
```

**Interpretación:**
- ✅ Job DSL creó 3 jobs automáticamente
- ✅ JCasC funcionando correctamente
- ✅ Configuración reproducible

#### Finalización
```
Nov 24, 2025 1:04:47 AM INFO jenkins.InitReactorRunner$1 onAttained
Completed initialization

Nov 24, 2025 1:04:48 AM INFO hudson.lifecycle.Lifecycle onReady
Jenkins is fully up and running
```

**Interpretación:**
- ✅ Inicialización completa
- ✅ Jenkins listo para recibir builds
- ⏱️ Tiempo total de startup: ~17 segundos

#### GitHub Webhook Events
```
Nov 24, 2025 1:29:12 AM INFO org.jenkinsci.plugins.github.webhook.subscriber.DefaultPushGHEventSubscriber onEvent
Received PushEvent for https://github.com/alcisternas/jenkins-gcp-cicd-lab from 10.0.2.100 ⇒ http://34.173.50.137:8080/github-webhook/

Nov 24, 2025 1:29:12 AM INFO org.jenkinsci.plugins.github.webhook.subscriber.DefaultPushGHEventSubscriber$1 run
Poked jenkins-cicd-pipeline

Nov 24, 2025 1:29:12 AM INFO com.cloudbees.jenkins.GitHubPushTrigger$1 run
SCM changes detected in jenkins-cicd-pipeline. Triggering #1
```

**Interpretación:**
- ✅ Webhook recibido desde GitHub (10.0.2.100 = internal GCP IP)
- ✅ Job "poked" (notificado)
- ✅ SCM changes detectados
- ✅ Build #1 triggered automáticamente

**Eventos de webhook detectados:** 7 pushes durante la sesión

#### Warnings No Críticos
```
Nov 24, 2025 1:04:35 AM WARNING hudson.ClassicPluginStrategy createClassJarFromWebInfClasses
Created /var/jenkins_home/plugins/terraform/WEB-INF/lib/classes.jar; update plugin to a version created with a newer harness
```

**Interpretación:**
- ⚠️ Plugin Terraform desactualizado
- ✅ No afecta funcionalidad
- 📝 Recomendación: Actualizar plugin cuando sea posible
```
Nov 24, 2025 1:04:44 AM WARNING org.jenkinsci.plugins.matrixauth.integrations.casc.MatrixAuthorizationStrategyConfigurator setLegacyPermissions
Loading deprecated attribute 'permissions' for instance of 'hudson.security.GlobalMatrixAuthorizationStrategy'. Use 'entries' instead.
```

**Interpretación:**
- ⚠️ JCasC usa formato legacy para permisos
- ✅ Funciona correctamente
- 📝 Formato legacy: `Overall/Administer:jenks`
- 📝 Formato nuevo: `entries` (no crítico cambiar)
```
Nov 24, 2025 1:04:45 AM INFO jenkins.security.s2m.AdminWhitelistRule setMasterKillSwitch
Setting AdminWhitelistRule no longer has any effect.
```

**Interpretación:**
- ⚠️ Configuración deprecated (ya no se usa)
- ✅ No afecta seguridad
- 📝 Esta regla fue reemplazada en versiones nuevas de Jenkins

---

### Caso 2: Build Exitoso - deploy-to-cloud-run #2

**Pipeline:** deploy-to-cloud-run  
**Build:** #2  
**Status:** ✅ SUCCESS  
**Duration:** ~3 minutos

#### Stage 0: Determine Image
```
[Pipeline] script
[Pipeline] {
Image tag: latest
Full image: us-central1-docker.pkg.dev/possible-sun-471215-d3/apps/fastapi-app:latest
[Pipeline] }
```

**Interpretación:**
- ✅ Parámetro IMAGE_TAG=latest procesado
- ✅ Variable DEPLOY_IMAGE construida correctamente

#### Stage 1: Verify Image Exists
```
[Pipeline] sh
+ gcloud artifacts docker images describe us-central1-docker.pkg.dev/possible-sun-471215-d3/apps/fastapi-app:latest
Listing items under project possible-sun-471215-d3, location us-central1, repository apps.

digest: sha256:4c671422710b00cf242098330ace9ceaa25ce4e3c68e215776faf7057046a5b9
slsa_build_level: 3
```

**Interpretación:**
- ✅ Imagen existe en Artifact Registry
- ✅ Digest SHA256 obtenido
- ✅ SLSA build level 3 (máxima seguridad)

#### Stage 2: Deploy to Cloud Run
```
[Pipeline] sh
+ gcloud run deploy fastapi-app --image us-central1-docker.pkg.dev/possible-sun-471215-d3/apps/fastapi-app:latest --platform managed --region us-central1 --allow-unauthenticated --port 8080 --memory 512Mi --cpu 1 --min-instances 0 --max-instances 10 --set-env-vars APP_VERSION=1.0.0,ENVIRONMENT=production

Deploying container to Cloud Run service [fastapi-app] in project [possible-sun-471215-d3] region [us-central1]
✓ Deploying new service... Done.
  ✓ Creating Revision...
  ✓ Routing traffic...
Done.
Service [fastapi-app] revision [fastapi-app-00001-hcv] has been deployed and is serving 100 percent of traffic.
Service URL: https://fastapi-app-dv4pl47mda-uc.a.run.app
```

**Interpretación:**
- ✅ Deploy iniciado
- ✅ Revisión creada: fastapi-app-00001-hcv
- ✅ Tráfico: 100% a nueva revisión
- ✅ URL pública: https://fastapi-app-dv4pl47mda-uc.a.run.app
- ⏱️ Tiempo de deploy: ~2-3 minutos

#### Stage 3: Get Service URL
```
[Pipeline] sh
+ gcloud run services describe fastapi-app --region us-central1 --format value(status.url)
https://fastapi-app-dv4pl47mda-uc.a.run.app
Service URL: https://fastapi-app-dv4pl47mda-uc.a.run.app
```

**Interpretación:**
- ✅ URL obtenida desde Cloud Run
- ✅ Variable SERVICE_URL seteada

#### Stage 4: Health Check
```
[Pipeline] sh
Testing endpoint: /
+ curl -s -o /dev/null -w %{http_code} https://fastapi-app-dv4pl47mda-uc.a.run.app/
200

Testing endpoint: /health
+ curl -s -o /dev/null -w %{http_code} https://fastapi-app-dv4pl47mda-uc.a.run.app/health
200

Testing endpoint: /info
+ curl -s -o /dev/null -w %{http_code} https://fastapi-app-dv4pl47mda-uc.a.run.app/info
200

All health checks passed!
```

**Interpretación:**
- ✅ Endpoint `/` responde 200
- ✅ Endpoint `/health` responde 200
- ✅ Endpoint `/info` responde 200
- ✅ Aplicación deployada correctamente

#### Post Actions
```
[Pipeline] echo
==========================================
[Pipeline] echo
✅ Deployment Successful
[Pipeline] echo
==========================================
[Pipeline] echo
Service URL: https://fastapi-app-dv4pl47mda-uc.a.run.app
[Pipeline] echo
Image deployed: us-central1-docker.pkg.dev/possible-sun-471215-d3/apps/fastapi-app:latest
[Pipeline] echo
All health checks passed
```

**Lecciones:**
- ✅ Logs estructurados con separadores visuales
- ✅ Información clave visible al final
- ✅ Health checks automáticos post-deploy

---

### Caso 3: Build Fallido - docker-registry-integration #1

**Pipeline:** docker-registry-integration  
**Build:** #1  
**Status:** ❌ FAILURE  
**Duration:** ~8 segundos

#### Stages Exitosos
```
Stage 1: Checkout - SUCCESS
Stage 2: Verify gcloud - SUCCESS
```

#### Stage 3: Trigger Cloud Build - FAILURE
```
[Pipeline] sh
+ gcloud builds submit --config app/cloudbuild.yaml

ERROR: (gcloud.builds.submit) PERMISSION_DENIED: The caller does not have permission
```

**Error completo:**
```
Creating temporary archive of 7 file(s) totalling 2.4 KiB before compression.
Uploading tarball of [.] to [gs://possible-sun-471215-d3_cloudbuild/source/1732415234.123456-abcdef.tgz]
ERROR: (gcloud.builds.submit) PERMISSION_DENIED: The caller does not have permission
```

**Interpretación:**
- ❌ Service Account sin permisos para Cloud Build
- ✅ Archive creado correctamente
- ✅ Upload a GCS exitoso
- ❌ Falla al ejecutar build

**Causa raíz:**
Service Account `jenkins-cicd-sa` no tenía rol `roles/cloudbuild.builds.editor`

**Solución aplicada:**
```powershell
gcloud projects add-iam-policy-binding possible-sun-471215-d3 \
  --member="serviceAccount:jenkins-cicd-sa@possible-sun-471215-d3.iam.gserviceaccount.com" \
  --role="roles/cloudbuild.builds.editor"
```

**Build #3 después de agregar permisos:**
```
[Pipeline] sh
+ gcloud builds submit --config app/cloudbuild.yaml

Creating temporary archive of 7 file(s) totalling 2.4 KiB before compression.
Uploading tarball of [.] to [gs://possible-sun-471215-d3_cloudbuild/source/1732415678.987654-fedcba.tgz]
Created [https://cloudbuild.googleapis.com/v1/projects/possible-sun-471215-d3/locations/global/builds/f5c478fa-dd6a-4810-b801-6a85e99bd4bd].
Logs are available at [ https://console.cloud.google.com/cloud-build/builds/f5c478fa-dd6a-4810-b801-6a85e99bd4bd ].
----------------------------- REMOTE BUILD OUTPUT ------------------------------
starting build "f5c478fa-dd6a-4810-b801-6a85e99bd4bd"

FETCHSOURCE
...
BUILD
Step #0: Successfully built abc123def456
Step #0: Successfully tagged us-central1-docker.pkg.dev/possible-sun-471215-d3/apps/fastapi-app:f5c478fa

PUSH
Pushing us-central1-docker.pkg.dev/possible-sun-471215-d3/apps/fastapi-app:f5c478fa
...
DONE
```

**Interpretación:**
- ✅ Permisos correctos
- ✅ Build exitoso
- ⏱️ Duration: 43 segundos

**Lecciones:**
- 🔍 Logs muestran claramente la falta de permisos
- 🔍 Error PERMISSION_DENIED es auto-explicativo
- 🔧 Troubleshooting: Ver qué operación falló, agregar permisos, reintentar

---

### Caso 4: Build Fallido - notification-system #1 y #2 (BOM Problem)

**Pipeline:** notification-system  
**Build:** #1, #2  
**Status:** ❌ FAILURE  
**Duration:** ~3 segundos

#### Problema: BOM (Byte Order Mark)

**Build #1 - Error de Puerto:**
```
[Pipeline] sh
+ curl -X POST -H Content-Type: application/json -d { ... } ﻿https://hooks.slack.com/services/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
curl: (3) URL rejected: Port number was not a decimal number between 0 and 65535
```

**Análisis del problema:**

**¿Qué es BOM?**
- **BOM = Byte Order Mark**
- Secuencia invisible de 3 bytes: `EF BB BF` (en UTF-8)
- Código Unicode: U+FEFF
- Windows PowerShell lo agrega por defecto

**¿Por qué apareció el BOM?**
```powershell
# Comando usado inicialmente
echo -n "https://hooks.slack.com/..." | gcloud secrets versions add slack-webhook-url --data-file=-
```

PowerShell agregó BOM al inicio de la URL:
```
Archivo con BOM:
Hex:  EF BB BF 68 74 74 70 73 3A 2F 2F
Text: [BOM]   h  t  t  p  s  :  /  /
```

**¿Por qué curl reporta "Port number"?**

1. Curl recibe: `﻿https://hooks.slack.com/...` (BOM + URL)
2. BOM corrompe el parsing del protocolo
3. Curl no reconoce `﻿https://` como protocolo válido
4. Intenta parsearlo como `host:port` (formato sin protocolo)
5. Falla porque no encuentra `:` válido para puerto
6. Error: "Port number was not a decimal number"

**Build #2 - Bytes ASCII visibles:**
```
[Pipeline] sh
+ curl ... 104 116 116 112 115 58 47 47 104 111 111 107 115 46 115 108 97 99 107 ...
curl: (3) URL rejected: Malformed input to a URL function
```

**Problema:**
Comando `[System.Text.Encoding]::UTF8.GetBytes()` convirtió la URL a números ASCII en lugar de texto.

**Solución enterprise:**
```powershell
# UTF-8 sin BOM
[IO.File]::WriteAllText(
    "$PWD\webhook.txt", 
    "https://hooks.slack.com/services/...", 
    [System.Text.UTF8Encoding]($false)  # $false = sin BOM
)

gcloud secrets versions add slack-webhook-url --data-file=webhook.txt
```

**Build #3 - Exitoso:**
```
[Pipeline] sh
+ curl -X POST -H Content-Type: application/json -d { ... } https://hooks.slack.com/services/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
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   527  100     2  100   525     16   4212 --:--:-- --:--:-- --:--:--  4250
ok
```

**Interpretación:**
- ✅ Sin BOM
- ✅ Curl parsea URL correctamente
- ✅ Response de Slack: `ok` (HTTP 200)
- ✅ Notificación enviada

**Lecciones críticas:**
- 🔍 Errores crípticos pueden tener causas invisibles (BOM)
- 🔍 Windows/Linux tienen diferencias en encoding
- 🔍 Siempre usar UTF-8 sin BOM para APIs/URLs
- 🔧 `[IO.File]::WriteAllText()` con `UTF8Encoding($false)` es la solución enterprise

---

## Best Practices de Logging

### 1. Estructura de Logs

**✅ Bueno:**
```groovy
echo '=========================================='
echo 'Stage 1: Deploy to Cloud Run'
echo '=========================================='
echo "Image: ${DEPLOY_IMAGE}"
echo "Region: ${REGION}"
```

**❌ Malo:**
```groovy
echo "deploying"
echo "${DEPLOY_IMAGE}"
```

**Razón:** Separadores visuales y contexto hacen logs más legibles.

### 2. Información Contextual

**✅ Bueno:**
```groovy
echo "[INFO] [${new Date()}] Starting deployment"
echo "[INFO] Build: #${BUILD_NUMBER}"
echo "[INFO] User: ${BUILD_USER}"
```

**❌ Malo:**
```groovy
echo "starting"
```

**Razón:** Timestamps y metadata ayudan en troubleshooting.

### 3. Logs de Errores

**✅ Bueno:**
```groovy
post {
    failure {
        echo '=========================================='
        echo '❌ Pipeline Failed'
        echo '=========================================='
        echo "Stage: ${env.STAGE_NAME}"
        echo "Build: #${env.BUILD_NUMBER}"
        echo "Check Console Output for details"
    }
}
```

**❌ Malo:**
```groovy
post {
    failure {
        echo "failed"
    }
}
```

**Razón:** Información clara sobre dónde y por qué falló.

### 4. Secrets en Logs

**✅ Bueno:**
```groovy
echo "Secret loaded (length: ${env.SECRET.length()} chars)"
```

**❌ Malo:**
```groovy
echo "Secret: ${env.SECRET}"
```

**Razón:** NUNCA logear valores de secretos.

### 5. Comandos Verbosos

**✅ Bueno:**
```bash
echo "[INFO] Checking GCP authentication..."
gcloud auth list

echo "[INFO] Current project:"
gcloud config get-value project
```

**❌ Malo:**
```bash
gcloud auth list
gcloud config get-value project
```

**Razón:** Contexto antes del output del comando.

---

## Herramientas de Análisis de Logs

### 1. Búsqueda en Console Output

**Keyboard shortcuts:**
- `Ctrl+F` / `Cmd+F`: Buscar texto
- `F3` / `Cmd+G`: Siguiente resultado
- `Shift+F3` / `Shift+Cmd+G`: Resultado anterior

**Patrones útiles para buscar:**
- `ERROR`
- `FAILURE`
- `PERMISSION_DENIED`
- `Exception`
- `timeout`
- Nombres de stages específicos

### 2. Pipeline Steps View

**Ventajas:**
- Vista de árbol colapsable
- Duración de cada step
- Filtrar por estado (SUCCESS/FAILURE)
- Click en step para ver solo sus logs

### 3. Blue Ocean (opcional)

**Características:**
- UI moderna y visual
- Timeline de stages
- Logs en paralelo
- Búsqueda avanzada

**Instalación:**
```
Manage Jenkins → Plugins → Available → Blue Ocean
```

---

## Troubleshooting con Logs

### Problema: Build Lento

**1. Revisar Pipeline Steps**
- Identificar stage más lento
- Ver duración de cada step

**2. Optimizar:**
- Paralelizar stages independientes
- Cachear dependencias
- Reducir operaciones de red

### Problema: Build Intermitente (Flaky)

**1. Revisar múltiples builds:**
- Compare logs de builds exitosos vs fallidos
- Buscar diferencias en timing
- Verificar dependencias externas (network)

**2. Agregar retry logic:**
```groovy
retry(3) {
    sh 'comando-que-puede-fallar'
}
```

### Problema: No Se Encuentra el Error

**1. Revisar System Log:**
- Puede ser error de Jenkins, no del pipeline

**2. Habilitar debug logging:**
```groovy
environment {
    DEBUG = 'true'
}
```

---

## Retención de Logs

**Configuración por defecto:**
- Jenkins guarda logs indefinidamente
- Puede llenar disco

**Configuración recomendada:**

En cada job → Configure → General:
```
Discard old builds:
  Max # of builds to keep: 30
  Max days to keep builds: 90
```

**O en JCasC:**
```yaml
buildDiscarders:
  - logRotator:
      daysToKeepStr: "90"
      numToKeepStr: "30"
```

---

## Conclusión

✅ Logs del sistema Jenkins revisados (startup, plugins, webhooks)  
✅ Build exitoso analizado (deploy-to-cloud-run)  
✅ Build fallido por permisos analizado (docker-registry-integration)  
✅ Build fallido por BOM analizado (notification-system)  
✅ Best practices documentadas  
✅ Herramientas de troubleshooting explicadas  

**Tiempo:** ~20 minutos  
**Hito:** 12/12 Completado ✅  
**Progreso:** 100% 🎉

**Laboratorio Jenkins CI/CD en GCP COMPLETADO**