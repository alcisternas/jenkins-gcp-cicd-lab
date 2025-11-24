# Hito 11: Configurar Notificaciones (Slack)

**Fecha:** 2025-11-24  
**Estado:** ✅ Completado

---

## Objetivo

Configurar Jenkins para enviar notificaciones de builds a Slack usando webhooks almacenados en Secret Manager.

---

## Configuración de Slack

### 1. Crear Workspace

**Workspace:** `jenkins-lab-alejandro`  
**URL:** https://jenkins-lab-alejandro.slack.com

### 2. Crear Canal

**Canal:** `#jenkins-notifications`  
**Propósito:** Recibir notificaciones de builds de Jenkins

### 3. Crear App de Slack

**Pasos:**
1. Ve a: https://api.slack.com/apps
2. Click en **"Create New App"**
3. Selecciona **"From scratch"**
4. **App Name:** `Jenkins` (sin espacios ni caracteres especiales)
5. **Workspace:** jenkins-lab-alejandro
6. Click **"Create App"**

**Problema inicial:** Nombre "Jenkins CI/CD" con espacios causaba error "something went wrong"  
**Solución:** Usar nombre simple "Jenkins"

### 4. Configurar Incoming Webhook

**Pasos:**
1. En la app creada, ve a: **Features → Incoming Webhooks**
2. Activa el toggle **"Activate Incoming Webhooks"**
3. Click en **"Add New Webhook to Workspace"**
4. Selecciona canal: **#jenkins-notifications**
5. Click **"Allow"**
6. **Copia la Webhook URL**

**Webhook URL obtenida:**
```
https://hooks.slack.com/services/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
```

---

## Guardar Webhook en Secret Manager

### Problema: BOM (Byte Order Mark) en Windows

**Error inicial:**
```
curl: (3) URL rejected: Malformed input to a URL function
```

**Causa:** PowerShell en Windows agrega BOM al usar `echo` o pipes, corrompiendo la URL.

**Intentos fallidos:**
1. `echo -n "..." | gcloud secrets versions add` → Agregó BOM
2. `[System.Text.Encoding]::UTF8.GetBytes()` → Convirtió a bytes ASCII numéricos

**Solución enterprise:**
```powershell
# Crear archivo UTF-8 sin BOM
[IO.File]::WriteAllText("$PWD\webhook.txt", "https://hooks.slack.com/services/...", [System.Text.UTF8Encoding]($false))

# Subir a Secret Manager
gcloud secrets versions add slack-webhook-url --data-file=webhook.txt --project=possible-sun-471215-d3

# Limpiar
Remove-Item webhook.txt
```

**Resultado:** Versión 4 del secreto creada correctamente sin BOM.

---

## Pipeline de Notificaciones

**Job:** `notification-system`  
**Tipo:** Pipeline parametrizado

### Parámetros
```groovy
parameters {
    choice(
        name: 'BUILD_STATUS',
        choices: ['SUCCESS', 'FAILURE', 'UNSTABLE'],
        description: 'Simulate build status for notification'
    )
    booleanParam(
        name: 'SEND_SLACK',
        defaultValue: true,
        description: 'Send Slack notification'
    )
}
```

---

## Stages del Pipeline

### Stage 1: Load Secrets
```groovy
env.SLACK_WEBHOOK = sh(
    script: """
        gcloud secrets versions access latest \
            --secret=slack-webhook-url \
            --project=${GCP_PROJECT}
    """,
    returnStdout: true
).trim()
```

**Output:**
```
✅ Slack webhook loaded from Secret Manager
```

### Stage 2: Prepare Message
```groovy
def statusEmoji = ''
def statusColor = ''

switch(params.BUILD_STATUS) {
    case 'SUCCESS':
        statusEmoji = ':white_check_mark:'
        statusColor = 'good'
        break
    case 'FAILURE':
        statusEmoji = ':x:'
        statusColor = 'danger'
        break
    case 'UNSTABLE':
        statusEmoji = ':warning:'
        statusColor = 'warning'
        break
}
```

**Slack colors:**
- `good` = Verde
- `danger` = Rojo
- `warning` = Amarillo

### Stage 3: Send Slack Notification

**Payload JSON:**
```json
{
    "text": ":white_check_mark: Jenkins Build Notification",
    "attachments": [
        {
            "color": "good",
            "fields": [
                {"title": "Job", "value": "notification-system", "short": true},
                {"title": "Build", "value": "#3", "short": true},
                {"title": "Status", "value": "SUCCESS", "short": true},
                {"title": "Duration", "value": "2.7 sec", "short": true},
                {"title": "URL", "value": "http://localhost:8080/...", "short": false}
            ],
            "footer": "Jenkins CI/CD Lab - Hito 11",
            "ts": 1763953190.527
        }
    ]
}
```

