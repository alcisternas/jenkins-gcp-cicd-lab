# Hito 9: Deploy en Cloud Run

**Fecha:** 2025-11-24  
**Estado:** ✅ Completado

---

## Objetivo

Desplegar la aplicación FastAPI desde Artifact Registry a Cloud Run usando Jenkins, obteniendo una URL pública accesible.

---

## Implementación

### Pipeline de Deploy

**Job:** `deploy-to-cloud-run`  
**Tipo:** Pipeline parametrizado

**Parámetros:**
```groovy
parameters {
    choice(
        name: 'IMAGE_TAG',
        choices: ['latest', 'specific'],
        description: 'Which image tag to deploy'
    )
    string(
        name: 'SPECIFIC_TAG',
        defaultValue: '',
        description: 'Specific build ID (only if IMAGE_TAG=specific)'
    )
}
```

**Permite desplegar:**
- Tag `latest` (default)
- Build específico por ID

---

## Stages del Pipeline

### Stage 0: Determine Image
**Propósito:** Determinar qué imagen desplegar según parámetros.
```groovy
script {
    if (params.IMAGE_TAG == 'latest') {
        env.DEPLOY_IMAGE = "${REGISTRY}/${GCP_PROJECT}/${REPOSITORY}/${IMAGE_NAME}:latest"
    } else {
        env.DEPLOY_IMAGE = "${REGISTRY}/${GCP_PROJECT}/${REPOSITORY}/${IMAGE_NAME}:${params.SPECIFIC_TAG}"
    }
}
```

### Stage 1: Verify Image Exists
**Propósito:** Validar que la imagen existe en Artifact Registry antes de desplegar.
```bash
gcloud artifacts docker images describe ${DEPLOY_IMAGE}
```

**Output:**
```
image_summary:
  digest: sha256:4c671422710b00cf242098330ace9ceaa25ce4e3c68e215776faf7057046a5b9
  repository: apps
  slsa_build_level: 3
```

### Stage 2: Deploy to Cloud Run
**Propósito:** Desplegar el servicio a Cloud Run.
```bash
gcloud run deploy fastapi-app \
    --image ${DEPLOY_IMAGE} \
    --platform managed \
    --region us-central1 \
    --allow-unauthenticated \
    --port 8080 \
    --memory 512Mi \
    --cpu 1 \
    --min-instances 0 \
    --max-instances 10 \
    --set-env-vars "APP_VERSION=1.0.0,ENVIRONMENT=production"
```

**Configuración:**
- **Platform:** Managed (serverless)
- **Region:** us-central1
- **Auth:** Unauthenticated (público)
- **Port:** 8080
- **Resources:** 512Mi RAM, 1 vCPU
- **Scaling:** 0 min, 10 max (scale to zero)
- **Env vars:** APP_VERSION, ENVIRONMENT

**Output:**
```
Service [fastapi-app] revision [fastapi-app-00001-hcv] has been deployed
Service URL: https://fastapi-app-dv4pl47mda-uc.a.run.app
```

### Stage 3: Get Service URL
**Propósito:** Obtener URL pública del servicio.
```bash
gcloud run services describe fastapi-app \
    --region us-central1 \
    --format 'value(status.url)'
```

**URL obtenida:** https://fastapi-app-dv4pl47mda-uc.a.run.app

### Stage 4: Health Check
**Propósito:** Validar que el servicio responde correctamente.

**Tests realizados:**

**Endpoint raíz (/):**
```bash
curl https://fastapi-app-dv4pl47mda-uc.a.run.app/
```
Response:
```json
{
  "message": "Hello from Jenkins CI/CD Lab!",
  "hito": "H8 - Artifact Registry Integration",
  "version": "1.0.0",
  "environment": "production"
}
```

**Endpoint de salud (/health):**
```bash
curl https://fastapi-app-dv4pl47mda-uc.a.run.app/health
```
Response:
```json
{"status": "healthy"}
```

**Endpoint de información (/info):**
```bash
curl https://fastapi-app-dv4pl47mda-uc.a.run.app/info
```
Response:
```json
{
  "app": "jenkins-cicd-lab",
  "hito": "H8",
  "description": "FastAPI app integrated with Jenkins and Artifact Registry"
}
```

### Stage 5: Service Info
**Propósito:** Mostrar información detallada del servicio.

**Output:**
```
NAME         URL                                          REVISION                STATUS
fastapi-app  https://fastapi-app-dv4pl47mda-uc.a.run.app  fastapi-app-00001-hcv  True
```

---

## Configuración de Permisos

### Service Account Roles Adicionales

