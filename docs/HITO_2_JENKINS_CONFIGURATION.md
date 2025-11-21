# HITO 2: Configuración Básica de Jenkins

## Fecha de Completación
2025-11-18

## Objetivo Cumplido
✅ Configurar Jenkins con método enterprise usando Custom Docker Image, Configuration as Code (JCasC), y automatización completa mediante Cloud Build.

---

## Arquitectura de la Solución

### Componentes Principales
```
┌─────────────────────────────────────────────────────────────┐
│                     Desarrollo Local                        │
│  ┌────────────┐  ┌──────────────┐  ┌──────────────────┐     │
│  │ Dockerfile │  │ plugins.txt  │  │ jenkins-casc.yaml│     │
│  └────────────┘  └──────────────┘  └──────────────────┘     │
│         │                │                    │             │
│         └────────────────┴────────────────────┘             │
│                          │                                  │
│                    git push                                 │
│                          │                                  │
└──────────────────────────┼──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Cloud Build (GCP)                        │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ cloudbuild.yaml                                       │  │
│  │  1. Build custom Jenkins image                        │  │
│  │  2. Install 23+ plugins                               │  │
│  │  3. Embed JCasC configuration                         │  │
│  │  4. Push to Artifact Registry                         │  │
│  └───────────────────────────────────────────────────────┘  │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              Artifact Registry (us-central1)                │
│  jenkins-custom:latest                                      │
│  jenkins-custom:1.0.0                                       │
│  Size: ~390 MB                                              │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   GCE VM (jenkins-lab-vm)                    │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ startup-script.sh                                     │  │
│  │  1. Install Podman                                    │  │
│  │  2. Configure rootless                                │  │
│  │  3. Authenticate with Artifact Registry               │  │
│  │  4. Pull custom image                                 │  │
│  │  5. Start Jenkins container                           │  │
│  └───────────────────────────────────────────────────────┘  │
│                          │                                  │
│                          ▼                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Jenkins Container (Podman)                            │  │
│  │  - Pre-installed plugins                              │  │
│  │  - JCasC auto-configuration                           │  │
│  │  - No setup wizard                                    │  │
│  │  - Admin user: jenks / admin123                       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Archivos Creados/Modificados

### Nuevos Archivos
```
jenkins/
├── Dockerfile                  # Custom Jenkins image definition
├── plugins.txt                 # 23 plugins pre-instalados
├── jenkins-casc.yaml          # Configuration as Code
├── cloudbuild.yaml            # Cloud Build automation
├── .dockerignore              # Exclusiones para build
└── README.md                  # Documentación de la imagen

docs/
└── HITO_2_JENKINS_CONFIGURATION.md  # Este documento
```

### Archivos Modificados
```
terraform/jenkins-vm/
└── startup-script.sh          # Simplificado para usar imagen custom

.gcloudignore                  # Exclusiones para Cloud Build
```

---

## Proceso de Implementación

### Fase 1: Diseño y Preparación

**Decisión Arquitectónica:**
Tras múltiples intentos de configurar Jenkins con startup script + JCasC, se determinó que el método enterprise correcto es:
- **Custom Docker Image** con plugins pre-instalados
- **JCasC** embebido en la imagen
- **Cloud Build** para automatización

**Alternativas Evaluadas:**
1. ❌ Startup script con instalación manual de plugins → No reproducible
2. ❌ Startup script con JCasC pero sin plugins → Plugin JCasC no estaba instalado
3. ✅ Custom Docker Image con todo embebido → Método enterprise correcto

### Fase 2: Creación de Custom Docker Image

#### 2.1 Dockerfile
```dockerfile
FROM jenkins/jenkins:lts-jdk17

USER root
RUN apt-get update && \
    apt-get install -y git curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

USER jenkins

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
ENV CASC_JENKINS_CONFIG=/var/jenkins_home/casc_configs/jenkins.yaml

COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

COPY --chown=jenkins:jenkins jenkins-casc.yaml /usr/share/jenkins/ref/casc_configs/jenkins.yaml

