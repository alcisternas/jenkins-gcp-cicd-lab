# HITO 1: Instalar Jenkins en GCE con Podman Rootless

## Fecha de Completación
2025-11-16

## Objetivo Cumplido
✅ Instalar Jenkins en una VM de Google Compute Engine usando Podman en modo rootless, siguiendo mejores prácticas empresariales con Infrastructure as Code (Terraform).

---

## Metas del Laboratorio Cubiertas en este Hito

### ✅ META 1: Instalar Jenkins en GCE with podman

**Configuración Responsable:**

#### 1.1 Creación de la VM en GCE
**Archivo:** `terraform/jenkins-vm/main.tf`  
**Líneas:** 8-56
```hcl
resource "google_compute_instance" "jenkins_vm" {
  name         = var.vm_name
  machine_type = var.vm_machine_type
  zone         = var.zone
  project      = var.project_id

  tags = var.network_tags

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = var.vm_disk_size_gb
      type  = var.vm_disk_type
    }
    auto_delete = true
  }

  network_interface {
    network    = var.network_name
    subnetwork = var.subnet_name

    access_config {
      # Ephemeral external IP
    }
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
    startup-script = file("${path.module}/startup-script.sh")
  }

  shielded_instance_config {
    enable_secure_boot          = false
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  labels = {
    environment = var.environment
    purpose     = "jenkins-cicd"
    managed_by  = "terraform"
  }
}
```

**Por qué cumple la meta:**
- Crea una instancia de Compute Engine (GCE)
- Especifica Ubuntu 22.04 LTS como sistema operativo
- Configura disco de 50GB SSD
- Asigna IP externa para acceso
- Ejecuta startup script automáticamente al iniciar

---

#### 1.2 Instalación de Podman
**Archivo:** `terraform/jenkins-vm/startup-script.sh`  
**Líneas:** 18-20
```bash
# 2. Install Podman and dependencies
echo "[$(date)] Installing Podman and dependencies..."
apt-get install -y podman uidmap slirp4netns fuse-overlayfs
```

**Por qué cumple la meta:**
- `podman`: Runtime de contenedores (alternativa a Docker)
- `uidmap`: Permite mapeo de UIDs para rootless containers
- `slirp4netns`: Networking para contenedores sin privilegios
- `fuse-overlayfs`: Driver de almacenamiento overlay para rootless

---

#### 1.3 Configuración Rootless (Usuario sin privilegios)
**Archivo:** `terraform/jenkins-vm/startup-script.sh`  
**Líneas:** 23-26
```bash
# 3. Create Jenkins user (non-root)
echo "[$(date)] Creating Jenkins user..."
if ! id "${JENKINS_USER}" &>/dev/null; then
    useradd -m -s /bin/bash ${JENKINS_USER}
fi
```

**Por qué cumple la meta:**
- Crea usuario `jenkins` sin privilegios de root
- Este usuario ejecutará el contenedor de Jenkins
- Cumple principio de **least privilege**

**Líneas:** 29-31
```bash
# 4. Enable lingering for Jenkins user
echo "[$(date)] Enabling lingering for Jenkins user..."
loginctl enable-linger ${JENKINS_USER}
```

**Por qué cumple la meta:**
- Permite que servicios systemd del usuario `jenkins` se ejecuten sin sesión activa
- Necesario para que Jenkins inicie automáticamente al boot de la VM

**Líneas:** 34-40
```bash
# 5. Configure subuid and subgid for rootless containers
echo "[$(date)] Configuring subuid and subgid..."
if ! grep -q "^${JENKINS_USER}:" /etc/subuid; then
    echo "${JENKINS_USER}:100000:65536" >> /etc/subuid
fi
if ! grep -q "^${JENKINS_USER}:" /etc/subgid; then
    echo "${JENKINS_USER}:100000:65536" >> /etc/subgid
fi
```

**Por qué cumple la meta:**
- Configura rangos de subordinate UIDs y GIDs
- Permite que contenedores rootless mapeen usuarios internos a rangos seguros
- UID 100000-165535 disponibles para el usuario jenkins

 ---

#### 1.4 Configuración de Almacenamiento Podman
**Archivo:** `terraform/jenkins-vm/startup-script.sh`  
**Líneas:** 54-68
```bash
# 7. Configure Podman storage for rootless
echo "[$(date)] Configuring Podman storage..."
mkdir -p /home/${JENKINS_USER}/.config/containers
cat > /home/${JENKINS_USER}/.config/containers/storage.conf <<EOF
[storage]
driver = "overlay"
runroot = "/run/user/$(id -u ${JENKINS_USER})/containers"
graphroot = "/home/${JENKINS_USER}/.local/share/containers/storage"

[storage.options]
pull_options = {enable_partial_images = "true", use_hard_links = "false", ostree_repos=""}

[storage.options.overlay]
mountopt = "nodev"
EOF
```

**Por qué cumple la meta:**
- Configura driver `overlay` para almacenamiento eficiente de imágenes
- Define rutas específicas del usuario (no rutas globales de root)
- `mountopt = "nodev"`: Opción de montaje compatible con kernel 6.8.0-1043-gcp
- **CRÍTICO**: Se removió `metacopy=on` por incompatibilidad detectada durante troubleshooting

---

#### 1.5 Descarga de Imagen Jenkins
**Archivo:** `terraform/jenkins-vm/startup-script.sh`  
**Líneas:** 73-75
```bash
# 8. Pull Jenkins image as jenkins user
echo "[$(date)] Pulling Jenkins LTS image..."
su - ${JENKINS_USER} -c "podman pull docker.io/jenkins/jenkins:lts"
```

**Por qué cumple la meta:**
- Descarga imagen oficial de Jenkins LTS
- Ejecutado como usuario `jenkins` (no root)
- Usa Docker Hub como registry (`docker.io`)