**Rol agregado:**
```bash
gcloud projects add-iam-policy-binding possible-sun-471215-d3 \
  --member="serviceAccount:jenkins-cicd-sa@..." \
  --role="roles/containeranalysis.ServiceAgent"
```

**Permisos incluidos:**
- `containeranalysis.occurrences.list` - Describir imágenes
- `containeranalysis.occurrences.get` - Obtener detalles de imágenes
- Container vulnerability scanning access

**Roles totales del SA (11):**
1. Artifact Registry Reader
2. Artifact Registry Writer
3. Cloud Build Editor
4. Cloud Run Developer
5. Compute Instance Admin
6. **Container Analysis Service Agent** ← Nuevo
7. IAM Service Account User
8. Secret Manager Accessor
9. Service Account User
10. Storage Object Admin
11. Storage Object Viewer

---

## Validación

### Test 1: Deploy con Latest Tag
**Trigger:** Manual  
**Build:** #2  
**Parámetros:** IMAGE_TAG=latest  
**Resultado:** ✅ SUCCESS

**Timeline:**
- 00:00 - Determine Image (latest)
- 00:02 - Verify Image (SLSA level 3)
- 00:05 - Deploy to Cloud Run (creating revision)
- 02:30 - Deployment complete
- 02:32 - Get Service URL
- 02:35 - Health checks passed (3/3)
- 02:40 - Service info displayed

**Total duration:** ~3 minutos

### Endpoints Validados

✅ **GET /** - Responde 200 OK  
✅ **GET /health** - Responde 200 OK  
✅ **GET /info** - Responde 200 OK  
✅ **Service URL** - Accesible públicamente  
✅ **HTTPS** - Certificado automático

---

## Características de Cloud Run

### Serverless
- Scale to zero cuando no hay tráfico (sin costo)
- Scale automático hasta 10 instancias
- Pay per use (solo por requests)

### Managed Platform
- SSL/TLS automático
- Load balancing integrado
- Health checks automáticos
- Rolling updates
- Traffic splitting

### Configuración Aplicada
```yaml
Service: fastapi-app
Region: us-central1
Min instances: 0 (scale to zero)
Max instances: 10
Memory: 512Mi
CPU: 1 vCPU
Port: 8080
Concurrency: 80 (default)
Timeout: 300s (default)
Authentication: Allow unauthenticated
```

---

## Lecciones Aprendidas

### 1. Container Analysis Permissions
**Error inicial:**
```
Permission 'containeranalysis.occurrences.list' denied
```

**Solución:** Agregar rol `roles/containeranalysis.ServiceAgent` al Service Account.

**Aprendizaje:** Describir imágenes Docker requiere permisos específicos de Container Analysis, no solo Artifact Registry Reader.

### 2. Cloud Run Deployment Time
**Observación:** Primera deployment toma ~2-3 minutos.

**Razón:**
- Descarga de imagen
- Creación de revision
- Cold start del container
- Health checks

**Deployments subsecuentes:** ~30-60 segundos

### 3. Allow Unauthenticated
**Flag:** `--allow-unauthenticated`

**Efecto:** Servicio accesible públicamente sin autenticación.

**Alternativa:** Usar IAM para acceso restringido:
```bash
--no-allow-unauthenticated
gcloud run services add-iam-policy-binding ...
```

### 4. Scale to Zero
**Configuración:** `--min-instances 0`

**Ventajas:**
- Sin costos en idle
- Ideal para desarrollo/testing

**Desventaja:**
- Cold start (~2-3s) en primer request después de idle

**Producción:** Considerar `--min-instances 1` para mejor latencia.

### 5. Environment Variables
**Passing env vars:**
```bash
--set-env-vars "KEY1=value1,KEY2=value2"
```

**Acceso en app:**
```python
os.getenv("KEY1", "default")
```

---

## URLs y Acceso

**Service URL:** https://fastapi-app-dv4pl47mda-uc.a.run.app

**Endpoints disponibles:**
- `/` - Mensaje de bienvenida
- `/health` - Health check
- `/info` - Información de la app
- `/docs` - Swagger UI (FastAPI automático)
- `/redoc` - ReDoc (FastAPI automático)

**GCP Console:**
https://console.cloud.google.com/run/detail/us-central1/fastapi-app/metrics

---

## Conclusión

✅ Aplicación desplegada en Cloud Run  
✅ URL pública accesible  
✅ Health checks pasando  
✅ Pipeline parametrizado funcional  
✅ Scale to zero configurado  
✅ SSL/TLS automático  

**Tiempo:** ~30 minutos  
**Hito:** 9/12 Completado ✅  
**Progreso:** 75%