EXPOSE 8080 50000
```

**Características:**
- Base: `jenkins/jenkins:lts-jdk17`
- Git pre-instalado
- Setup wizard deshabilitado
- 23 plugins pre-instalados
- JCasC configurado

#### 2.2 plugins.txt

**23 Plugins Instalados:**
```
git:latest
workflow-aggregator:latest
pipeline-stage-view:latest
credentials-binding:latest
ssh-slaves:latest
google-oauth-plugin:latest
google-storage-plugin:latest
docker-workflow:latest
docker-plugin:latest
terraform:latest
configuration-as-code:latest
slack:latest
email-ext:latest
mailer:latest
matrix-auth:latest
authorize-project:latest
blueocean:latest
dark-theme:latest
ws-cleanup:latest
timestamper:latest
build-timeout:latest
credentials:latest
plain-credentials:latest
```

#### 2.3 jenkins-casc.yaml

**Configuración Automatizada:**
- Usuario admin con variables de entorno
- Permisos globales configurados
- Herramientas pre-configuradas: Git, Docker, Terraform
- Seguridad habilitada
```yaml
jenkins:
  securityRealm:
    local:
      users:
        - id: "${JENKINS_ADMIN_ID}"
          password: "${JENKINS_ADMIN_PASSWORD}"
  
  authorizationStrategy:
    globalMatrix:
      permissions:
        - "Overall/Administer:${JENKINS_ADMIN_ID}"

tool:
  git:
    installations:
      - name: "Default"
        home: "git"
  terraform:
    installations:
      - name: "terraform"
        properties:
          - installSource:
              installers:
                - terraformInstaller:
                    id: "1.9.11-linux-amd64"
  dockerTool:
    installations:
      - name: "docker"
```

### Fase 3: Automatización con Cloud Build

#### 3.1 cloudbuild.yaml
```yaml
steps:
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'build'
      - '-t'
      - 'us-central1-docker.pkg.dev/$PROJECT_ID/apps/jenkins-custom:latest'
      - '-t'
      - 'us-central1-docker.pkg.dev/$PROJECT_ID/apps/jenkins-custom:1.0.0'
      - '-f'
      - 'jenkins/Dockerfile'
      - 'jenkins'
```

**Ejecución:**
```powershell
gcloud builds submit --config jenkins/cloudbuild.yaml .
```

**Resultado:**
- Build time: 51 segundos
- Imagen size: ~390 MB
- Tags: `latest`, `1.0.0`

### Fase 4: Simplificación de Startup Script

**startup-script.sh** reducido de ~150 líneas a ~100 líneas:

**Eliminado:**
- ❌ Creación manual de `jenkins-casc.yaml`
- ❌ Creación manual de `plugins.txt`
- ❌ Instalación manual de plugins

**Agregado:**
- ✅ Autenticación con Artifact Registry
- ✅ Pull de imagen custom
- ✅ Variables de entorno para admin user
```bash
# Authenticate with Artifact Registry
TOKEN=$(su - ${JENKINS_USER} -c "gcloud auth print-access-token")

# Pull custom image
su - ${JENKINS_USER} -c "podman pull ${JENKINS_IMAGE} --creds oauth2accesstoken:${TOKEN}"

# Run container
ExecStart=/usr/bin/podman run --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v ${JENKINS_HOME}:/var/jenkins_home \
  -e JENKINS_ADMIN_ID=jenks \
  -e JENKINS_ADMIN_PASSWORD=admin123 \
  ${JENKINS_IMAGE}
```

---

## Problemas Encontrados y Soluciones

### Problema 1: Windows CRLF vs Unix LF Line Endings

**Error:**
```
/bin/bash^M: bad interpreter: No such file or directory
```

**Causa:** Startup script editado en Windows con VS Code se guardó con line endings CRLF.

**Solución:**
```powershell
# En VS Code: Click "CRLF" → Seleccionar "LF"
# O con PowerShell:
(Get-Content startup-script.sh -Raw) -replace "`r`n","`n" | Set-Content startup-script.sh -NoNewline
```

**Lección:** Siempre usar LF para scripts de Linux, configurar VS Code correctamente.

---

### Problema 2: Plugin workspace-cleanup No Existe

**Error:**
```
Unable to resolve plugin URL .../workspace-cleanup.hpi: 404 Not Found
```

**Causa:** Nombre incorrecto del plugin.

**Solución:**
```diff
- workspace-cleanup:latest
+ ws-cleanup:latest
```

---

### Problema 3: Artifact Registry 403 Forbidden

**Error:**
```
Requesting bear token: invalid status code from registry 403 (Forbidden)
```

**Causa:** Service Account no tenía permisos de lectura en Artifact Registry.

**Solución:**
```powershell
gcloud projects add-iam-policy-binding possible-sun-471215-d3 \
  --member="serviceAccount:jenkins-cicd-sa@possible-sun-471215-d3.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"
