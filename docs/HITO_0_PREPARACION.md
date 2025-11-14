	# HITO 0: Preparación del Entorno

## Fecha de Completación
2025-11-13

## Objetivo Cumplido
✅ Preparar todos los recursos base necesarios antes de instalar Jenkins, siguiendo mejores prácticas empresariales.

---

## Configuración del Proyecto

### Proyecto GCP - Trabajo
- **ID**: `possible-sun-471215-d3`
- **Región**: `us-central1`
- **Zona**: `us-central1-a`

### Proyecto GCP - Bootstrap (Terraform State)
- **ID**: `my-project-bootstrap-476516`
- **Bucket State**: `gs://my-project-bootstrap-476516-terraform-state`
- **Versionado**: ✅ Habilitado
- **Decisión de Arquitectura**: Se decidió separar el Terraform state en un proyecto bootstrap independiente para:
  - Proteger el state de cambios accidentales en proyecto de trabajo
  - Seguir best practice empresarial de separación de concerns
  - Facilitar gestión centralizada de states para múltiples proyectos

### Service Account
- **Email**: `jenkins-cicd-sa@possible-sun-471215-d3.iam.gserviceaccount.com`
- **Display Name**: Jenkins CI/CD Service Account
- **Método de Autenticación**: **VM Service Account Attachment** (NO JSON keys)
  - Decisión basada en best practices empresariales
  - Sin keys que gestionar manualmente
  - Totalmente auditable
  - Tokens automáticos manejados por GCP
  - Principio de least privilege

### Roles Asignados al Service Account
| Rol | Justificación |
|-----|---------------|
| `roles/artifactregistry.writer` | Push de imágenes Docker a Artifact Registry |
| `roles/run.admin` | Deploy y gestión de Cloud Run services |
| `roles/secretmanager.secretAccessor` | Lectura de secrets durante pipeline |
| `roles/iam.serviceAccountUser` | Actuar como SA en deployments de Cloud Run |
| `roles/compute.instanceAdmin.v1` | Terraform: Crear/gestionar VMs |
| `roles/compute.networkUser` | Terraform: Usar redes VPC |
| `roles/storage.admin` | Acceso al bucket de Terraform state en proyecto bootstrap |

**Total**: 7 roles (principio de least privilege aplicado)

### Repositorio GitHub
- **URL**: https://github.com/alcisternas/jenkins-gcp-cicd-lab
- **Visibilidad**: Private
- **Branch principal**: main
- **Estructura de carpetas**:
```
  jenkins-gcp-cicd-lab/
  ├── terraform/          # Infraestructura como código
  ├── app/               # Aplicación FastAPI
  ├── jenkins/           # Jenkinsfiles y configuración
  └── docs/              # Documentación de cada hito
```

### Artifact Registry
- **Repository**: `apps` (existente, reutilizado)
- **Location**: `us-central1`
- **Format**: Docker
- **Full Path**: `us-central1-docker.pkg.dev/possible-sun-471215-d3/apps`
- **Creado**: 2025-09-08 (pre-existente)
- **Tamaño actual**: 223.757 MB

### Secret Manager
- **Secretos creados**:
  1. `slack-webhook-url` - Para notificaciones Slack (configuración aplazada a Hito 11)
  2. `gmail-app-password` - Para notificaciones Email (configuración aplazada a Hito 11)
  3. `db-password` - Para credenciales de base de datos de la aplicación

- **Replication Policy**: Automatic
- **Permisos**: Service Account tiene rol `secretAccessor` en los 3 secretos

### Notificaciones (Aplazado a Hito 11)
- **Slack**: Configuración pospuesta debido a restricciones en workspace. Se creará workspace nuevo en Hito 11.
- **Email SMTP**: Configuración pospuesta. Se configurará Gmail SMTP en Hito 11.
- **Decisión**: Las notificaciones NO son críticas para Hitos 1-10, se priorizó avanzar con core del laboratorio.

---

## APIs Habilitadas en GCP
```
✅ compute.googleapis.com               - Compute Engine API
✅ run.googleapis.com                   - Cloud Run Admin API  
✅ artifactregistry.googleapis.com      - Artifact Registry API
✅ secretmanager.googleapis.com         - Secret Manager API
✅ cloudresourcemanager.googleapis.com  - Cloud Resource Manager API
✅ iam.googleapis.com                   - Identity and Access Management API
✅ iamcredentials.googleapis.com        - IAM Service Account Credentials API
✅ cloudbuild.googleapis.com            - Cloud Build API
```

---

## Comandos Ejecutados

### Verificación de Pre-requisitos
```powershell
# Verificar gcloud instalado
gcloud --version
# Output: Google Cloud SDK 538.0.0

# Verificar git instalado  
git --version
# Output: git version 2.50.1.windows.1
```