---

#### 1.6 Servicio Systemd para Jenkins
**Archivo:** `terraform/jenkins-vm/startup-script.sh`  
**Líneas:** 78-99
```bash
# 9. Create systemd service for Jenkins
echo "[$(date)] Creating systemd service..."
mkdir -p /home/${JENKINS_USER}/.config/systemd/user
cat > /home/${JENKINS_USER}/.config/systemd/user/jenkins.service <<EOF
[Unit]
Description=Jenkins CI/CD Server (Rootless Podman)
After=network-online.target
Wants=network-online.target

[Service]
Restart=always
TimeoutStartSec=0
ExecStartPre=-/usr/bin/podman stop jenkins
ExecStartPre=-/usr/bin/podman rm jenkins
ExecStart=/usr/bin/podman run --name jenkins \\
  -p 8080:8080 \\
  -p 50000:50000 \\
  -v ${JENKINS_HOME}:/var/jenkins_home \\
  docker.io/jenkins/jenkins:lts
ExecStop=/usr/bin/podman stop jenkins

[Install]
WantedBy=default.target
EOF
```

**Por qué cumple la meta:**
- **Systemd user service**: Servicio ejecutado por usuario `jenkins`, no por root
- `Restart=always`: Jenkins se reinicia automáticamente si falla
- `ExecStartPre`: Limpia contenedores previos antes de iniciar
- `-p 8080:8080`: Expone puerto web de Jenkins
- `-p 50000:50000`: Puerto para agentes Jenkins (JNLP)
- `-v ${JENKINS_HOME}:/var/jenkins_home`: Volumen persistente para datos de Jenkins
- **CRÍTICO**: Se removió flag `:Z` de SELinux por problemas de permisos

**Líneas:** 104-106
```bash
# 10. Enable and start Jenkins service
echo "[$(date)] Enabling and starting Jenkins service..."
su - ${JENKINS_USER} -c "systemctl --user daemon-reload"
su - ${JENKINS_USER} -c "systemctl --user enable jenkins.service"
su - ${JENKINS_USER} -c "systemctl --user start jenkins.service"
```

**Por qué cumple la meta:**
- Habilita el servicio para inicio automático
- Inicia Jenkins inmediatamente
- Todo ejecutado como usuario `jenkins` (`systemctl --user`)

---

### ✅ META PARCIAL: Conectar con Service Account (roles mínimos)

**Configuración Responsable:**

#### VM con Service Account Attached
**Archivo:** `terraform/jenkins-vm/main.tf`  
**Líneas:** 34-37
```hcl
service_account {
  email  = var.service_account_email
  scopes = ["cloud-platform"]
}
```

**Por qué cumple la meta:**
- La VM usa el Service Account `jenkins-cicd-sa` creado en Hito 0
- **NO usa JSON keys** (best practice empresarial)
- El SA está attached a la VM directamente
- Scope `cloud-platform` permite acceso a todas las APIs de GCP según los roles IAM del SA

**Roles del Service Account** (configurados en Hito 0):
- `roles/artifactregistry.writer` - Para push de imágenes Docker
- `roles/run.admin` - Para deploy en Cloud Run
- `roles/secretmanager.secretAccessor` - Para leer secrets
- `roles/iam.serviceAccountUser` - Para actuar como SA en Cloud Run
- `roles/compute.instanceAdmin.v1` - Para Terraform crear VMs
- `roles/compute.networkUser` - Para Terraform usar redes
- `roles/storage.admin` - Para Terraform state en GCS

---

## Arquitectura Resultante
```
Internet
    │
    ├─── SSH (22) ──────────┐
    └─── HTTP (8080) ───────┤
                            │
                    ┌───────▼─────────┐
                    │  Firewall Rules │
                    └───────┬─────────┘
                            │
        ┌───────────────────▼────────────────────┐
        │     jenkins-lab-vpc (Custom VPC)       │
        │                                        │
        │  ┌─────────────────────────────────┐   │
        │  │  jenkins-subnet (10.10.0.0/24)  │   │
        │  │                                 │   │
        │  │    ┌─────────────────────┐      │   │
        │  │    │  jenkins-lab-vm     │      │   │
        │  │    │  Ubuntu 22.04 LTS   │      │   │
        │  │    │  e2-standard-4      │      │   │
        │  │    │  Internal: 10.10.0.2│      │   │
        │  │    │  External: 35.239.. │      │   │
        │  │    │                     │      │   │
        │  │    │  ┌───────────────┐  │      │   │
        │  │    │  │ User: jenkins │  │      │   │
        │  │    │  │ (UID: 1001)   │  │      │   │
        │  │    │  │               │  │      │   │
        │  │    │  │ ┌───────────┐ │  │      │   │
        │  │    │  │ │  Podman   │ │  │      │   │
        │  │    │  │ │ (rootless)│ │  │      │   │
        │  │    │  │ │           │ │  │      │   │
        │  │    │  │ │ ┌───────┐ │ │  │      │   │
        │  │    │  │ │ │Jenkins│ │ │  │      │   │
        │  │    │  │ │ │:8080  │ │ │  │      │   │
        │  │    │  │ │ └───────┘ │ │  │      │   │
        │  │    │  │ └───────────┘ │  │      │   │
        │  │    │  └───────────────┘  │      │   │
        │  │    └─────────────────────┘      │   │
        │  └─────────────────────────────────┘   │
        │                                        │
        │  ┌─────────────────────────────────┐   │
        │  │  Cloud Router + NAT             │   │
        │  └─────────────────────────────────┘   │
        └────────────────────────────────────────┘
                            │
                    Service Account
                jenkins-cicd-sa@...
                            │
                    ┌───────▼─────────┐
                    │   GCP APIs      │
                    │ - Artifact Reg  │
                    │ - Secret Mgr    │
                    │ - Cloud Run     │
                    └─────────────────┘
```

