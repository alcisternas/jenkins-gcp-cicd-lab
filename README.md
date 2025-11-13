# Jenkins + GCP CI/CD Pipeline Lab

Laboratorio completo de CI/CD usando Jenkins, Git, Terraform, Docker y Google Cloud Platform.

## Objetivo
Implementar un pipeline enterprise-grade siguiendo mejores prácticas de DevOps y seguridad.

## Arquitectura
- **Jenkins**: VM en GCE con Podman
- **Autenticación**: Workload Identity (VM Service Account)
- **IaC**: Terraform para recursos GCP
- **Containers**: Docker/Podman → Artifact Registry → Cloud Run
- **Secrets**: Secret Manager
- **Notificaciones**: Slack + Email

## Estructura del Proyecto
```
├── terraform/          # Infraestructura como código
├── app/               # Aplicación FastAPI
├── jenkins/           # Jenkinsfiles y configuración
└── docs/              # Documentación de cada hito
```

## Proyecto GCP
- **ID**: possible-sun-471215-d3
- **Región**: us-central1
- **Zona**: us-central1-a

## Hitos Completados
- [x] Hito 0: Preparación del entorno
- [ ] Hito 1: Instalar Jenkins en GCE con Podman
- [ ] ... (resto de hitos)