### Configuración de Proyecto
```powershell
# Autenticación
gcloud auth login

# Configurar proyecto por defecto
gcloud config set project possible-sun-471215-d3

# Verificar
gcloud config get-value project
# Output: possible-sun-471215-d3
```

### Habilitación de APIs
```powershell
gcloud services enable compute.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable cloudbuild.googleapis.com

# Verificación
gcloud services list --enabled --filter="name:(compute OR run OR artifactregistry OR secretmanager OR cloudbuild OR iam OR cloudresourcemanager)"
```

### Creación de Service Account
```powershell
# Crear Service Account
gcloud iam service-accounts create jenkins-cicd-sa --display-name="Jenkins CI/CD Service Account" --description="SA for Jenkins VM to interact with GCP services following least privilege principle"

# Verificar creación
gcloud iam service-accounts list --filter="email:jenkins-cicd-sa@"

# Asignar roles (ejecutados uno por uno)
gcloud projects add-iam-policy-binding possible-sun-471215-d3 --member="serviceAccount:jenkins-cicd-sa@possible-sun-471215-d3.iam.gserviceaccount.com" --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding possible-sun-471215-d3 --member="serviceAccount:jenkins-cicd-sa@possible-sun-471215-d3.iam.gserviceaccount.com" --role="roles/run.admin"

gcloud projects add-iam-policy-binding possible-sun-471215-d3 --member="serviceAccount:jenkins-cicd-sa@possible-sun-471215-d3.iam.gserviceaccount.com" --role="roles/secretmanager.secretAccessor"

gcloud projects add-iam-policy-binding possible-sun-471215-d3 --member="serviceAccount:jenkins-cicd-sa@possible-sun-471215-d3.iam.gserviceaccount.com" --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding possible-sun-471215-d3 --member="serviceAccount:jenkins-cicd-sa@possible-sun-471215-d3.iam.gserviceaccount.com" --role="roles/compute.instanceAdmin.v1"

gcloud projects add-iam-policy-binding possible-sun-471215-d3 --member="serviceAccount:jenkins-cicd-sa@possible-sun-471215-d3.iam.gserviceaccount.com" --role="roles/compute.networkUser"

gcloud projects add-iam-policy-binding possible-sun-471215-d3 --member="serviceAccount:jenkins-cicd-sa@possible-sun-471215-d3.iam.gserviceaccount.com" --role="roles/storage.admin"

# Verificar roles asignados
gcloud projects get-iam-policy possible-sun-471215-d3 --flatten="bindings[].members" --filter="bindings.members:jenkins-cicd-sa@possible-sun-471215-d3.iam.gserviceaccount.com" --format="table(bindings.role)"
```

### Repositorio GitHub
```powershell
# Clonar repositorio
cd C:\Users\a.cisternas.guajardo\Source\Repos
git clone https://github.com/alcisternas/jenkins-gcp-cicd-lab.git
cd jenkins-gcp-cicd-lab

# Crear estructura de carpetas
mkdir terraform
mkdir app
mkdir jenkins
mkdir docs

# Crear archivos base
New-Item -Path ".\docs\HITO_0_PREPARACION.md" -ItemType File
New-Item -Path ".\jenkins\Jenkinsfile" -ItemType File
New-Item -Path ".\app\Dockerfile" -ItemType File
New-Item -Path ".\app\requirements.txt" -ItemType File
```

### Artifact Registry
```powershell
# Verificar repository existente (se decidió reutilizar)
gcloud artifacts repositories list --location=us-central1

# Output: Repository 'apps' existe desde 2025-09-08
```

### Terraform State Bucket
```powershell
# Crear bucket en proyecto bootstrap
gsutil mb -p my-project-bootstrap-476516 -c STANDARD -l us-central1 gs://my-project-bootstrap-476516-terraform-state

# Habilitar versionado
gsutil versioning set on gs://my-project-bootstrap-476516-terraform-state

# Verificar
gsutil ls -L gs://my-project-bootstrap-476516-terraform-state

# Dar permisos al Service Account
gsutil iam ch serviceAccount:jenkins-cicd-sa@possible-sun-471215-d3.iam.gserviceaccount.com:roles/storage.objectAdmin gs://my-project-bootstrap-476516-terraform-state
```

