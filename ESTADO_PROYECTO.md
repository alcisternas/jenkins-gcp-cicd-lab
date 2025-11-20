# Estado del Proyecto: Jenkins CI/CD Lab en GCP

## Información General

**Nombre del Proyecto:** jenkins-gcp-cicd-lab  
**Fecha de Última Actualización:** 2025-11-18  
**Estado General:** 5/12 Hitos Completados (41.7%)
**Próximo Hito:** H6  

---

## Identificadores GCP

### Proyectos
- **Proyecto de Trabajo:** `possible-sun-471215-d3`
- **Proyecto Bootstrap:** `my-project-bootstrap-476516`
- **Región Principal:** `us-central1`
- **Zona Principal:** `us-central1-a`

### Service Account Principal
```
Email: jenkins-cicd-sa@possible-sun-471215-d3.iam.gserviceaccount.com
```

**Roles Asignados (8):**
1. `roles/artifactregistry.reader` - Leer imágenes custom
2. `roles/artifactregistry.writer` - Subir imágenes
3. `roles/compute.instanceAdmin.v1` - Administrar VMs
4. `roles/compute.networkUser` - Usar redes
5. `roles/iam.serviceAccountUser` - Usar service accounts
6. `roles/run.admin` - Administrar Cloud Run
7. `roles/secretmanager.secretAccessor` - Leer secretos
8. `roles/storage.admin` - Administrar Cloud Storage

### Recursos Principales

**Compute Engine:**
```
VM Name: jenkins-lab-vm
Machine Type: e2-medium (2 vCPU, 4 GB RAM)
IP Externa: 34.172.178.70 (ephemeral)
IP Interna: 10.10.0.2
OS: Ubuntu 22.04 LTS
```

**Networking:**
```
VPC: jenkins-lab-vpc
Subnet: jenkins-subnet (10.10.0.0/24)
Firewall: jenkins-allow-http (puerto 8080)
```

**Artifact Registry:**
```
Repository: apps
Location: us-central1
Format: Docker
Imagen Principal: jenkins-custom:latest (v1.0.0)
Size: ~390 MB
```

**Secret Manager (3 secretos):**
```
slack-webhook-url
gmail-app-password
db-password
```

---

## Estructura del Proyecto
```
jenkins-gcp-cicd-lab/
├── jenkins/                          # Custom Jenkins Docker Image
│   ├── Dockerfile                    # Definición imagen custom
│   ├── plugins.txt                   # 23 plugins pre-instalados
│   ├── jenkins-casc.yaml            # Configuration as Code
│   ├── cloudbuild.yaml              # Automatización Cloud Build
│   ├── .dockerignore                # Exclusiones build
│   ├── Jenkinsfile                  # Pipeline (para H7, vacío)
│   └── README.md                    # Doc imagen custom
│
├── terraform/
│   ├── network/                     # Módulo VPC (de Hito 0)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── jenkins-vm/                  # Infraestructura Jenkins
│       ├── main.tf                  # Definición VM + IAM
│       ├── variables.tf             # Variables
│       ├── outputs.tf               # IPs, comandos SSH
│       └── startup-script.sh        # Script inicialización VM
│
├── app/                             # Aplicación FastAPI (para H9)
│   └── [vacío - pendiente]
│
├── docs/                            # Documentación
│   ├── HITO_2_JENKINS_CONFIGURATION.md  # Doc completa H2
│   └── [otros hitos pendientes]
│
├── .gitignore                       # Exclusiones Git
├── .gcloudignore                    # Exclusiones Cloud Build
├── README.md                        # Documentación principal
├── ESTADO_PROYECTO.md              # Este archivo
└── listado_contenido_proyecto.txt  # Inventario archivos
```

---

## Configuración de Jenkins

### Acceso
```
URL: http://34.172.178.70:8080
Usuario: jenks
Password: admin123
```

### Arquitectura
- **Contenedor:** Podman (rootless)
- **Imagen Base:** jenkins/jenkins:lts-jdk17
- **Imagen Custom:** us-central1-docker.pkg.dev/possible-sun-471215-d3/apps/jenkins-custom:latest
- **Plugins:** 23 pre-instalados (Git, Docker, Terraform, JCasC, etc.)
- **Configuración:** Configuration as Code (JCasC)
- **Setup Wizard:** Deshabilitado

### Plugins Instalados (23)
```
git, workflow-aggregator, pipeline-stage-view, credentials-binding,
ssh-slaves, google-oauth-plugin, google-storage-plugin, docker-workflow,
docker-plugin, terraform, configuration-as-code, slack, email-ext,
mailer, matrix-auth, authorize-project, blueocean, dark-theme,
ws-cleanup, timestamper, build-timeout, credentials, plain-credentials
```

### Tools Configurados
- **Git:** Default (git)
- **Terraform:** terraform (1.9.11-linux-amd64)
- **Docker:** docker (latest)

---

## Estado de las 12 Metas

### ✅ Completadas (2/12)

