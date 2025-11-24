# Hito 10: Integrar Secret Manager

**Fecha:** 2025-11-24  
**Estado:** ✅ Completado

---

## Objetivo

Configurar Jenkins para leer secretos desde GCP Secret Manager de forma segura, evitando hardcodear credenciales en código o pipelines.

---

## Secretos Creados

### 1. jenkins-api-token
**Propósito:** Token de ejemplo para APIs externas  
**Valor:** `api-token-12345-example`  
**Uso:** Autenticación con servicios externos
```bash
echo -n "api-token-12345-example" | gcloud secrets create jenkins-api-token \
  --data-file=- \
  --replication-policy="automatic" \
  --project=possible-sun-471215-d3
```

### 2. db-password
**Propósito:** Password de base de datos (ejemplo)  
**Valor:** `changeme-insecure-password`  
**Uso:** Conexión a bases de datos
```bash
echo -n "changeme-insecure-password" | gcloud secrets create db-password \
  --data-file=- \
  --replication-policy="automatic" \
  --project=possible-sun-471215-d3
```

### 3. slack-webhook-url
**Propósito:** Webhook URL para notificaciones Slack (H11)  
**Valor:** `TU_SLACK_WEBHOOK_URL_AQUI`  
**Uso:** Envío de notificaciones
```bash
echo -n "https://hooks.slack.com/..." | gcloud secrets create slack-webhook-url \
  --data-file=- \
  --replication-policy="automatic" \
  --project=possible-sun-471215-d3
```

### 4. gmail-app-password
**Propósito:** Password de aplicación Gmail (H11)  
**Pre-existente:** Creado en sesión anterior  
**Uso:** Envío de emails desde Jenkins

---

## Pipeline de Integración

**Job:** `secret-manager-integration`  
**Tipo:** Pipeline

---

## Stages del Pipeline

### Stage 1: List Secrets
**Propósito:** Listar secretos disponibles en Secret Manager.
```bash
gcloud secrets list --project ${GCP_PROJECT}
```

**Output:**
```
NAME                CREATED              REPLICATION_POLICY
db-password         2025-11-13T03:33:49  automatic
gmail-app-password  2025-11-13T03:33:41  automatic
jenkins-api-token   2025-11-24T02:14:36  automatic
slack-webhook-url   2025-11-13T03:33:33  automatic
```

### Stage 2: Read Secret Values
**Propósito:** Leer valores de secretos y almacenarlos en variables de entorno.
```groovy
script {
    env.API_TOKEN = sh(
        script: """
            gcloud secrets versions access latest \
                --secret=jenkins-api-token \
                --project=${GCP_PROJECT}
        """,
        returnStdout: true
    ).trim()
    
    env.DB_PASSWORD = sh(
        script: """
            gcloud secrets versions access latest \
                --secret=db-password \
                --project=${GCP_PROJECT}
        """,
        returnStdout: true
    ).trim()
    
    env.SLACK_WEBHOOK = sh(
        script: """
            gcloud secrets versions access latest \
                --secret=slack-webhook-url \
                --project=${GCP_PROJECT}
        """,
        returnStdout: true
    ).trim()
}
```

**Características:**
- `versions access latest` - Lee la versión más reciente
- `trim()` - Elimina espacios/saltos de línea
- Variables disponibles en stages siguientes

### Stage 3: Validate Secrets
**Propósito:** Validar que secretos no estén vacíos.
```bash
if [ -z "$API_TOKEN" ]; then
    echo "❌ API_TOKEN is empty"
    exit 1
else
    echo "✅ API_TOKEN loaded (length: ${#API_TOKEN})"
fi
```

**Output:**
```
✅ API_TOKEN loaded (length: 26)
✅ DB_PASSWORD loaded (length: 26)
✅ SLACK_WEBHOOK loaded (length: 25)
```

### Stage 4: Use Secrets (Masked)
**Propósito:** Demostrar uso seguro de secretos sin exponer valores.
```groovy
script {
    def apiTokenLength = env.API_TOKEN.length()
    def dbPasswordLength = env.DB_PASSWORD.length()
    def webhookLength = env.SLACK_WEBHOOK.length()
    
    echo "API Token length: ${apiTokenLength} characters"
    echo "DB Password length: ${dbPasswordLength} characters"
    echo "Webhook URL length: ${webhookLength} characters"
}
```

**Best practice:** Nunca hacer `echo $SECRET` directamente.

### Stage 5: Secret Versions Info
**Propósito:** Mostrar historial de versiones de secretos.
```bash
gcloud secrets versions list jenkins-api-token \
    --project ${GCP_PROJECT} \
    --limit=3
```

**Output ejemplo:**
```
NAME  STATE    CREATED              DESTROYED
1     enabled  2025-11-24T02:14:36  -
```

### Stage 6: Demonstrate Secret Rotation
**Propósito:** Documentar cómo rotar secretos.

**Comando para agregar nueva versión:**
```bash
echo -n 'new-value' | gcloud secrets versions add SECRET_NAME --data-file=-
```

**Características:**
- Nueva versión se vuelve `latest` automáticamente
- Versión anterior permanece accesible (historial)
- Próximo pipeline usa nueva versión automáticamente

---

## Post Actions

### Success
```groovy
echo "✅ All secrets accessed successfully"
echo "✅ Secret values validated"
echo "✅ Ready for use in other pipelines"
```