### Secret Manager
```powershell
# Crear secretos (con valores placeholder por ahora)
echo "placeholder-slack-webhook" | gcloud secrets create slack-webhook-url --data-file=- --replication-policy="automatic"

echo "placeholder-gmail-password" | gcloud secrets create gmail-app-password --data-file=- --replication-policy="automatic"

echo "changeme-insecure-password" | gcloud secrets create db-password --data-file=- --replication-policy="automatic"

# Dar permisos al SA (ejecutado para cada secret)
gcloud secrets add-iam-policy-binding slack-webhook-url --member="serviceAccount:jenkins-cicd-sa@possible-sun-471215-d3.iam.gserviceaccount.com" --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding gmail-app-password --member="serviceAccount:jenkins-cicd-sa@possible-sun-471215-d3.iam.gserviceaccount.com" --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding db-password --member="serviceAccount:jenkins-cicd-sa@possible-sun-471215-d3.iam.gserviceaccount.com" --role="roles/secretmanager.secretAccessor"

# Verificar
gcloud secrets list
```

---

## Verificación Final

### Comandos de Verificación Ejecutados
```powershell
# 1. Proyecto configurado
gcloud config get-value project
# ✅ Output: possible-sun-471215-d3

# 2. Service Account existe
gcloud iam service-accounts list --filter="email:jenkins-cicd-sa@"
# ✅ Output: jenkins-cicd-sa@possible-sun-471215-d3.iam.gserviceaccount.com

# 3. Roles del SA
gcloud projects get-iam-policy possible-sun-471215-d3 --flatten="bindings[].members" --filter="bindings.members:jenkins-cicd-sa@possible-sun-471215-d3.iam.gserviceaccount.com" --format="table(bindings.role)"
# ✅ Output: 7 roles listados

# 4. APIs habilitadas
gcloud services list --enabled --filter="name:(compute OR run OR artifactregistry OR secretmanager)"
# ✅ Output: 4 APIs principales habilitadas

# 5. Artifact Registry
gcloud artifacts repositories list --location=us-central1
# ✅ Output: Repository 'apps' disponible

# 6. Secrets
gcloud secrets list
# ✅ Output: 3 secrets creados

# 7. Bucket Terraform State
gsutil ls
# ✅ Output: gs://my-project-bootstrap-476516-terraform-state/
```

---

## Problemas Encontrados y Soluciones

### Problema 1: Configuración de Slack App
**Descripción**: Al intentar crear Slack App en workspace "DevOps", se recibía error "Something went wrong" persistente, incluso siendo owner del workspace.

**Intentos fallidos**:
1. Crear app desde api.slack.com/apps
2. Acceder a admin/roles (página no existe en nueva versión de Slack)
3. Crear app desde diferentes navegadores
4. Usar app desktop de Slack

**Causa raíz identificada**: 
- Slack cambió su estructura de administración
- Posibles restricciones no visibles en workspace Free/Trial
- Información de documentación desactualizada sobre rutas de admin

**Solución aplicada**: 
- **Decisión de aplazar configuración a Hito 11**
- Las notificaciones NO son críticas para Hitos 1-10 (instalación Jenkins, Terraform, Docker, CI/CD)
- En Hito 11 se creará workspace Slack nuevo donde se tendrá control total
- Esto es approach común en empresas: workspaces separados para diferentes ambientes

**Aprendizajes**:
- Best practice: Separar workspaces de Slack por ambiente (dev/staging/prod)
- No bloquear progreso de laboratorio por componentes no críticos
- Documentar todos los intentos fallidos para evitar repetirlos

### Problema 2: Terraform State en Mismo Proyecto
**Descripción**: Inicialmente se planificó crear bucket de Terraform state en el mismo proyecto de trabajo (`possible-sun-471215-d3`).

**Solución aplicada**:
- **Decisión de usar proyecto bootstrap separado** (`my-project-bootstrap-476516`)
- Esto es **best practice empresarial** por:
  - State protegido de cambios accidentales en proyecto de trabajo
  - Separación de concerns (bootstrap vs workload)
  - Facilita gestión de múltiples proyectos desde state centralizado
  - State persiste aunque se destruya infraestructura de trabajo

**Ajustes necesarios**:
- Service Account necesita permisos cross-project sobre bucket
- Backend de Terraform debe referenciar proyecto bootstrap
- Comandos gsutil deben especificar `-p` para proyecto correcto

**Comando de permisos cross-project**:
```powershell
gsutil iam ch serviceAccount:jenkins-cicd-sa@possible-sun-471215-d3.iam.gserviceaccount.com:roles/storage.objectAdmin gs://my-project-bootstrap-476516-terraform-state
```

### Problema 3: Sintaxis de Comandos para PowerShell
**Descripción**: Comandos inicialmente proporcionados usaban sintaxis bash con `\` para continuación de línea.

**Solución**: 
- PowerShell usa `` ` `` (backtick) para continuación de línea
- Sin embargo, es más limpio escribir comandos en una sola línea
- Todos los comandos futuros serán adaptados a sintaxis PowerShell