#### **Hito 1: Instalar Jenkins en GCE with Podman**
- ✅ VM creada con Terraform
- ✅ Podman rootless instalado
- ✅ Jenkins corriendo en contenedor
- ✅ Systemd service configurado
- **Documentación:** Incluida en HITO_2_JENKINS_CONFIGURATION.md

#### **Hito 2: Configurar Jenkins Basic Mode**
- ✅ Custom Docker Image (Dockerfile + build)
- ✅ Configuration as Code (JCasC)
- ✅ 23 plugins pre-instalados
- ✅ Tools configurados (Git, Docker, Terraform)
- ✅ Cloud Build automatizado
- ✅ Usuario admin configurado
- ✅ Setup wizard deshabilitado
- ✅ Reproducible con terraform destroy/apply
- **Documentación:** docs/HITO_2_JENKINS_CONFIGURATION.md (completa)

#### **Hito 3: Conectar con Service Account**
- ✅ gcloud CLI integrado en imagen custom (v1.1.0)
- ✅ Configuración automática via startup script
- ✅ Application Default Credentials funcionando
- ✅ 9 roles validados (agregado secretmanager.viewer)
- ✅ Testing manual y automatizado exitoso
- ✅ 100% reproducible con destroy/apply
- **Documentación:** docs/HITO_3_SERVICE_ACCOUNT.md

#### **Hito 4: Hacer comandos básicos de Git**
- ✅ `git commit`
- ✅ `git push`
- ✅ `git revert`
- ✅ `git diff`
- ✅ `git log`
- ✅ `git status`
- ✅ `git pull` (demostrado en H4)
- ✅ Resolver conflictos (demo)
- ✅ Documentar en docs/HITO_4_GIT_COMMANDS.md

**Tiempo Estimado:** 15 minutos

#### **Hito 5: Integrar Git con Jenkins**
- ✅ GitHub Personal Access Token configurado
- ✅ Webhook automático funcionando
- ✅ SCM Polling como backup (cada 5 min)
- ✅ Pipeline desde Jenkinsfile versionado
- ✅ Builds automáticos en cada push
- **Documentación:** docs/HITO_5_GIT_JENKINS_INTEGRATION.md

---

### ❌ Pendientes (7/12)

#### **Hito 6: Integrar Jenkins con Terraform** ← PRÓXIMO

---

### ❌ Pendientes (8/12)

---

#### **Hito 6: Integrar Jenkins with Terraform**
**Tareas:**
- [ ] Validar Terraform tool en Jenkins (ya configurado)
- [ ] Configurar credenciales GCP para Terraform en Jenkins
- [ ] Crear primer pipeline que ejecute Terraform
- [ ] Documentar en docs/HITO_6_JENKINS_TERRAFORM.md

**Tiempo Estimado:** 30 minutos

---

#### **Hito 7: Crear Jenkinsfile con stages Terraform**
**Tareas:**
- [ ] Crear `jenkins/Jenkinsfile` funcional
- [ ] Stage: terraform validate
- [ ] Stage: terraform plan
- [ ] Stage: terraform apply
- [ ] Stage: terraform destroy
- [ ] Pipeline ejecutándose correctamente
- [ ] Documentar en docs/HITO_7_JENKINSFILE_TERRAFORM.md

**Tiempo Estimado:** 45 minutos

---

#### **Hito 8: Integrar Registry Container with Jenkins**
**Tareas:**
- [ ] Configurar credenciales de Artifact Registry en Jenkins
- [ ] Testear push desde Jenkins a Artifact Registry
- [ ] Crear pipeline que haga build y push de imagen
- [ ] Documentar en docs/HITO_8_REGISTRY_JENKINS.md

**Tiempo Estimado:** 30 minutos

---

#### **Hito 9: Añadir stages Docker (build, push, deploy Cloud Run)**
**Tareas:**
- [ ] Crear Dockerfile de aplicación en `app/`
- [ ] Pipeline stage: Docker build
- [ ] Pipeline stage: Docker push to Artifact Registry
- [ ] Pipeline stage: Deploy to Cloud Run
- [ ] Aplicación funcionando en Cloud Run
- [ ] Documentar en docs/HITO_9_DOCKER_CLOUDRUN.md

**Tiempo Estimado:** 60 minutos

---

#### **Hito 10: Inyectar secretos desde Secret Manager**
**Tareas:**
- [ ] Configurar Secret Manager plugin en Jenkins
- [ ] Leer secretos en pipeline desde Secret Manager
- [ ] Usar secretos en deploy (variables de entorno)
- [ ] Documentar en docs/HITO_10_SECRET_MANAGER.md

**Secretos ya creados:**
- ✅ `slack-webhook-url`
- ✅ `gmail-app-password`
- ✅ `db-password`

**Tiempo Estimado:** 30 minutos

---

#### **Hito 11: Configurar notificaciones (Slack/Email) y control de acceso**
**Tareas:**
- [ ] Configurar Slack workspace y webhook
- [ ] Configurar plugin Slack en Jenkins
- [ ] Configurar SMTP para email (Gmail)
- [ ] Pipeline con notificaciones exitosas/fallidas
- [ ] Configurar control de acceso adicional (roles)
- [ ] Documentar en docs/HITO_11_NOTIFICACIONES_ACCESO.md