---

## Comandos Ejecutados

### 1. Creación de Infraestructura con Terraform
```powershell
cd C:\Users\a.cisternas.guajardo\source\repos\jenkins-gcp-cicd-lab\terraform

# Inicializar Terraform (descargar providers, configurar backend)
terraform init

# Validar sintaxis de código
terraform validate

# Ver plan de ejecución (qué se creará)
terraform plan

# Aplicar infraestructura
terraform apply
# Output: 8 recursos creados
# - VPC Network
# - Subnet
# - Cloud Router
# - Cloud NAT
# - 3 Firewall Rules
# - VM Jenkins
```

### 2. Outputs de Terraform
```
jenkins_url                  = "http://35.239.17.0:8080"
jenkins_vm_external_ip       = "35.239.17.0"
jenkins_vm_internal_ip       = "10.10.0.2"
jenkins_vm_name              = "jenkins-lab-vm"
network_name                 = "jenkins-lab-vpc"
subnet_cidr                  = "10.10.0.0/24"
subnet_name                  = "jenkins-subnet"
ssh_command                  = "gcloud compute ssh jenkins-lab-vm --project=possible-sun-471215-d3 --zone=us-central1-a"
get_jenkins_password_command = "gcloud compute ssh jenkins-lab-vm --project=possible-sun-471215-d3 --zone=us-central1-a --command='sudo su - jenkins -c \"podman exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword\"'"
```

### 3. Acceso a Jenkins
```powershell
# Abrir navegador
Start-Process "http://35.239.17.0:8080"

# Password inicial obtenido del contenedor:
# 648cd2a42588434eb9cf92d255efb053
```

### 4. Setup Inicial de Jenkins

1. Ingresar password inicial: `648cd2a42588434eb9cf92d255efb053`
2. Seleccionar "Install suggested plugins"
3. Esperar instalación de plugins (3-5 minutos)
4. Crear primer usuario admin: `jenks`
5. Configurar Jenkins URL: `http://35.239.17.0:8080` (dejar por defecto)
6. Click "Start using Jenkins"

---

## Problemas Encontrados y Soluciones

### PROBLEMA 1: Startup Script con Permisos Incorrectos (Exit 126)

#### Síntoma
```
Nov 16 21:30:45 jenkins-lab-vm google_metadata_script_runner[1448]: startup-script: /bin/bash: /tmp/metadata-scripts.../startup-script: Permission denied
Nov 16 21:30:45 jenkins-lab-vm google_metadata_script_runner[1448]: Script "startup-script" failed with error: exit status 126
```

#### Causa Raíz
Terraform usaba `metadata_startup_script` como argumento separado, lo cual no preserva permisos de ejecución del archivo cuando GCE intenta ejecutarlo.

**Configuración Problemática:**
**Archivo:** `terraform/jenkins-vm/main.tf` (versión inicial incorrecta)
```hcl
resource "google_compute_instance" "jenkins_vm" {
  # ... otras configuraciones ...
  
  metadata = {
    enable-oslogin = "TRUE"
  }
  
  # ❌ INCORRECTO - Genera archivos sin permisos de ejecución
  metadata_startup_script = file("${path.module}/startup-script.sh")
}
```

**Por qué falla:**
- GCE copia el script a `/tmp/metadata-scripts*/startup-script`
- El archivo resultante no tiene flag de ejecución (`-x`)
- Bash intenta ejecutar pero recibe "Permission denied"
- Exit code 126 = "Command found but not executable"

#### Solución Aplicada
**Archivo:** `terraform/jenkins-vm/main.tf` (versión corregida)
```hcl
resource "google_compute_instance" "jenkins_vm" {
  # ... otras configuraciones ...
  
  metadata = {
    enable-oslogin = "TRUE"
    startup-script = file("${path.module}/startup-script.sh")  # ✅ CORRECTO
  }
  
  # ❌ Línea eliminada:
  # metadata_startup_script = file("${path.module}/startup-script.sh")
}
```

**Por qué funciona:**
- El campo `startup-script` dentro de `metadata` es un parámetro estándar de GCE
- GCE interpreta este campo directamente y ejecuta el contenido como script
- No requiere permisos de ejecución en el archivo fuente
- El contenido se ejecuta con `/bin/bash -c`

#### Verificación de la Solución
```powershell
# Destruir infraestructura con código incorrecto
terraform destroy

# Aplicar con código corregido
terraform apply

# Verificar que el startup script se ejecutó correctamente
gcloud compute ssh jenkins-lab-vm --project=possible-sun-471215-d3 --zone=us-central1-a --command="sudo journalctl -u google-startup-scripts.service | tail -5"

# Output esperado:
# Finished Google Compute Engine Startup Scripts.
# (sin errores de "Permission denied")
```

#### Commits Relacionados
- `4d35da5` - Initial Terraform structure (código incorrecto)
- Primera corrección aplicada durante troubleshooting en vivo

#### Aprendizaje Clave
**SIEMPRE usar `metadata.startup-script` en lugar de `metadata_startup_script` como argumento separado.**

Este es un patrón común en recursos de GCE y evita problemas de permisos.

---

### PROBLEMA 2: Error de Overlay Mount - metacopy Incompatible

#### Síntoma
```bash
jenkins@jenkins-lab-vm:~$ podman run --rm hello-world
Error: error mounting storage for container: error creating overlay mount
mount_data="nodev,metacopy=on,lowerdir=...,upperdir=...,workdir=...,userxattr": invalid argument
```

