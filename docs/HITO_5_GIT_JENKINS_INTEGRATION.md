# Hito 5: Integrar Git con Jenkins

**Fecha:** 2025-11-20  
**Estado:** ✅ Completado

---

## Implementado

### 1. GitHub Personal Access Token
- Creado en GitHub con scopes: `repo`, `admin:repo_hook`
- Configurado en Jenkins como credential: `github-token`
- Tipo: Username with password

### 2. Webhook Automático
- URL: `http://34.72.222.37:8080/github-webhook/`
- Trigger: Push events
- Status: ✅ Funcionando
- Comprobado: "Started by GitHub push by alcisternas"

### 3. SCM Polling (Backup)
- Schedule: `H/5 * * * *` (cada 5 minutos)
- Redundancia en caso de fallo de webhook

### 4. Pipeline Jobs

#### Job: `github-integration-test`
- Tipo: Pipeline script
- Stages: Clone, List Files, Show Git Info
- Trigger: Webhook + Polling

#### Job: `jenkins-cicd-pipeline`  
- Tipo: Pipeline from SCM
- Source: `jenkins/Jenkinsfile`
- Stages: Checkout, Environment, GCP Verify, Structure
- Trigger: Webhook + Polling

---

## Resultado

✅ Push automático dispara builds  
✅ Jenkins clona repositorio  
✅ Jenkinsfile versionado en Git  
✅ Integración completa GitHub ↔ Jenkins

---

**Tiempo:** ~45 minutos  
**Hito:** 5/12 Completado ✅  
**Progreso:** 41.7%