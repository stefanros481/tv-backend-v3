# TV Backend v3

A microservices-based backend application for TV streaming platforms, built with FastAPI and Python.

## Project Overview

This project serves as a technology demonstrator for a modern TV streaming backend, showcasing a robust, scalable, and modular architecture built on microservices. It provides comprehensive content management, user authentication, rights management, and global search capabilities.

## Architecture

The system is built using a microservices architecture with the following components:

- **API Gateway**: Central entry point for all client requests, handling routing, authentication, and authorization
- **User Management Service**: Manages customer accounts and profiles
- **Authentication Service**: Handles user authentication with JWT
- **On-Demand Video Service**: Manages movies, series, and episodes
- **Live TV Service**: Manages channels and EPG data
- **Rights Management Service**: Controls content access based on subscriptions, purchases, and rentals
- **Global Search Service**: Provides unified search across all metadata

## Technology Stack

- **Backend Framework**: FastAPI (Python)
- **Database**: PostgreSQL
- **Search Engine**: Elasticsearch
- **Message Broker**: Redis (for Celery tasks)
- **Containerization**: Docker & Docker Compose
- **Package Management**: uv

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Python 3.10+
- uv (Python package installer)

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/stefanros481/tv-backend-v3.git
   cd tv-backend-v3
   ```

2. Start the services:
   ```bash
   docker compose up --build
   ```

3. The API will be available at http://localhost/health

### Project Structure

```
tv-backend-v3/
├── backend/
│   ├── api_gateway_service/
│   ├── user_management_service/
│   ├── authentication_service/
│   ├── ondemand_service/
│   ├── live_tv_service/
│   ├── rights_management_service/
│   └── global_search_service/
├── frontend/
└── docker-compose.yml
```

## Documentation

- [TASKS.md](./TASKS.md) - Project milestones and tasks
- [PLAN.md](./PLAN.md) - High-level project plan
- [DESIGNDOCUMENT.md](./DESIGNDOCUMENT.md) - Detailed architecture and design
- [APIENDPOINTS.md](./APIENDPOINTS.md) - Complete API documentation
- [APIGATEWAY.md](./APIGATEWAY.md) - API Gateway design and implementation

## License

This project is licensed under the MIT License - see the LICENSE file for details.
