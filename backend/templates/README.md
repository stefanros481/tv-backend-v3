# FastAPI Microservice Template

This is a template for FastAPI microservices in the TV Streaming Backend Application.

## Structure

- `src/main.py` - Main FastAPI application entry point
- `src/` - Application source code
- `tests/` - Test files

## Getting Started

1. Copy this template to your new service directory
2. Update the service name in `pyproject.toml`
3. Modify `src/main.py` to implement your service's endpoints
4. Add the service to `docker-compose.yml`

## Development

### Running locally

```bash
# Install dependencies
pip install -e .

# Run the service
uvicorn src.main:app --reload
```

### Running with Docker

```bash
# Build and run the Docker container
docker build -t my-service .
docker run -p 8000:8000 my-service
```

## API Documentation

After starting the service, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