**Tiempo Estimado:** 45 minutos

---

#### **Hito 12: Revisar logs en Jenkins**
**Tareas:**
- [ ] Demostrar cómo ver logs de builds
- [ ] Logs de pipeline stages individuales
- [ ] Logs del sistema Jenkins
- [ ] Logs de Podman container
- [ ] Documentar en docs/HITO_12_LOGS.md

**Tiempo Estimado:** 15 minutos

---

## Tiempo Restante Estimado
```
H5:  30 min
H6:  30 min
H7:  45 min
H8:  30 min
H9:  60 min
H10: 30 min
H11: 45 min
H12: 15 min
─────────────
Total: 4.75 horas
```

---

## Comandos Clave

### Terraform
```powershell
# Deploy infraestructura
cd terraform
terraform init
terraform plan
terraform apply

# Destruir infraestructura
terraform destroy

# Ver outputs
terraform output
```

### Cloud Build
```powershell
# Build y push imagen custom Jenkins
cd jenkins-gcp-cicd-lab
gcloud builds submit --config jenkins/cloudbuild.yaml .

# Ver builds
gcloud builds list --limit=5
```

### Podman en la VM
```bash
# SSH a la VM
gcloud compute ssh jenkins-lab-vm --project=possible-sun-471215-d3 --zone=us-central1-a

# Como jenkins user
sudo su - jenkins

# Ver contenedores
podman ps

# Ver logs Jenkins
podman logs jenkins

# Ver servicio systemd
XDG_RUNTIME_DIR=/run/user/1001 systemctl --user status jenkins.service
```

### Git
```powershell
# Estado y log
git status
git log --oneline -10

# Commits
git add .
git commit -m "mensaje"
git push origin main

# Historial
git diff HEAD~1 HEAD
git revert <commit-hash>
```

---

## Problemas Conocidos y Soluciones

### 1. Windows CRLF vs Unix LF
**Problema:** Scripts bash fallan con `^M: bad interpreter`  
**Solución:** Convertir a LF en VS Code o con PowerShell
```powershell
(Get-Content file.sh -Raw) -replace "`r`n","`n" | Set-Content file.sh -NoNewline
```

### 2. Artifact Registry 403 Forbidden
**Problema:** Podman no puede pull imagen  
**Solución:** 
```bash
# Usar token de acceso
TOKEN=$(gcloud auth print-access-token)
podman pull IMAGE --creds oauth2accesstoken:${TOKEN}
```

### 3. Startup Script No Se Re-ejecuta
**Problema:** `terraform apply` no vuelve a ejecutar startup scripts  
**Solución:** Siempre hacer `terraform destroy` + `terraform apply`

### 4. Plugin No Encontrado
**Problema:** `workspace-cleanup:latest` → 404  
**Solución:** Nombre correcto es `ws-cleanup:latest`

---

## Entorno de Desarrollo

**Sistema Operativo:** Windows 11  
**Terminal:** PowerShell  
**Editor:** Visual Studio Code 2022  
**Control de Versiones:** Git  
**Repositorio:** GitHub (alcisternas/jenkins-gcp-cicd-lab)

**Herramientas Instaladas:**
- gcloud CLI
- Terraform
- Podman (configurado como `docker` alias)
- Git

---

## Próximos Pasos Inmediatos

1. **Commit de este documento:**
```powershell
   git add ESTADO_PROYECTO.md
   git commit -m "docs: Add project state documentation with all 12 milestones"
   git push origin main
```

2. **Iniciar Hito 3:**
   - Configurar credenciales GCP en Jenkins
   - Testear acceso a recursos GCP
   - Validar roles del Service Account

3. **Completar Hito 4:**
   - Demostrar `git pull`
   - Resolver conflictos (opcional)

4. **Continuar secuencialmente** con Hitos 5-12

---

## Notas Importantes

- ✅ Infraestructura es **completamente reproducible** con Terraform
- ✅ Todos los cambios están en **control de versiones** (Git)
- ✅ Documentación completa en carpeta `docs/`
- ✅ Método **enterprise-grade** con IaC, JCasC, Cloud Build
- ✅ Security best practices: rootless Podman, SA con roles mínimos
- ⚠️ IP externa es **ephemeral** - cambia en cada deploy
- ⚠️ Jenkins credentials (`jenks/admin123`) son para **lab only** - no producción

---

## Referencias Útiles

- [Documentación Jenkins](https://www.jenkins.io/doc/)
- [Jenkins Configuration as Code](https://github.com/jenkinsci/configuration-as-code-plugin)
- [GCP Artifact Registry](https://cloud.google.com/artifact-registry/docs)
- [Podman Rootless](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

---

**Última Actualización:** 2025-11-18 01:20 AM (Chile)  
**Autor:** Alejandro Cisternas  
**Estado:** Hito 2 Completado - Listo para Hito 3