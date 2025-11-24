# Hito 8: Integrar Jenkins con Artifact Registry

**Fecha:** 2025-11-24  
**Estado:** ✅ Completado

---

## Objetivo

Configurar Jenkins para construir imágenes Docker y subirlas automáticamente a Artifact Registry de GCP usando Cloud Build.

---

## Implementación

### 1. Aplicación FastAPI de Prueba

**Archivo:** `app/main.py`
```python
from fastapi import FastAPI
import os

app = FastAPI(title="Jenkins CI/CD Lab - H8")

@app.get("/")
def read_root():
    return {
        "message": "Hello from Jenkins CI/CD Lab!",
        "hito": "H8 - Artifact Registry Integration",
        "version": os.getenv("APP_VERSION", "1.0.0")
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}
```

**Propósito:** Aplicación simple para validar el flujo de build y push.

---

### 2. Dockerfile

**Archivo:** `app/Dockerfile`
```dockerfile
FROM python:3.11-slim
WORKDIR /app
RUN pip install --no-cache-dir fastapi==0.104.1 uvicorn==0.24.0
COPY main.py .
EXPOSE 8080
ENV APP_VERSION=1.0.0
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
```

**Base:** Python 3.11 slim (~120 MB)  
**Dependencias:** FastAPI + Uvicorn  
**Puerto:** 8080

---

### 3. Cloud Build Configuration

**Archivo:** `app/cloudbuild.yaml`
```yaml
steps:
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'build'
      - '-t'
      - 'us-central1-docker.pkg.dev/$PROJECT_ID/apps/fastapi-app:$BUILD_ID'
      - '-t'
      - 'us-central1-docker.pkg.dev/$PROJECT_ID/apps/fastapi-app:latest'
      - '-f'
      - 'app/Dockerfile'
      - 'app'

  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'us-central1-docker.pkg.dev/$PROJECT_ID/apps/fastapi-app:$BUILD_ID']

  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'us-central1-docker.pkg.dev/$PROJECT_ID/apps/fastapi-app:latest']

images:
  - 'us-central1-docker.pkg.dev/$PROJECT_ID/apps/fastapi-app:$BUILD_ID'
  - 'us-central1-docker.pkg.dev/$PROJECT_ID/apps/fastapi-app:latest'
```

**Características:**
- Construye con build ID único
- Tag `latest` para última versión
- Push automático a Artifact Registry

---

### 4. Pipeline Jenkins

**Job:** `docker-registry-integration`  
**Tipo:** Pipeline

**Stages:**

#### Stage 1: Checkout
```groovy
git branch: 'main',
    credentialsId: 'github-token',
    url: 'https://github.com/alcisternas/jenkins-gcp-cicd-lab.git'
```

#### Stage 2: Verify gcloud
```groovy
sh 'gcloud version'
sh 'gcloud auth list'
```

#### Stage 3: Trigger Cloud Build
```groovy
sh '''
    gcloud builds submit \
        --config app/cloudbuild.yaml \
        --project ${GCP_PROJECT} \
        .
'''
```

#### Stage 4: Verify in Registry
```groovy
sh '''
    gcloud artifacts docker images list \
        ${REGISTRY}/${GCP_PROJECT}/${REPOSITORY} \
        --filter="${IMAGE_NAME}"
'''
```

#### Stage 5: Image Info
Muestra URL de imagen y comando para pull.

---

## Configuración de Permisos

### Service Account Roles

**Service Account:** `jenkins-cicd-sa@possible-sun-471215-d3.iam.gserviceaccount.com`

**Rol agregado:**
```bash
gcloud projects add-iam-policy-binding possible-sun-471215-d3 \
  --member="serviceAccount:jenkins-cicd-sa@..." \
  --role="roles/cloudbuild.builds.editor"
```

**Permisos incluidos:**
- `cloudbuild.builds.create`
- `cloudbuild.builds.get`
- `cloudbuild.builds.list`
- `cloudbuild.builds.update`

**Roles totales del SA (10):**
1. Artifact Registry Reader
2. Artifact Registry Writer
3. Cloud Run Developer
4. Compute Instance Admin
5. **Cloud Build Editor** ← Nuevo
6. IAM Service Account User
7. Secret Manager Accessor
8. Service Account User
9. Storage Object Admin
10. Storage Object Viewer

---

## Validación

### Test 1: Build Manual
**Trigger:** Manual "Construir Ahora"  
**Build:** #3  
**Resultado:** ✅ SUCCESS

**Output:**
```
Created [https://cloudbuild.googleapis.com/v1/projects/.../builds/f5c478fa...]
Duration: 43 seconds
Status: SUCCESS

Images:
- us-central1-docker.pkg.dev/.../fastapi-app:f5c478fa-dd6a-4810-b801-6a85e99bd4bd
- us-central1-docker.pkg.dev/.../fastapi-app:latest
```

**Artifact Registry:**
- ✅ 2 imágenes creadas
- ✅ Tag `latest` apuntando a build más reciente
- ✅ Tag con build ID único
- Tamaño: ~50-60 MB

---

## Decisiones de Arquitectura

### ¿Por Qué Cloud Build en Lugar de Podman Local?

**Problema inicial:** Podman no disponible dentro del container Jenkins (container-in-container)

**Opciones evaluadas:**
1. ❌ Montar socket Podman del host (complejo, requiere permisos especiales)
2. ❌ Instalar Podman en imagen Jenkins (bloat, problemas de seguridad)
3. ✅ **Usar Cloud Build** (enterprise-grade, ya configurado)

**Ventajas de Cloud Build:**
- ✅ Separación de responsabilidades
- ✅ Escalabilidad (builds paralelos)
- ✅ Logs centralizados en GCP
- ✅ Caché de layers optimizado
- ✅ No requiere recursos en Jenkins VM
- ✅ Best practice para GCP

---

## Lecciones Aprendidas

### 1. Container-in-Container es Complejo
**Problema:** Ejecutar Podman dentro de container Jenkins requiere privilegios especiales.

**Solución:** Delegar construcción a servicio externo (Cloud Build).

### 2. Service Account Roles Son Granulares
**Error inicial:**
```
PERMISSION_DENIED: The caller does not have permission
```

**Solución:** Agregar rol `cloudbuild.builds.editor`.

**Aprendizaje:** Siempre verificar permisos necesarios antes de ejecutar comandos gcloud.

### 3. Cloud Build Usa Variables de Entorno
**Variables disponibles:**
- `$PROJECT_ID` - ID del proyecto GCP
- `$BUILD_ID` - ID único del build
- `$COMMIT_SHA` - SHA del commit Git
- `$BRANCH_NAME` - Nombre del branch

**Uso:** Tagging automático con build IDs únicos.

### 4. Artifact Registry Soporta Múltiples Tags
**Best practice:**
- Tag `latest` para última versión
- Tag con build ID para trazabilidad
- Tag con semantic version (futuro)

---

## Conclusión

✅ Jenkins integrado con Artifact Registry  
✅ Cloud Build como build engine  
✅ Imágenes Docker subiéndose automáticamente  
✅ Service Account con permisos correctos  
✅ Pipeline enterprise-grade funcionando  

**Tiempo:** ~30 minutos  
**Hito:** 8/12 Completado ✅  
**Progreso:** 66.7%