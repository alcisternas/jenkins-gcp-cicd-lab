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