**Contenedor Jenkins intentaba iniciar pero fallaba inmediatamente:**
```
Nov 16 22:41:36 jenkins-lab-vm systemd[3371]: jenkins.service: Main process exited, code=exited, status=126/n/a
Nov 16 22:41:36 jenkins-lab-vm systemd[3371]: jenkins.service: Failed with result 'exit-code'.
```

#### Diagnóstico

**Paso 1: Verificar configuración de Podman storage**
```bash
jenkins@jenkins-lab-vm:~$ cat ~/.config/containers/storage.conf
[storage]
driver = "overlay"
...
[storage.options.overlay]
mountopt = "nodev,metacopy=on"  # ← Opción problemática
```

**Paso 2: Verificar estado real del sistema**
```bash
jenkins@jenkins-lab-vm:~$ podman info | grep -A 5 "graphOptions"
graphOptions:
  overlay.mountopt: nodev,metacopy=on
graphStatus:
  Backing Filesystem: extfs
  Native Overlay Diff: "false"
  Using metacopy: "false"  # ← ¡Conflicto detectado!
```

**Paso 3: Verificar kernel**
```bash
jenkins@jenkins-lab-vm:~$ uname -r
6.8.0-1043-gcp
```

#### Causa Raíz
**La opción `metacopy=on` no es compatible con el kernel 6.8.0-1043-gcp de Ubuntu 22.04 en GCE.**

**Configuración Problemática:**
**Archivo:** `terraform/jenkins-vm/startup-script.sh` (versión inicial)
**Líneas:** 66-67
```bash
[storage.options.overlay]
mountopt = "nodev,metacopy=on"  # ❌ INCOMPATIBLE
```

**Por qué falla:**
- `metacopy` es una optimización del driver overlay filesystem
- Requiere soporte específico del kernel y filesystem
- El kernel 6.8.0-1043-gcp no tiene este soporte habilitado
- Podman intenta montar con esta opción y el kernel rechaza con "invalid argument"

#### Solución Aplicada

**Archivo:** `terraform/jenkins-vm/startup-script.sh` (versión corregida)
**Líneas:** 66-67
```bash
[storage.options.overlay]
mountopt = "nodev"  # ✅ COMPATIBLE - Solo opción básica
```

**Por qué funciona:**
- `nodev`: Opción estándar que previene creación de device files
- Compatible con todos los kernels
- Suficiente para operación segura de contenedores rootless

#### Pasos de Remediación Ejecutados

**Dentro de la VM, como usuario jenkins:**
```bash
# 1. Editar configuración de storage
nano ~/.config/containers/storage.conf
# Cambiar línea: mountopt = "nodev,metacopy=on" → mountopt = "nodev"

# 2. Limpiar storage corrupto de Podman
podman system reset --force
# Output: A storage.conf file exists at /home/jenkins/.config/containers/storage.conf

# 3. Verificar nueva configuración
podman info | grep -A 5 "graphOptions"
# Output esperado:
#   graphOptions:
#     overlay.mountopt: nodev
#   graphStatus:
#     Native Overlay Diff: "true"  # ← Mejorado

# 4. Test de funcionamiento
podman run --rm hello-world
# Output esperado:
# Hello from Docker!
# This message shows that your installation appears to be working correctly.
# ✅ ÉXITO
```

#### Actualización del Código Terraform

**Commit:** `abd8006`
```bash
git add terraform/jenkins-vm/startup-script.sh
git commit -m "fix(jenkins-vm): Remove metacopy=on from Podman storage config
- metacopy is incompatible with kernel 6.8.0-1043-gcp
- Podman was failing with 'invalid argument' on overlay mount
- Removed metacopy=on, keeping only nodev mount option
- This fixes container creation errors in rootless Podman"
git push origin main
```

#### Verificación Post-Fix
```bash
# Destruir VM actual
terraform destroy

# Aplicar con código corregido
terraform apply

# Esperar ~5 minutos para startup script

# Verificar que Jenkins inició correctamente
gcloud compute ssh jenkins-lab-vm --command="sudo su - jenkins -c 'podman ps'"
# Output esperado: Contenedor jenkins corriendo en puerto 8080
```

#### Aprendizaje Clave
**SIEMPRE probar opciones de mount de overlay filesystem en el kernel target antes de deployar a producción.**

Opciones como `metacopy`, `userxattr`, `volatile` tienen dependencias específicas de kernel/filesystem.

Para máxima compatibilidad en rootless Podman:
```bash
mountopt = "nodev"  # Opción segura y universal
```

 ---

### PROBLEMA 3: Permisos de Volumen Jenkins - Flag :Z de SELinux

#### Síntoma
```bash
jenkins@jenkins-lab-vm:~$ podman logs jenkins
touch: cannot touch '/var/jenkins_home/copy_reference_file.log': Permission denied
INSTALL WARNING: User: missing rw permissions on JENKINS_HOME: /var/jenkins_home
Can not write to /var/jenkins_home/copy_reference_file.log. Wrong volume permissions?
```

**Contenedor iniciaba pero Jenkins no podía escribir en su directorio home.**

#### Diagnóstico

**Paso 1: Verificar contenedor**
```bash
jenkins@jenkins-lab-vm:~$ podman ps -a
CONTAINER ID  IMAGE                          STATUS
717d72c4bf9f  docker.io/jenkins/jenkins:lts  Created  # ← Nunca pasó a "Running"
```

**Paso 2: Verificar permisos del volumen**
```bash
jenkins@jenkins-lab-vm:~$ ls -la /home/jenkins/ | grep jenkins_home
drwxr-xr-x 2 jenkins jenkins 4096 Nov 16 22:41 jenkins_home
```

**Paso 3: Verificar UID del usuario**
```bash
jenkins@jenkins-lab-vm:~$ id jenkins
uid=1001(jenkins) gid=1002(jenkins) groups=1002(jenkins)
```

