# Hito 4: Comandos Básicos de Git

**Fecha de Completación:** 2025-11-18  
**Estado:** ✅ Completado

---

## Comandos Demostrados

### Durante todo el laboratorio (H1-H3):
- ✅ `git status` - Ver estado del repositorio
- ✅ `git add` - Agregar archivos al staging area
- ✅ `git commit` - Crear commits con mensajes descriptivos
- ✅ `git push` - Subir cambios al repositorio remoto
- ✅ `git log` - Ver historial de commits
- ✅ `git diff` - Ver diferencias entre versiones

### En H4 específicamente:
- ✅ `git pull` - Traer cambios del repositorio remoto
- ✅ **Resolución de conflictos de merge**

---

## Demo de Resolución de Conflictos

### Escenario Creado:
1. Cambio remoto en GitHub (línea del objetivo en README)
2. Cambio local en la misma línea
3. Intento de push rechazado
4. Pull genera conflicto de merge

### Proceso de Resolución:
```powershell
# Pull detecta conflicto
git pull origin main
# Output: CONFLICT (content): Merge conflict in README.md

# Ver archivos en conflicto
git status

# Editar archivo manualmente
# - Buscar marcadores: <<<<<<<, =======, >>>>>>>
# - Combinar ambas versiones
# - Eliminar marcadores

# Marcar como resuelto
git add README.md

# Completar merge
git commit -m "merge: Resolve conflict in README.md"

# Push
git push origin main
```

### Resultado:
```
*   f3a3e69 (HEAD -> main) merge: Resolve conflict
|\
| * f58812f Cambio remoto
* | a17a998 Cambio local
|/
```

---

## Comandos de Referencia
```bash
# Ver estado
git status

# Agregar cambios
git add <archivo>
git add .  # todos los archivos

# Commit
git commit -m "mensaje"

# Push
git push origin main

# Pull
git pull origin main

# Ver historial
git log --oneline -10
git log --oneline --graph -10  # con grafo

# Ver diferencias
git diff  # cambios no staged
git diff HEAD~1 HEAD  # último commit vs anterior

# Descartar cambios locales
git restore <archivo>

# Ver ramas
git branch

# Configuración
git config pull.rebase false  # usar merge para divergencias
```

---

## Conclusión

✅ Todos los comandos básicos de Git demostrados  
✅ Resolución exitosa de conflictos de merge  
✅ Uso práctico durante todo el laboratorio  

**Tiempo:** ~25 minutos  
**Hito:** 4/12 Completado ✅