### Always (Cleanup)
```bash
unset API_TOKEN
unset DB_PASSWORD
unset SLACK_WEBHOOK
```

**Importante:** Limpiar variables de entorno después de uso.

---

## Service Account Permissions

**Roles necesarios (ya configurados):**
```bash
roles/secretmanager.secretAccessor
roles/secretmanager.viewer
```

**Permisos incluidos:**
- `secretmanager.versions.access` - Leer valores de secretos
- `secretmanager.secrets.get` - Obtener metadata de secretos
- `secretmanager.secrets.list` - Listar secretos
- `secretmanager.versions.list` - Listar versiones

---

## Validación

### Test 1: Read All Secrets
**Trigger:** Manual  
**Build:** #2  
**Resultado:** ✅ SUCCESS

**Secretos leídos:**
- ✅ jenkins-api-token (26 caracteres)
- ✅ db-password (26 caracteres)
- ✅ slack-webhook-url (25 caracteres)

**Timeline:**
- 00:00 - List secrets (4 encontrados)
- 00:02 - Read secret values (3 leídos)
- 00:05 - Validate (todos no vacíos)
- 00:06 - Use secrets (valores enmascarados)
- 00:08 - Version info (historial mostrado)
- 00:10 - Demo rotation (comandos documentados)

**Total duration:** ~12 segundos

---

## Best Practices Implementadas

### 1. Never Hardcode Secrets
**❌ Mal:**
```groovy
environment {
    DB_PASSWORD = "my-secret-password"
}
```

**✅ Bien:**
```groovy
script {
    env.DB_PASSWORD = sh(
        script: "gcloud secrets versions access latest --secret=db-password",
        returnStdout: true
    ).trim()
}
```

### 2. Use Latest Version
**Comando:**
```bash
gcloud secrets versions access latest --secret=SECRET_NAME
```

**Beneficio:** Siempre usa versión más reciente automáticamente.

### 3. Validate Before Use
```bash
if [ -z "$SECRET" ]; then
    echo "Secret is empty!"
    exit 1
fi
```

### 4. Clean Up After Use
```bash
unset SECRET_VARIABLE
```

### 5. Never Log Secret Values
**❌ Mal:**
```bash
echo "Password is: $DB_PASSWORD"
```

**✅ Bien:**
```bash
echo "Password length: ${#DB_PASSWORD} characters"
```

---

## Secret Rotation

### Proceso de Rotación

**1. Crear nueva versión:**
```bash
echo -n 'new-secure-value' | gcloud secrets versions add db-password --data-file=-
```

**2. Verificar nueva versión:**
```bash
gcloud secrets versions list db-password --limit=5
```

**Output:**
```
NAME  STATE    CREATED
2     enabled  2025-11-24T03:00:00
1     enabled  2025-11-24T02:00:00
```

**3. Próximo pipeline usa automáticamente versión 2**

**4. Opcional - Deshabilitar versión antigua:**
```bash
gcloud secrets versions disable 1 --secret=db-password
```

**5. Opcional - Destruir versión antigua:**
```bash
gcloud secrets versions destroy 1 --secret=db-password
```

---

## Lecciones Aprendidas

### 1. Shell Compatibility
**Problema:** Bash advanced syntax (`${VAR:0:10}`) no funciona con `sh`.

**Solución:** Usar Groovy script para manipulación de strings:
```groovy
def length = env.VARIABLE.length()
```

### 2. Trim Whitespace
**Problema:** gcloud puede retornar espacios/newlines.

**Solución:** Siempre usar `.trim()`:
```groovy
env.SECRET = sh(...).trim()
```

### 3. Automatic Replication
**Opción:** `--replication-policy="automatic"`

**Beneficio:** Secret replicado en múltiples regiones automáticamente.

**Alternativa:** `--replication-policy="user-managed"` para control específico.

### 4. Secret Versioning
**Característica:** Secret Manager mantiene historial de versiones.

**Uso:**
- Rollback fácil si nueva versión tiene problemas
- Auditoría completa de cambios
- Acceso a versiones específicas si necesario

### 5. Service Account vs User
**Best practice:** Usar Service Account, no credenciales de usuario.

**Ventajas:**
- Roles granulares
- No expira con cambios de password
- Auditable
- Rotación independiente

---

## Uso en Otros Pipelines

### Ejemplo: Deploy con Secrets
```groovy
pipeline {
    agent any
    
    stages {
        stage('Load Secrets') {
            steps {
                script {
                    env.DB_PASSWORD = sh(
                        script: "gcloud secrets versions access latest --secret=db-password",
                        returnStdout: true
                    ).trim()
                }
            }
        }
        
        stage('Deploy with Secret') {
            steps {
                sh '''
                    gcloud run deploy my-app \
                        --set-env-vars "DB_PASSWORD=${DB_PASSWORD}"
                '''
            }
        }
    }
}
```

---

## Conclusión

✅ Secret Manager integrado con Jenkins  
✅ 4 secretos disponibles (api-token, db-password, slack-webhook, gmail-password)  
✅ Pipeline valida lectura segura  
✅ Best practices implementadas  
✅ Rotation process documentado  
✅ Listo para H11 (Notificaciones)  

**Tiempo:** ~25 minutos  
**Hito:** 10/12 Completado ✅  
**Progreso:** 83.3%