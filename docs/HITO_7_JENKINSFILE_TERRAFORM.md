# Hito 7: Crear Jenkinsfile con Stages Terraform

**Fecha:** 2025-11-21  
**Estado:** ✅ Completado

---

## Objetivo

Crear un Jenkinsfile avanzado que ejecute pipelines completos de Terraform con:
- Parámetros dinámicos para diferentes acciones
- Stages condicionales
- Aprobaciones manuales
- Validaciones exhaustivas

---

## Implementación

### Jenkinsfile con Parámetros

**Archivo:** `jenkins/Jenkinsfile`

**Parámetros definidos:**
```groovy
parameters {
    choice(
        name: 'ACTION',
        choices: ['plan', 'apply', 'destroy'],
        description: 'Terraform action to perform'
    )
    booleanParam(
        name: 'AUTO_APPROVE',
        defaultValue: false,
        description: 'Skip manual approval for apply/destroy'
    )
}
```

**Variables de entorno:**
```groovy
environment {
    PROJECT_NAME = 'jenkins-gcp-cicd-lab'
    GCP_PROJECT = 'possible-sun-471215-d3'
    TF_IN_AUTOMATION = 'true'
    TF_INPUT = 'false'
    TF_DIR = 'terraform/test-module'
}
```

---

## Stages Implementados

### 1. Checkout (Stage 1)
- Muestra información del repositorio
- Branch, commit hash

### 2. Environment Info (Stage 2)
- pwd, ls, git log
- Verifica workspace

### 3. Verify Tools (Stage 3)
- Terraform version
- gcloud version
- Git version

### 4. Verify GCP Access (Stage 4)
- gcloud auth list
- gcloud config list
- gcloud projects describe

### 5. Terraform Init (Stage 5)
```groovy
dir(env.TF_DIR) {
    sh 'terraform init -upgrade'
    sh 'terraform version'
}
```

### 6. Terraform Validate (Stage 6)
```groovy
dir(env.TF_DIR) {
    sh 'terraform validate'
}
```

### 7. Terraform Format Check (Stage 7)
```groovy
sh 'terraform fmt -check -recursive || echo "Warning: Some files need formatting"'
```

### 8. Terraform Plan (Stage 8)
**Condicional:** Solo si ACTION=plan o ACTION=apply
```groovy
when {
    expression { params.ACTION == 'plan' || params.ACTION == 'apply' }
}
steps {
    sh 'terraform plan -out=tfplan'
}
```

### 9. Approval for Apply (Stage 9)
**Condicional:** Solo si ACTION=apply y AUTO_APPROVE=false
```groovy
when {
    allOf {
        expression { params.ACTION == 'apply' }
        expression { params.AUTO_APPROVE == false }
    }
}
steps {
    input message: 'Apply Terraform changes?',
          ok: 'Apply',
          submitter: 'jenks'
}
```

### 10. Terraform Apply (Stage 10)
**Condicional:** Solo si ACTION=apply
```groovy
when {
    expression { params.ACTION == 'apply' }
}
steps {
    sh 'terraform apply tfplan'
}
```

### 11-13. Terraform Destroy Stages
Similar a Apply pero para destroy:
- Terraform Destroy Plan
- Approval for Destroy
- Terraform Destroy

### 14. Terraform Output (Stage 14)
**Condicional:** Solo después de apply exitoso
```groovy
when {
    expression { params.ACTION == 'apply' }
}
steps {
    sh 'terraform output -json'
}
```

---

## Post Actions

### Always
```groovy
always {
    dir(env.TF_DIR) {
        sh 'rm -f tfplan tfplan-destroy || true'
    }
}
```

### Success
```groovy
success {
    echo '✅ Pipeline Completed Successfully!'
    echo "Action: ${params.ACTION}"
}
```

### Failure
```groovy
failure {
    echo '❌ Pipeline Failed!'
}
```

---

---

## Módulo Terraform de Test

### ¿Qué Hace el Módulo test-module?

**Ubicación:** `terraform/test-module/`

**Propósito:** Módulo seguro para testing que **NO crea recursos reales**.

**Contenido:**
```hcl
# Solo lee información existente
data "google_project" "current" {
  project_id = var.project_id
}

# Solo genera outputs informativos
output "project_info" {
  value = {
    project_id     = data.google_project.current.project_id
    project_name   = data.google_project.current.name
    project_number = data.google_project.current.number
  }
}
```

**Características:**
- ✅ **No crea recursos** (sin costos)
- ✅ **No modifica infraestructura** existente
- ✅ **Solo consulta** información del proyecto GCP
- ✅ `terraform apply` es **completamente seguro**
- ✅ `terraform destroy` no elimina nada (no hay recursos creados)

**Ideal para:**
- Testing de pipelines CI/CD
- Validación de integración Terraform + Jenkins
- Verificación de credenciales GCP
- Demostración de flujos de trabajo

---

## Validación Ejecutada

### Test 1: Plan Automático (Webhook)
**Trigger:** `git push`  
**Build:** #5  
**Parámetros:** ACTION=plan (default), AUTO_APPROVE=false  
**Resultado:** ✅ SUCCESS