```

**Roles finales del SA:**
- `roles/artifactregistry.reader` ← Agregado
- `roles/artifactregistry.writer`
- `roles/compute.instanceAdmin.v1`
- `roles/compute.networkUser`
- `roles/iam.serviceAccountUser`
- `roles/run.admin`
- `roles/secretmanager.secretAccessor`
- `roles/storage.admin`

---

### Problema 4: Podman No Puede Usar gcloud Credential Helper

**Error:**
```
error getting credentials - err: exit status 1
```

**Causa:** `gcloud auth configure-docker` funciona con Docker nativo, pero Podman requiere configuración especial.

**Solución:** Usar token de acceso directo:
```bash
TOKEN=$(gcloud auth print-access-token)
podman pull ${IMAGE} --creds oauth2accesstoken:${TOKEN}
```

---

### Problema 5: JCasC No Se Aplicaba en Reintentos

**Causa:** Al hacer `podman restart`, el volumen con configuración vieja quedaba cacheado.

**Solución:** Siempre hacer:
```bash
podman stop jenkins
podman rm jenkins
rm -rf ~/jenkins_home/*
# Luego iniciar de nuevo
```

---

### Problema 6: Systemd con Flag `-s` Mal Interpretado

**Error:**
```
Error: unknown shorthand flag: 's' in -s
```

**Causa:** El `$(curl -s ...)` en JENKINS_URL se interpretaba antes de tiempo.

**Solución:** Eliminar JENKINS_URL del ExecStart (Jenkins lo autodetecta).

---

### Problema 7: Startup Script No Se Re-ejecuta en Apply

**Causa:** `terraform apply` sin `destroy` NO vuelve a ejecutar startup scripts en VMs existentes.

**Solución:** Siempre hacer `terraform destroy` + `terraform apply` cuando se modifica startup script.

---

## Comandos Git Utilizados (Hito 4 - Adelantado)

Durante este hito aprendimos y aplicamos comandos Git:

### Git Revert
```powershell
# Revertir commit problemático
git revert 853e2dd

# Resultado: Nuevo commit que deshace cambios
```

### Git Diff
```powershell
# Ver diferencias entre commits
git diff 31dc2dc 853e2dd

# Ver solo archivos cambiados
git diff --stat 31dc2dc 853e2dd

# Ver cambios en archivo específico
git diff 31dc2dc 853e2dd -- terraform/jenkins-vm/startup-script.sh
```

### Git Status y Log
```powershell
# Ver estado actual
git status

# Ver historial resumido
git log --oneline -5
```

### Commits Realizados
```
c5c4edb - Revert "feat(hito-2): Configure Jenkins with JCasC..."
853e2dd - feat(hito-2): Configure Jenkins with JCasC... (revertido)
8de38a8 - feat(jenkins-vm): Add Git installation and Jenkins Configuration as Code
31dc2dc - fix(jenkins-vm): Remove SELinux :Z flag and set 777 permissions
```

---

## Verificación Final

### Checklist de Completación

- [x] Jenkins inicia sin setup wizard
- [x] Login con `jenks / admin123` funciona
- [x] Dashboard muestra mensaje de JCasC
- [x] 23+ plugins instalados
- [x] Git tool configurado
- [x] Docker tool configurado
- [x] Terraform tool configurado
- [x] Imagen en Artifact Registry
- [x] Cloud Build funcional
- [x] Reproducible con terraform destroy/apply

### Acceso
```
URL: http://34.172.178.70:8080
Usuario: jenks
Password: admin123
```

### Plugins Instalados Verificados
```
Dashboard → Manage Jenkins → Plugins → Installed plugins
Total: 23 plugins + dependencias
```

### Tools Configurados
```
Dashboard → Manage Jenkins → Tools
- Git: Default (git)
- Terraform: terraform (1.9.11-linux-amd64)
- Docker: docker (latest)
```

---

## Avisos Presentes (No Críticos)

1. ⚠️ **Proxy inverso:** URL detection, se puede ignorar o configurar
2. ⚠️ **Built-in node:** Best practice usar agents (Hito avanzado)
3. ℹ️ **Java 17 EOL:** Informativo, soporte hasta marzo 2026
4. ⚠️ **Permisos ambiguos:** Configuración puede refinarse (opcional)

**Ninguno bloquea el uso de Jenkins.**

---

## Lecciones Aprendidas

### Técnicas

1. **Custom Docker Images son el método correcto** para Jenkins enterprise
   - Reproducible
   - Versionable
   - Testeable localmente

2. **Configuration as Code (JCasC)** requiere que el plugin esté PRE-instalado
   - No se puede instalar plugins después del primer boot
   - Debe estar en la imagen base

3. **Podman en rootless** tiene diferencias con Docker
   - Credential helpers no funcionan igual
   - Usar tokens directos es más confiable

4. **Line endings importan** en scripts cross-platform
   - Siempre usar LF para Linux
   - Configurar editores correctamente

5. **Startup scripts solo corren en primer boot**
   - Cambios requieren destroy/apply
   - Testear con destroy/apply completo

### Metodológicas

1. **Documentar problemas es crítico**
   - Evita repetir errores
   - Ayuda al troubleshooting

2. **Git revert/diff son herramientas poderosas**
   - Revert crea historial limpio
   - Diff ayuda a encontrar qué cambió

3. **Infraestructura como código debe ser reproducible**
   - Test con destroy/apply
   - Validar desde cero

4. **Artifact Registry requiere autenticación explícita**
   - SA necesita roles correctos
   - Podman necesita configuración especial

---

## Tiempo Invertido

- **Diseño e investigación:** 1 hora
- **Implementación inicial:** 2 horas
- **Troubleshooting:** 3 horas
- **Refinamiento final:** 1 hora
- **Total:** ~7 horas

**Nota:** En producción, con esta documentación, el setup tomaría ~30 minutos.


 ---

## Mejora Post-Lab: Jobs Completamente Reproducibles (v1.4.0)

**Fecha:** 2025-11-21  
**Motivación:** Eliminar configuración manual de jobs después de cada deploy

### Problema Identificado

Después de H5, cada vez que se hacía `terraform destroy/apply`, era necesario:
- ❌ Reconfigurar credenciales GitHub manualmente
- ❌ Recrear 3 jobs manualmente (15-20 min)
- ❌ Reconfigurar webhooks

**Solución:** Agregar jobs a JCasC usando plugin job-dsl.

### Implementación

#### 1. Agregar Plugin job-dsl

**Archivo:** `jenkins/plugins.txt`
```
job-dsl:latest
```

**Resultado:** Permite crear jobs programáticamente vía JCasC.

#### 2. Definir Jobs en jenkins-casc.yaml

**Archivo:** `jenkins/jenkins-casc.yaml`

Agregamos sección `jobs:` al final del archivo con 3 jobs:

**a) github-integration-test** (Pipeline inline)
```yaml
jobs:
  - script: >
      pipelineJob('github-integration-test') {
        description('Test GitHub integration with Jenkins')
        properties {
          githubProjectUrl('https://github.com/alcisternas/jenkins-gcp-cicd-lab/')
        }
        triggers {
          githubPush()
        }
        definition {
          cps {
            script('''
              pipeline {
                agent any
                stages {
                  stage('Clone Repository') { ... }
                  stage('List Files') { ... }
                  stage('Show Git Info') { ... }
                }
              }
            '''.stripIndent())
            sandbox()
          }
        }
      }
```

**b) terraform-integration-test** (Pipeline inline con Terraform)
```yaml
  - script: >
      pipelineJob('terraform-integration-test') {
        triggers { githubPush() }
        definition {
          cps {
            script('''
              pipeline {
                agent any
                environment {
                  TF_IN_AUTOMATION = 'true'
                  TF_INPUT = 'false'
                }
                stages {
                  stage('Terraform Init') { ... }
                  stage('Terraform Validate') { ... }
                  stage('Terraform Plan') { ... }
                }
              }
            '''.stripIndent())
          }
        }
      }
```

**c) jenkins-cicd-pipeline** (Pipeline from SCM)
```yaml
  - script: >
      pipelineJob('jenkins-cicd-pipeline') {
        triggers { githubPush() }
        definition {
          cpsScm {
            scm {
              git {
                remote {
                  url('https://github.com/alcisternas/jenkins-gcp-cicd-lab.git')
                  credentials('github-token')
                }
                branches('*/main')
              }
            }
            scriptPath('jenkins/Jenkinsfile')
          }
        }
      }