**Envío con curl:**
```bash
curl -X POST \
    -H 'Content-Type: application/json' \
    -d '${payload}' \
    '${SLACK_WEBHOOK}'
```

**Response de Slack:** `ok` (HTTP 200)

---

## Validación

### Test 1: SUCCESS Notification

**Trigger:** Build with Parameters  
**Parámetros:**
- BUILD_STATUS: SUCCESS
- SEND_SLACK: true

**Build:** #3  
**Resultado:** ✅ SUCCESS

**Notificación en Slack:**
- ✅ Mensaje recibido en canal #jenkins-notifications
- ✅ Color verde (good)
- ✅ Emoji: :white_check_mark:
- ✅ Todos los campos mostrados correctamente
- ✅ Link a build (localhost:8080)

**Curl output:**
```
% Total    % Received % Xferd  Average Speed
  100   527  100     2  100   525     16   4212
ok
```

**Timeline:**
- 00:00 - Load Secrets (webhook desde Secret Manager)
- 00:02 - Prepare Message (emoji, color)
- 00:03 - Send Slack (curl POST)
- 00:04 - Response: ok
- 00:05 - Pipeline complete

---

## Post Actions

### Success
```groovy
echo "Status simulated: ${params.BUILD_STATUS}"
echo "Slack sent: ${params.SEND_SLACK}"
```

### Failure
```groovy
// Envía notificación de falla automática
def payload = """
{
    "text": ":x: Jenkins Build Failed",
    "attachments": [{
        "color": "danger",
        "text": "Build #${BUILD_NUMBER} failed"
    }]
}
"""
```

### Always
```bash
unset SLACK_WEBHOOK
echo "Secrets cleared from environment"
```

---

## Lecciones Aprendidas

### 1. BOM en Windows es un Problema Real

**Problema:** PowerShell agrega BOM por defecto en UTF-8.

**Impacto:** Corrompe URLs y causa errores de parsing en curl.

**Solución:** Usar `[IO.File]::WriteAllText()` con `UTF8Encoding($false)`.

**Aprendizaje:** En ambientes Windows, siempre verificar encoding al crear archivos para Linux/APIs.

### 2. Nombres de Apps de Slack

**Problema:** Caracteres especiales y espacios en nombres causan errores crípticos.

**Error:** "Hmm, something went wrong. Try Again?"

**Solución:** Usar nombres simples sin espacios: "Jenkins" en lugar de "Jenkins CI/CD".

### 3. Slack Webhook Format

**Formato correcto:**
```
https://hooks.slack.com/services/T.../B.../...
```

**NO agregar:**
- Espacios
- Saltos de línea
- BOM
- Caracteres invisibles

### 4. Curl Response "ok"

**Response:** `ok` (texto plano)  
**HTTP Status:** 200  
**Significa:** Mensaje procesado correctamente por Slack

**NO es un error**, es la respuesta exitosa estándar de Slack.

### 5. Secret Manager Versioning

**Ventaja:** Permite múltiples intentos sin perder versiones anteriores.

**Uso:**
- Versión 1: Valor inicial (placeholder)
- Versión 2: Webhook real con BOM (fallido)
- Versión 3: Intentos con encoding (fallidos)
- Versión 4: Sin BOM (exitoso) ✅

**`latest`** siempre apunta a la versión más reciente.

---

## Uso en Otros Pipelines

### Ejemplo: Notificar Deploy
```groovy
stage('Notify Deploy') {
    steps {
        script {
            def webhook = sh(
                script: "gcloud secrets versions access latest --secret=slack-webhook-url",
                returnStdout: true
            ).trim()
            
            sh """
                curl -X POST -H 'Content-Type: application/json' \
                -d '{"text": ":rocket: Deployed to Cloud Run"}' \
                '${webhook}'
            """
        }
    }
}
```

---

## Conclusión

✅ Slack workspace configurado  
✅ Incoming webhook creado  
✅ Webhook almacenado en Secret Manager sin BOM  
✅ Pipeline envía notificaciones correctamente  
✅ Notificaciones visuales con colores y emojis  
✅ Listo para integrar en pipelines de producción  

**Tiempo:** ~45 minutos (incluyendo troubleshooting BOM)  
**Hito:** 11/12 Completado ✅  
**Progreso:** 91.7%  

**Próximo:** H12 - Logs (último hito)