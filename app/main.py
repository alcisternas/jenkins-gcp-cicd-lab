from fastapi import FastAPI
import os

app = FastAPI(title="Jenkins CI/CD Lab - H8")

@app.get("/")
def read_root():
    return {
        "message": "Hello from Jenkins CI/CD Lab!",
        "hito": "H8 - Artifact Registry Integration",
        "version": os.getenv("APP_VERSION", "1.0.0"),
        "environment": os.getenv("ENVIRONMENT", "development")
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.get("/info")
def info():
    return {
        "app": "jenkins-cicd-lab",
        "hito": "H8",
        "description": "FastAPI app integrated with Jenkins and Artifact Registry"
    }