```

**Tipos de jobs:**
- **CPS (Pipeline inline):** Script Groovy embebido directamente en JCasC
- **cpsScm (Pipeline from SCM):** Lee Jenkinsfile desde repositorio Git

#### 3. Nueva Imagen Custom

**Versión:** 1.4.0  
**Plugins totales:** 24 (23 originales + job-dsl)  
**Tamaño:** ~400 MB  
**Build time:** ~3 minutos

**Build:**
```powershell
gcloud builds submit --config jenkins/cloudbuild.yaml .
```

#### 4. Deploy y Validación

**Deploy:**
```powershell
cd terraform
terraform destroy -auto-approve
terraform apply -auto-approve
```

**Validación:**
- Jenkins inicia → Dashboard muestra "Jenkins configured automatically via Configuration as Code (JCasC)"
- 3 jobs aparecen automáticamente sin configuración manual
- `git push` → 3 jobs se disparan automáticamente
- ✅ SUCCESS en los 3 jobs

### Resultado Final

✅ **Jobs creados automáticamente** al iniciar Jenkins  
✅ **Webhooks funcionando** - 3 jobs se disparan en cada push  
✅ **Cero configuración manual** de jobs  
✅ **100% reproducible** con destroy/apply  

**Única configuración manual requerida:**
- Credencial GitHub (token `ghp_...`) por seguridad

**Jobs configurados:**
1. `github-integration-test` - Valida integración Git
2. `terraform-integration-test` - Ejecuta Terraform init/validate/plan
3. `jenkins-cicd-pipeline` - Pipeline principal desde Jenkinsfile

### Lecciones Aprendadas

1. **Plugin job-dsl es esencial** para Jobs as Code en JCasC
   - JCasC solo no puede crear jobs
   - job-dsl proporciona DSL Groovy para definir jobs

2. **Sintaxis es Groovy DSL**, no YAML
   - Usar `script:` con pipeline Groovy
   - Escape de comillas con triple comillas `'''`

3. **Credenciales deben existir antes**
   - Jobs referencian `github-token`
   - Se debe crear manualmente (seguridad)

4. **Error común:** `UnknownConfiguratorException: jobs`
   - Significa que falta plugin job-dsl
   - Solución: Agregar a plugins.txt

5. **Webhooks requieren trigger explícito**
   - `triggers { githubPush() }` en cada job
   - Sin esto, jobs no se disparan automáticamente

---



---

## Próximos Pasos

✅ **Hito 2 Completado**

**Siguiente: Hito 3 - Conectar con Service Account (roles mínimos)**
- Configurar credenciales en Jenkins
- Testear acceso a GCP desde Jenkins
- Verificar permisos del SA

---

## Referencias

- [Jenkins Configuration as Code Plugin](https://github.com/jenkinsci/configuration-as-code-plugin)
- [Jenkins Docker Official Image](https://hub.docker.com/r/jenkins/jenkins)
- [GCP Cloud Build Documentation](https://cloud.google.com/build/docs)
- [GCP Artifact Registry](https://cloud.google.com/artifact-registry/docs)
- [Podman Rootless](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md)