**Paso 4: Verificar configuración del servicio**
```bash
jenkins@jenkins-lab-vm:~$ cat ~/.config/systemd/user/jenkins.service | grep ExecStart
ExecStart=/usr/bin/podman run --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v /home/jenkins/jenkins_home:/var/jenkins_home:Z \  # ← Flag :Z problemático
  docker.io/jenkins/jenkins:lts
```

#### Causa Raíz

**Hay DOS problemas combinados:**

**Problema A: Mismatch de UIDs**
- Usuario `jenkins` en VM tiene UID **1001**
- Contenedor Jenkins espera escribir como UID **1000**
- Directorio owned por UID 1001, contenedor no puede escribir

**Problema B: Flag :Z de SELinux**
- El flag `:Z` intenta relabel de SELinux en el volumen
- En este entorno causa conflictos adicionales de permisos
- Ubuntu 22.04 en GCE no usa SELinux por defecto

**Configuración Problemática:**
**Archivo:** `terraform/jenkins-vm/startup-script.sh` (versión inicial)
**Líneas:** 49-51 y 91
```bash
# 6. Create Jenkins home directory
mkdir -p ${JENKINS_HOME}
chown -R ${JENKINS_USER}:${JENKINS_USER} ${JENKINS_HOME}
# ❌ FALTA: chmod para permitir escritura de UID 1000

# ... más adelante ...

ExecStart=/usr/bin/podman run --name jenkins \\
  -p 8080:8080 \\
  -p 50000:50000 \\
  -v ${JENKINS_HOME}:/var/jenkins_home:Z \\  # ❌ Flag :Z problemático
  docker.io/jenkins/jenkins:lts
```

#### Solución Aplicada

**Archivo:** `terraform/jenkins-vm/startup-script.sh` (versión corregida)

**Cambio 1: Permisos permisivos en el directorio (Líneas 49-51)**
```bash
# 6. Create Jenkins home directory
mkdir -p ${JENKINS_HOME}
chown -R ${JENKINS_USER}:${JENKINS_USER} ${JENKINS_HOME}
chmod -R 777 ${JENKINS_HOME}  # ✅ AGREGADO - Permite escritura de cualquier UID
```

**Por qué funciona:**
- Permisos `777` (rwxrwxrwx) permiten lectura/escritura/ejecución para:
  - Owner (UID 1001)
  - Group (GID 1002)
  - Others (incluye UID 1000 del contenedor)
- No es ideal para producción, pero funcional para lab

**Cambio 2: Remover flag :Z (Línea 91)**
```bash
ExecStart=/usr/bin/podman run --name jenkins \\
  -p 8080:8080 \\
  -p 50000:50000 \\
  -v ${JENKINS_HOME}:/var/jenkins_home \\  # ✅ Sin :Z
  docker.io/jenkins/jenkins:lts
```

**Por qué funciona:**
- Sin `:Z`, Podman no intenta relabeling de SELinux
- El volumen se monta directamente sin modificaciones de contexto
- Compatible con sistemas sin SELinux activo

#### Pasos de Remediación Ejecutados

**Desde la VM:**
```bash
# 1. Salir de usuario jenkins
exit

# 2. Como root, cambiar permisos del directorio
sudo su -
chown -R 1000:1000 /home/jenkins/jenkins_home  # Intentado primero (no funcionó completamente)
chmod -R 777 /home/jenkins/jenkins_home         # Solución final

# 3. Verificar permisos
ls -ln /home/jenkins/ | grep jenkins_home
# Output: drwxrwxrwx 2 1000 1000 4096 Nov 16 22:41 jenkins_home

# 4. Volver a usuario jenkins e iniciar contenedor
su - jenkins
podman stop jenkins
podman rm jenkins

# 5. Ejecutar SIN flag :Z
podman run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v /home/jenkins/jenkins_home:/var/jenkins_home \
  docker.io/jenkins/jenkins:lts

# 6. Verificar logs
podman logs -f jenkins
# Output esperado:
# Running from: /usr/share/jenkins/jenkins.war
# Jenkins home directory: /var/jenkins_home found at: EnvVars.masterEnvVars.get("JENKINS_HOME")
# ...
# *************************************************************
# Jenkins initial setup is required. An admin user has been created and a password generated.
# Please use the following password to proceed to installation:
#
# 648cd2a42588434eb9cf92d255efb053
# *************************************************************
# Jenkins is fully up and running
# ✅ ÉXITO
```

#### Actualización del Código Terraform

**Commit:** `31dc2dc`
```bash
git add terraform/jenkins-vm/startup-script.sh
git commit -m "fix(jenkins-vm): Remove SELinux :Z flag and set 777 permissions
- SELinux :Z flag was causing permission errors in rootless Podman
- Changed jenkins_home permissions to 777 for compatibility
- Removed :Z from volume mount in systemd service"
git push origin main
```

#### Verificación Post-Fix
```bash
# Desde PowerShell local
terraform destroy
terraform apply

# Esperar ~5 minutos

# Acceder a Jenkins
Start-Process "http://35.239.17.0:8080"
# ✅ Pantalla "Unlock Jenkins" visible
```

#### Aprendizaje Clave

**Para volúmenes de Podman rootless con mismatch de UIDs:**

1. **Opción A (Lab/Dev):** Permisos permisivos `chmod 777`
2. **Opción B (Producción):** Usar `--userns=keep-id` en podman run
3. **Opción C (Mejor):** Construir imagen personalizada con UID correcto

**Flag :Z de SELinux:**
- Solo usar en sistemas con SELinux activo (RHEL/CentOS/Fedora)
- No usar en Ubuntu/Debian (no tienen SELinux por defecto)
- Verificar siempre: `getenforce` (debe retornar "Enforcing" o "Permissive")