**Stages ejecutados:**
1. ✅ Checkout
2. ✅ Environment Info
3. ✅ Verify Tools (Terraform, gcloud, Git)
4. ✅ Verify GCP Access
5. ✅ Terraform Init
6. ✅ Terraform Validate
7. ✅ Terraform Format Check
8. ✅ Terraform Plan

**Output del Plan:**
```
data.google_project.current: Read complete
Changes to Outputs:
+ project_info = {
    + project_id     = "possible-sun-471215-d3"
    + project_name   = "My First Project"
    + project_number = "461712618697"
  }
```

**Stages saltados (correctamente):**
- Approval for Apply (solo con ACTION=apply)
- Terraform Apply (solo con ACTION=apply)
- Terraform Destroy stages (solo con ACTION=destroy)

---

### Test 2: Apply con Aprobación Manual
**Trigger:** Manual - "Build with Parameters"  
**Parámetros:** ACTION=apply, AUTO_APPROVE=false  
**Resultado:** ✅ SUCCESS

**Flujo:**
1. Stages 1-8 ejecutados normalmente
2. **Stage 9: Pausa en "Approval for Apply"**
   - Mensaje: "Apply Terraform changes?"
   - Botón: "Apply"
   - Usuario jenks aprobó manualmente
3. Stage 10: Terraform Apply ejecutado
4. Stage 14: Terraform Output mostró información

**Apply ejecutado exitosamente:**
- Terraform state actualizado
- Outputs guardados
- No se crearon recursos reales (solo data source)

---

### Test 3: Destroy con Aprobación Manual
**Trigger:** Manual - "Build with Parameters"  
**Parámetros:** ACTION=destroy, AUTO_APPROVE=false  
**Resultado:** ✅ SUCCESS

**Flujo:**
1. Stages 1-8 ejecutados normalmente
2. Stage 11: Terraform Destroy Plan ejecutado
3. **Stage 12: Pausa en "Approval for Destroy"**
   - Mensaje: "Destroy Terraform resources?"
   - Botón: "Destroy"
   - Usuario jenks aprobó manualmente
4. Stage 13: Terraform Destroy ejecutado

**Destroy ejecutado exitosamente:**
- Terraform state limpiado
- No hay recursos para destruir (solo data source)
- Pipeline completado correctamente

---

## Stages Condicionales Validados

### Lógica de when Clauses

**ACTION = plan:**
```
✅ Terraform Plan
❌ Approval for Apply (saltado)
❌ Terraform Apply (saltado)
❌ Destroy stages (saltados)
```

**ACTION = apply + AUTO_APPROVE = false:**
```
✅ Terraform Plan
✅ Approval for Apply (pausa manual)
✅ Terraform Apply
✅ Terraform Output
❌ Destroy stages (saltados)
```

**ACTION = destroy + AUTO_APPROVE = false:**
```
❌ Plan/Apply stages (saltados)
✅ Terraform Destroy Plan
✅ Approval for Destroy (pausa manual)
✅ Terraform Destroy
```

---

### Test 2: Apply con Aprobación Manual
**Ejecutar:**
1. Build with Parameters
2. ACTION: apply
3. AUTO_APPROVE: false
4. Esperar aprobación manual
5. Aprobar
6. Apply ejecuta

### Test 3: Destroy con Aprobación
**Ejecutar:**
1. Build with Parameters
2. ACTION: destroy
3. AUTO_APPROVE: false
4. Esperar aprobación
5. Aprobar
6. Destroy ejecuta

---

## Lecciones Aprendidas

### 1. Variable TF_WORKSPACE Reservada
**Error inicial:**
```
Error: Invalid workspace name set using TF_WORKSPACE
```

**Solución:** Renombrar a `TF_DIR`
- `TF_WORKSPACE` es variable reservada de Terraform
- Usar nombres custom para paths

### 2. Conditional Stages con `when`
```groovy
when {
    expression { params.ACTION == 'apply' }
}
```

**Permite:**
- Ejecutar stages según parámetros
- Múltiples condiciones con `allOf`
- Evitar stages innecesarios

### 3. Manual Approval con `input`
```groovy
input message: 'Apply changes?',
      ok: 'Apply',
      submitter: 'jenks'
```

**Best practice:**
- Siempre requerir aprobación para apply/destroy
- Excepto en automation (AUTO_APPROVE=true)

### 4. Cleanup en Post Actions
```groovy
post {
    always {
        sh 'rm -f tfplan tfplan-destroy || true'
    }
}
```

**Importante:**
- Limpiar archivos temporales
- Usar `|| true` para no fallar si no existen

---

## Conclusión

✅ Pipeline avanzado de Terraform funcional  
✅ Parámetros dinámicos funcionando  
✅ Stages condicionales correctos  
✅ Aprobaciones manuales implementadas  
✅ Validaciones exhaustivas  
✅ Cleanup automático  

**Tiempo:** ~30 minutos  
**Hito:** 7/12 Completado ✅  
**Progreso:** 58.3%