**Ejemplo**:
```powershell
# ❌ Bash style (no funciona en PowerShell)
gcloud iam service-accounts create jenkins-cicd-sa \
  --display-name="Jenkins CI/CD"

# ✅ PowerShell style (una línea)
gcloud iam service-accounts create jenkins-cicd-sa --display-name="Jenkins CI/CD" --description="SA for Jenkins"
```

---

## Notas Importantes de Arquitectura

### 1. Autenticación: VM Service Account vs JSON Keys
**Decisión**: Usar VM Service Account Attachment en lugar de JSON keys.

**Justificación**:
- ✅ No hay credentials estáticas que gestionar
- ✅ Rotation automática de tokens por GCP
- ✅ Completamente auditable en Cloud Audit Logs
- ✅ Imposible filtración de keys (no existen keys)
- ✅ Es el método usado en producción real

**Implementación**:
- VM de Jenkins se creará con `--service-account=jenkins-cicd-sa@...`
- Jenkins usará Application Default Credentials (ADC)
- Plugins de GCP configurados para usar ADC automáticamente

### 2. Terraform State en Proyecto Bootstrap
**Decisión**: Bucket de state en proyecto separado de infraestructura de trabajo.

**Ventajas**:
- State persiste aunque se destruya proyecto de trabajo
- Protección contra eliminación accidental
- Múltiples proyectos pueden compartir mismo bucket con prefixes diferentes
- Separación de concerns entre bootstrap y workload

**Configuración de backend**:
```hcl
terraform {
  backend "gcs" {
    bucket  = "my-project-bootstrap-476516-terraform-state"
    prefix  = "jenkins-lab"
  }
}
```

### 3. Least Privilege en Service Account
**Principio**: Solo permisos estrictamente necesarios.

**Roles asignados vs evitados**:
- ✅ `compute.instanceAdmin.v1` - Necesario para Terraform crear VMs
- ❌ `compute.admin` - Demasiado amplio, NO asignado
- ✅ `run.admin` - Necesario para deploy en Cloud Run
- ❌ `editor` o `owner` - Nunca usar en SA de producción

---

## Recursos Creados - Resumen

| Recurso | Nombre/ID | Proyecto | Estado |
|---------|-----------|----------|--------|
| Proyecto GCP (trabajo) | possible-sun-471215-d3 | - | ✅ Activo |
| Proyecto GCP (bootstrap) | my-project-bootstrap-476516 | - | ✅ Activo |
| Service Account | jenkins-cicd-sa | possible-sun-471215-d3 | ✅ Creado |
| Artifact Registry | apps | possible-sun-471215-d3 | ✅ Existente |
| Terraform State Bucket | my-project-bootstrap-476516-terraform-state | my-project-bootstrap-476516 | ✅ Creado |
| Secret: slack-webhook-url | - | possible-sun-471215-d3 | ✅ Creado (placeholder) |
| Secret: gmail-app-password | - | possible-sun-471215-d3 | ✅ Creado (placeholder) |
| Secret: db-password | - | possible-sun-471215-d3 | ✅ Creado (placeholder) |
| Repositorio GitHub | jenkins-gcp-cicd-lab | - | ✅ Creado |
| APIs (8 total) | compute, run, artifact, etc. | possible-sun-471215-d3 | ✅ Habilitadas |

---

## Siguiente Hito

**Hito 1**: Instalar Jenkins en GCE con Podman

**Pre-requisitos cumplidos**:
- ✅ Service Account listo con permisos
- ✅ Proyecto GCP configurado
- ✅ Artifact Registry disponible
- ✅ Repositorio GitHub listo
- ✅ Terraform state bucket configurado

**Próximos pasos**:
1. Crear instancia GCE con Service Account attached
2. Instalar Podman en la VM
3. Desplegar Jenkins usando Podman
4. Configurar acceso y seguridad inicial

---

## Tiempo Invertido

- **Configuración GCP**: ~30 minutos
- **Troubleshooting Slack**: ~45 minutos
- **Repositorio y estructura**: ~15 minutos
- **Documentación**: ~30 minutos
- **Total Hito 0**: ~2 horas

---

## Checklist Final ✅

- [x] Proyecto GCP configurado
- [x] APIs habilitadas (8 APIs)
- [x] Service Account creado con 7 roles mínimos
- [x] Artifact Registry repository disponible
- [x] Terraform state bucket en proyecto bootstrap
- [x] Permisos cross-project configurados
- [x] Secretos creados en Secret Manager
- [x] Repositorio GitHub creado y clonado
- [x] Estructura de carpetas creada
- [⏭️] Slack webhook (aplazado a Hito 11)
- [⏭️] Gmail SMTP (aplazado a Hito 11)
- [x] Documentación completa generada

**Estado**: ✅ HITO 0 COMPLETADO

**Listo para**: Proceder con Hito 1 - Instalar Jenkins en GCE con Podman