**Configuración final funcional:**
```bash
# Permisos del directorio
chmod -R 777 /home/jenkins/jenkins_home

# Volumen sin flags especiales
-v /home/jenkins/jenkins_home:/var/jenkins_home
```

---

## Recursos Creados por Terraform

### Tabla de Recursos

| Recurso           | Nombre                            | Tipo                          | Propósito                     |
|---------          |--------                           |------                         |-----------                    |
| VPC Network       | `jenkins-lab-vpc`                 | `google_compute_network`      | Red aislada personalizada     |
| Subnet            | `jenkins-subnet`                  | `google_compute_subnetwork`   | Segmento de red 10.10.0.0/24  |
| Cloud Router      | `jenkins-lab-vpc-router`          | `google_compute_router`       | Enrutamiento para Cloud NAT   |
| Cloud NAT         | `jenkins-lab-vpc-nat`             | `google_compute_router_nat`   | NAT gateway para VMs futuras  |
| Firewall: SSH     | `jenkins-lab-vpc-allow-ssh`       | `google_compute_firewall`     | Permite SSH (puerto 22)       |
| Firewall: Jenkins | `jenkins-lab-vpc-allow-jenkins`   | `google_compute_firewall`     | Permite HTTP (puerto 8080)    |
| Firewall: Internal| `jenkins-lab-vpc-allow-internal`  | `google_compute_firewall`     | Permite tráfico interno en VPC|
| VM Jenkins        | `jenkins-lab-vm`                  | `google_compute_instance`     | Servidor Jenkins principal    |

**Total: 8 recursos**

---

### Detalles de la VM Jenkins
```bash
# Obtener detalles completos de la VM
gcloud compute instances describe jenkins-lab-vm --project=possible-sun-471215-d3 --zone=us-central1-a --format=yaml
```

**Especificaciones:**
- **Nombre:** jenkins-lab-vm
- **Zona:** us-central1-a
- **Machine Type:** e2-standard-4 (4 vCPU, 16 GB RAM)
- **Sistema Operativo:** Ubuntu 22.04 LTS (ubuntu-2204-jammy-v20241115)

 ---

## Conclusiones del Hito 1

### Objetivos Logrados

✅ **Infraestructura completamente como código**
- 100% de recursos creados con Terraform
- Ningún recurso creado manualmente vía gcloud o consola
- Código versionado en Git con historial completo

✅ **Jenkins instalado en GCE con Podman Rootless**
- Contenedor ejecutándose como usuario sin privilegios (UID 1001)
- Servicio systemd user para inicio automático
- Accesible en http://35.239.17.0:8080

✅ **Best Practices Empresariales Aplicadas**
- Infrastructure as Code (IaC) con Terraform
- Módulos reutilizables (network, jenkins-vm)
- Backend remoto para state (GCS con versionado)
- Service Account attached a VM (NO JSON keys)
- Principio de least privilege
- Documentación exhaustiva de troubleshooting

✅ **Troubleshooting Documentado**
- 3 problemas mayores identificados y resueltos
- Soluciones aplicadas al código Terraform
- Conocimiento transferible a futuros deploys

---

### Métricas del Hito

| Métrica | Valor |
|---------|-------|
| Recursos Terraform creados | 8 |
| Líneas de código Terraform | ~350 |
| Líneas de startup script | 139 |
| Commits realizados | 3 |
| Problemas resueltos | 3 |
| Tiempo total invertido | ~3 horas |
| Reintentos de deploy | 2 (troubleshooting) |

---

### Lecciones Aprendidas

#### 1. Sobre Terraform y GCE
**Lección:** Siempre usar `metadata.startup-script` en lugar de `metadata_startup_script` como argumento separado.

**Impacto:** Evita errores de permisos (exit 126) en startup scripts.

**Aplicación futura:** Patrón estándar para todos los recursos `google_compute_instance`.

---

#### 2. Sobre Podman Rootless
**Lección:** Las opciones de mount de overlay filesystem (`metacopy`, `userxattr`) tienen dependencias específicas de kernel.

**Impacto:** Código que funciona en un kernel puede fallar en otro.

**Aplicación futura:** 
- Probar siempre en entorno target antes de producción
- Usar configuraciones minimalistas: `mountopt = "nodev"`
- Documentar versiones de kernel compatibles

---

#### 3. Sobre Volúmenes en Contenedores Rootless
**Lección:** Mismatch de UIDs entre host y contenedor requiere permisos permisivos o remapping.

**Impacto:** Contenedor no puede escribir en volúmenes owned por otro UID.

**Aplicación futura:**
- **Desarrollo/Lab:** `chmod 777` (rápido pero inseguro)
- **Producción:** `--userns=keep-id` o imagen custom con UID correcto
- Evitar flag `:Z` en sistemas sin SELinux

---

#### 4. Sobre Troubleshooting Sistemático
**Lección:** Un approach metódico de debugging ahorra tiempo.

**Proceso exitoso aplicado:**
1. Identificar síntoma exacto (logs, error messages)
2. Diagnosticar causa raíz (no asumir)
3. Probar solución en VM viva
4. Aplicar fix al código Terraform
5. Validar con destroy/apply completo
6. Documentar para futuros deploys

---

### Diferencias entre Enfoque Manual vs IaC

| Aspecto | Manual (gcloud/console) | IaC (Terraform) |
|---------|------------------------|-----------------|
| Reproducibilidad | ❌ Difícil repetir exactamente | ✅ `terraform apply` recrea todo |
| Versionado | ❌ No hay historial | ✅ Git completo |
| Colaboración | ❌ Conocimiento tribal | ✅ Code review, PRs |
| Auditoría | ❌ Difícil rastrear cambios | ✅ Git blame, commits |
| Rollback | ❌ Manual y propenso a errores | ✅ `git revert` + `terraform apply` |
| Documentación | ❌ Separada del proceso | ✅ El código ES la documentación |
| Testing | ❌ Solo en producción | ✅ Ambientes efímeros |
| Costo de tiempo inicial | ✅ Más rápido (aparente) | ⚠️ Más lento (inversión) |
| Costo de tiempo a largo plazo | ❌ Crece linealmente | ✅ Se amortiza |

