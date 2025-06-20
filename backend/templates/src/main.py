from typing import Dict

from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel

# Initialize FastAPI app
app = FastAPI(
    title="FastAPI Microservice",
    description="Template FastAPI microservice",
    version="0.1.0",
)


class HealthResponse(BaseModel):
    status: str
    service: str
    version: str


@app.get("/health", response_model=HealthResponse)
async def health_check() -> Dict[str, str]:
    """
    Health check endpoint to verify the service is running correctly.
    
    Returns:
        HealthResponse: Current health status of the service
    """
    return {
        "status": "ok",
        "service": app.title,
        "version": app.version,
    }


# Include routers here as the app grows
# Example: app.include_router(user_router, prefix="/users", tags=["users"])


@app.get("/")
async def root():
    """
    Root endpoint that redirects to the API documentation.
    """
    return {"message": "Welcome to the API! Visit /docs for documentation."}


# Add custom exception handlers as needed
@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    return {
        "status_code": exc.status_code,
        "detail": exc.detail,
    }


# Example startup and shutdown events
@app.on_event("startup")
async def startup_event():
    """
    Execute startup tasks like establishing database connections.
    """
    # Initialize resources - database connections, etc.
    print("Service starting up...")


@app.on_event("shutdown")
async def shutdown_event():
    """
    Execute shutdown tasks like closing database connections.
    """
    # Clean up resources - close connections, etc. 
    print("Service shutting down...")