**Conclusión:** La inversión en IaC se paga desde el segundo deploy.

---

### Estado Final del Sistema
```
✅ VPC Network creada (jenkins-lab-vpc)
✅ Subnet configurada (10.10.0.0/24)
✅ Firewall rules aplicadas (SSH, Jenkins, Internal)
✅ Cloud Router y NAT operativos
✅ VM Ubuntu 22.04 corriendo (e2-standard-4)
✅ Service Account attached (jenkins-cicd-sa)
✅ Podman rootless instalado (v3.4.4)
✅ Usuario jenkins configurado (UID 1001)
✅ Systemd user service activo
✅ Contenedor Jenkins corriendo
✅ Jenkins accesible en puerto 8080
✅ Usuario admin creado (jenks)
✅ Plugins básicos instalados
✅ Dashboard funcional
```

---

## Siguiente Hito

### HITO 2: Configurar Jenkins Basic Mode

**Objetivos:**
1. Configurar seguridad y usuarios en Jenkins
2. Instalar plugins adicionales necesarios para CI/CD
3. Configurar herramientas globales (Git, Maven, etc.)
4. Configurar credenciales para GitHub
5. Configurar System Settings básicos

**Pre-requisitos cumplidos:**
- ✅ Jenkins instalado y accesible
- ✅ Usuario admin creado
- ✅ Plugins básicos instalados
- ✅ VM con Service Account configurado

**Documentos relacionados:**
- `docs/HITO_0_PREPARACION.md` - Setup inicial de proyecto
- `docs/HITO_1_JENKINS_INSTALLATION.md` - Este documento
- `docs/HITO_2_JENKINS_BASIC_CONFIG.md` - (Próximo)

---

## Recursos Adicionales

### Documentación Oficial Consultada

- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GCE Metadata Startup Scripts](https://cloud.google.com/compute/docs/instances/startup-scripts)
- [Podman Rootless Containers](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md)
- [Jenkins Docker Image](https://hub.docker.com/r/jenkins/jenkins)
- [Systemd User Services](https://www.freedesktop.org/software/systemd/man/systemd.service.html)

### Comandos de Referencia Rápida
```bash
# Terraform
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy
terraform state list
terraform output

# GCP
gcloud compute instances list
gcloud compute ssh jenkins-lab-vm --zone=us-central1-a
gcloud compute instances describe jenkins-lab-vm --zone=us-central1-a

# Podman (como usuario jenkins)
podman ps
podman logs jenkins
podman exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
podman stop jenkins
podman start jenkins
podman system reset --force

# Systemd (como usuario jenkins)
systemctl --user status jenkins.service
systemctl --user restart jenkins.service
journalctl --user -u jenkins.service -f

# Helpers creados
get-jenkins-password
jenkins-status
```

---

## Checklist Final del Hito 1

- [x] VPC y networking creados con Terraform
- [x] VM Jenkins creada con Terraform
- [x] Podman instalado en modo rootless
- [x] Usuario jenkins configurado sin privilegios root
- [x] Contenedor Jenkins corriendo
- [x] Jenkins accesible vía web (puerto 8080)
- [x] Service Account attached a VM
- [x] Startup script automatizado y funcional
- [x] Problemas de metacopy resueltos
- [x] Problemas de permisos resueltos
- [x] Código Terraform corregido y versionado
- [x] Documentación completa generada
- [x] Usuario admin creado en Jenkins
- [x] Plugins básicos instalados
- [x] Dashboard de Jenkins funcional

**Estado del Hito 1:** ✅ **COMPLETADO**

---

## Próximos Pasos

1. **Commit de esta documentación**
```powershell
   cd C:\Users\a.cisternas.guajardo\source\repos\jenkins-gcp-cicd-lab
   git add docs/HITO_1_JENKINS_INSTALLATION.md
   git commit -m "docs(hito-1): Add complete documentation with troubleshooting and configurations"
   git push origin main
```

2. **Actualizar README principal** con link al Hito 1

3. **Iniciar Hito 2**: Configurar Jenkins Basic Mode
   - Configuración de seguridad
   - Instalación de plugins adicionales
   - Configuración de herramientas globales

---

**Fin del Hito 1**

---

*Documentado por: Alejandro Cisternas*  
*Fecha: 2025-11-16*  
*Versión: 1.0*
- **Disco:** 50 GB SSD (pd-balanced)
- **IP Interna:** 10.10.0.2
- **IP Externa:** 35.239.17.0 (efímera)
- **Service Account:** jenkins-cicd-sa@possible-sun-471215-d3.iam.gserviceaccount.com
- **Tags de Red:** jenkins-server
- **Labels:**
  - environment: lab
  - purpose: jenkins-cicd
  - managed_by: terraform

---

## Comandos de Verificación

### 1. Verificar Estado de la Infraestructura
```powershell
# Ver estado de Terraform
cd C:\Users\a.cisternas.guajardo\source\repos\jenkins-gcp-cicd-lab\terraform
terraform show

# Listar recursos en el state
terraform state list

# Output esperado:
# module.jenkins_vm.data.google_compute_image.ubuntu
# module.jenkins_vm.google_compute_instance.jenkins_vm
# module.network.google_compute_firewall.allow_internal
# module.network.google_compute_firewall.allow_jenkins
# module.network.google_compute_firewall.allow_ssh
# module.network.google_compute_network.vpc
# module.network.google_compute_router.router
# module.network.google_compute_router_nat.nat
# module.network.google_compute_subnetwork.subnet
```

### 2. Verificar Recursos en GCP
```powershell
# Verificar VM
gcloud compute instances list --project=possible-sun-471215-d3 --filter="name=jenkins-lab-vm"

# Verificar red
gcloud compute networks describe jenkins-lab-vpc --project=possible-sun-471215-d3

# Verificar firewall rules
gcloud compute firewall-rules list --project=possible-sun-471215-d3 --filter="network:jenkins-lab-vpc"

# Verificar Cloud NAT
gcloud compute routers nats list --router=jenkins-lab-vpc-router --region=us-central1 --project=possible-sun-471215-d3
```

### 3. Verificar Jenkins Funcionando
```powershell
# Test de conectividad a puerto 8080
Test-NetConnection -ComputerName 35.239.17.0 -Port 8080
# Output esperado: TcpTestSucceeded : True

# SSH a la VM
gcloud compute ssh jenkins-lab-vm --project=possible-sun-471215-d3 --zone=us-central1-a
```

**Dentro de la VM:**
```bash
# Verificar usuario jenkins
id jenkins
# Output: uid=1001(jenkins) gid=1002(jenkins) groups=1002(jenkins)

# Verificar Podman instalado
podman --version
# Output: podman version 3.4.4

# Verificar contenedor corriendo (como usuario jenkins)
sudo su - jenkins
podman ps
# Output esperado:
# CONTAINER ID  IMAGE                          STATUS      PORTS                                           NAMES
# c16f4c47feae  docker.io/jenkins/jenkins:lts  Up 15 min   0.0.0.0:8080->8080/tcp, 0.0.0.0:50000->50000/tcp  jenkins

# Verificar servicio systemd
systemctl --user status jenkins.service
# Output esperado: Active: active (running)

# Ver logs de Jenkins
podman logs jenkins --tail 50

# Obtener password inicial
podman exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
# Output: 648cd2a42588434eb9cf92d255efb053
```

### 4. Verificar Acceso Web
```powershell
# Abrir Jenkins en navegador
Start-Process "http://35.239.17.0:8080"
```

**Checklist de verificación:**
- [ ] Página "Unlock Jenkins" carga correctamente
- [ ] Password inicial funciona
- [ ] Plugins suggested se instalan sin errores
- [ ] Usuario admin creado exitosamente
- [ ] Dashboard principal es accesible

---

## Estado del Terraform State
```powershell
# Ver información del backend
terraform state pull | Select-String -Pattern "serial"

# Verificar que el state está en GCS
gsutil ls gs://my-project-bootstrap-476516-terraform-state/jenkins-lab/infrastructure/
# Output esperado: default.tfstate

# Ver versiones del state (con versionado habilitado)
gsutil ls -a gs://my-project-bootstrap-476516-terraform-state/jenkins-lab/infrastructure/default.tfstate
```

---

## Estructura de Archivos del Repositorio
```
jenkins-gcp-cicd-lab/
├── .git/
├── .gitignore
├── README.md
├── terraform/
│   ├── .gitignore
│   ├── .terraform/                    # Ignorado en Git
│   ├── .terraform.lock.hcl
│   ├── backend.tf                     # Configuración de GCS backend
│   ├── main.tf                        # Root module
│   ├── outputs.tf                     # Outputs principales
│   ├── README.md                      # Documentación de Terraform
│   ├── terraform.tfvars               # Variables del proyecto (Ignorado en Git)
│   ├── variables.tf                   # Definición de variables
│   ├── versions.tf                    # Provider versions
│   ├── network/
│   │   ├── main.tf                    # VPC, subnets, firewall, NAT
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── jenkins-vm/
│       ├── main.tf                    # VM configuration
│       ├── outputs.tf
│       ├── startup-script.sh          # Script de instalación
│       └── variables.tf
├── app/
│   ├── Dockerfile
│   └── requirements.txt
├── jenkins/
│   └── Jenkinsfile
├── scripts/
└── docs/
    ├── HITO_0_PREPARACION.md
    └── HITO_1_JENKINS_INSTALLATION.md
```

---

## Costos Estimados

| Recurso | Especificación | Costo Mensual (USD) |
|---------|---------------|---------------------|
| VM e2-standard-4 | 4 vCPU, 16 GB RAM | ~$98 |
| Disco SSD 50GB | pd-balanced | ~$4 |
| Cloud NAT Gateway | us-central1 | ~$45 |
| IP Externa | Efímera (mientras VM corre) | $0 |
| VPC, Subnet, Firewall | N/A | $0 |
| Egress Internet | Variable | $0.12/GB |
| **TOTAL ESTIMADO** | | **~$147/mes** |

**Nota:** Costos basados en precios de GCP para us-central1 (Noviembre 2025).

---

## Commits del Hito 1
```bash
# Ver historial de commits del Hito 1
git log --oneline --grep="jenkins-vm\|Hito 1" --all

# Output:
# 31dc2dc fix(jenkins-vm): Remove SELinux :Z flag and set 777 permissions
# abd8006 fix(jenkins-vm): Remove metacopy=on from Podman storage config
# 4d35da5 docs: Complete Hito 0 - Environment preparation
```

### Detalles de cada commit:

**Commit 1:** Initial Terraform structure
- Creación de módulos network y jenkins-vm
- Configuración de backend en GCS
- Outputs completos

**Commit 2:** `abd8006` - Fix metacopy
- Removió `metacopy=on` de storage.conf
- Identificó incompatibilidad con kernel 6.8.0-1043-gcp
- Solución verificada con `podman run hello-world`

**Commit 3:** `31dc2dc` - Fix permisos y SELinux
- Agregó `chmod -R 777` para jenkins_home
- Removió flag `:Z` del volumen
- Jenkins inició exitosamente

