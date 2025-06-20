# TV Streaming Backend Application: Milestone Plan

This document breaks down the project into actionable milestones and detailed tasks.

## Milestone 1: Project Setup & Core Infrastructure (Estimated Duration: 1-2 weeks)

**Goal:** Establish the foundational project structure and bring up core infrastructure services.

* **Task 1.10: Initialize Monorepo**
    - [ ] Create `tv-backend-v3` root directory.
    - [ ] Create `backend/`, `frontend/` directories.
    - [ ] Add initial `README.md` and `.gitignore`.
* **Task 1.20: Docker Compose for Infrastructure**
    - [ ] Create `docker-compose.yml`.
    - [ ] Define `db` service (PostgreSQL).
    - [ ] Define `redis` service (for caching/Celery broker).
    - [ ] Define `elasticsearch` service (for Global Search).
    - [ ] Configure basic health checks for `db` and `elasticsearch`.
    - [ ] Set up persistent Docker volumes.
* **Task 1.30: Base FastAPI Service Setup**
    - [ ] Create a template `Dockerfile` for Python FastAPI services.
    - [ ] Create a template `pyproject.toml` with basic FastAPI/uvicorn dependencies.
    - [ ] Define a base FastAPI app structure (`src/main.py`).
* **Task 1.40: Initial API Gateway Skeleton**
    - [ ] Create `backend/api_gateway_service/` directory.
    - [ ] Add `Dockerfile` and `pyproject.toml`.
    - [ ] Implement basic `main.py` with `FastAPI` app and `httpx` client.
    - [ ] Define a placeholder health check endpoint (`/health`).
    - [ ] Configure `api_gateway_service` in `docker-compose.yml` to be the only exposed backend service.
* **Task 1.50: Verify Basic Infrastructure**
    - [ ] Run `docker compose up --build`.
    - [ ] Verify all infrastructure containers start and are healthy.
    - [ ] Verify API Gateway is accessible via `http://localhost/health`.

## Milestone 2: User & Authentication Microservices (Estimated Duration: 2-3 weeks)

**Goal:** Implement core user account management and JWT-based authentication.

* **Task 2.10: User Management Service Development**
    - [ ] Create `backend/user_management_service/`.
    - [ ] Define Pydantic models for `Customer` and `Profile`.
    - [ ] Implement SQLAlchemy models for PostgreSQL.
    - [ ] Develop API endpoints: `POST /users`, `GET /users/me`, `GET/POST/PUT/DELETE /users/profiles`.
    - [ ] Implement password hashing (bcrypt).
    - [ ] Add initial unit tests.
* **Task 2.20: Authentication Service Development**
    - [ ] Create `backend/authentication_service/`.
    - [ ] Implement `POST /auth/register` (calls User Mgmt service to create user).
    - [ ] Implement `POST /auth/login` (verifies credentials with User Mgmt, generates JWT).
    - [ ] Implement JWT validation logic.
    - [ ] Add initial unit tests.
* **Task 2.30: API Gateway Integration for Auth & Users**
    - [ ] Update API Gateway:
        - [ ] Implement `get_current_user_from_token` dependency for JWT validation.
        - [ ] Define routes for `/auth/*` (public) and `/users/*` (authenticated).
        - [ ] Ensure auth token is passed from Gateway to User Management Service.
* **Task 2.40: Integration Testing (Auth & Users)**
    - [ ] Verify user registration and login through the API Gateway.
    - [ ] Verify authenticated access to user profile endpoints.

## Milestone 3: Content Management Microservices (Estimated Duration: 3-4 weeks)

**Goal:** Implement comprehensive management for On-Demand Video and Live TV content.

* **Task 3.10: On-Demand Video Service Development**
    - [ ] Create `backend/ondemand_service/`.
    - [ ] Define Pydantic and SQLAlchemy models for `Movie`, `Series`, `Episode`, `Genre`, `Person`.
    - [ ] Develop API endpoints: `GET /ondemand/movies`, `GET /ondemand/series`, `GET /ondemand/series/{series_id}/episodes`, `GET /ondemand/episodes/{episode_id}`.
    - [ ] Add initial unit tests.
* **Task 3.20: Live TV Service Development**
    - [ ] Create `backend/live_tv_service/`.
    - [ ] Define Pydantic and SQLAlchemy models for `Channel`, `EPGEntry`.
    - [ ] Develop API endpoints: `GET /livetv/channels`, `GET /livetv/epg`.
    - [ ] Add initial unit tests.
* **Task 3.30: API Gateway Integration for Content**
    - [ ] Update API Gateway with routes for `/ondemand/*` and `/livetv/*` (authenticated access).
* **Task 3.40: Integration Testing (Content Browsing)**
    - [ ] Verify browsing movies, series, and channels through the API Gateway.

## Milestone 4: Rights Management & Playback (Estimated Duration: 2-3 weeks)

**Goal:** Implement content access control and integrate playback initiation.

* **Task 4.10: Rights Management Service Development**
    - [ ] Create `backend/rights_management_service/`.
    - [ ] Define Pydantic and SQLAlchemy models for `SubscriptionPlan`, `PurchasedContent`, `RentedContent`, `ContentAccessRule`.
    - [ ] Develop internal API endpoint: `POST /rights/check_access`.
    - [ ] Develop client-facing endpoints: `GET /subscriptions`, `GET /users/purchases`, `GET /users/rentals`, `POST /ondemand/purchase/{content_id}`, `POST /ondemand/rent/{content_id}`.
    - [ ] Implement access logic considering SVOD, purchase, and rental rules.
    - [ ] Add initial unit tests.
* **Task 4.20: Playback Endpoint Integration**
    - [ ] Update On-Demand Video Service: Implement `GET /play/ondemand/{content_id}`. This endpoint will call the internal Rights Management Service (`POST /rights/check_access`) before returning the playback URL.
    - [ ] Update Live TV Service: Implement `GET /play/live/{channel_id}`. This endpoint will call the internal Rights Management Service (`POST /rights/check_access`) before returning the playback URL.
* **Task 4.30: API Gateway Integration for Playback & Rights**
    - [ ] Update API Gateway with routes for `/play/*` (authenticated access).
    - [ ] Update API Gateway with routes for client-facing subscription/purchase/rental endpoints.
* **Task 4.40: Integration Testing (Rights & Playback)**
    - [ ] Test content access based on different subscription/purchase/rental scenarios.
    - [ ] Verify successful playback initiation for authorized users.

## Milestone 5: Global Search & Indexing (Estimated Duration: 3-4 weeks)

**Goal:** Implement low-latency global search with real-time indexing.

* **Task 5.10: Global Search Service Development**
    - [ ] Create `backend/global_search_service/`.
    - [ ] Integrate Elasticsearch client.
    - [ ] Implement `GET /search/global` API endpoint for querying Elasticsearch.
    - [ ] Configure Elasticsearch mapping and analyzers for metadata fields.
    - [ ] Add unit tests for search logic.
* **Task 5.20: Asynchronous Indexing Setup**
    - [ ] Configure Celery worker in `global_search_service` to connect to Redis broker.
    - [ ] Implement Celery tasks for indexing/updating content in Elasticsearch.
    - [ ] Modify On-Demand Video Service and Live TV Service:
        - [ ] Upon `POST/PUT/DELETE` operations on content, send a message to Redis queue (e.g., "index_movie", "update_channel").
        - [ ] Global Search worker consumes these messages and updates its Elasticsearch index.
* **Task 5.30: API Gateway Integration for Global Search**
    - [ ] Update API Gateway with the route for `GET /search/global`.
* **Task 5.40: Integration Testing (Global Search)**
    - [ ] Verify real-time search functionality (index new content, search, update content, search again).
    - [ ] Test `search-as-you-type` behavior with various queries.

## Milestone 6: Admin API & Cross-Cutting Concerns (Estimated Duration: 2-3 weeks)

**Goal:** Implement admin functionalities and enhance overall system robustness.

* **Task 6.10: Admin API Endpoints Implementation**
    - [ ] In each relevant microservice (User Mgmt, On-Demand, Live TV, Rights Mgmt), implement the `/admin/*` endpoints (CRUD for managing data).
* **Task 6.20: API Gateway Admin Authorization**
    - [ ] Implement `require_admin_role` dependency in API Gateway.
    - [ ] Apply `require_admin_role` to all `/admin/*` routes in API Gateway.
* **Task 6.30: Logging & Error Handling Refinement**
    - [ ] Implement structured logging across all microservices (Python `logging` module).
    - [ ] Refine error responses for consistency across all services and the Gateway.
    - [ ] Implement global exception handlers in FastAPI apps.
* **Task 6.40: Comprehensive Testing**
    - [ ] Write extensive unit tests for all new admin endpoints and logic.
    - [ ] Implement integration tests for admin workflows through the API Gateway.
    - [ ] Review and enhance existing tests.
* **Task 6.50: Security Hardening (Demonstrator Level)**
    - [ ] Ensure all sensitive data (secrets, passwords) are handled via environment variables (or Docker secrets if preferred).
    - [ ] Implement basic rate limiting on API Gateway.

## Milestone 7: Frontend Demonstrator & End-to-End Validation (Estimated Duration: 2-3 weeks)

**Goal:** Build a basic frontend to demonstrate backend functionality and perform final end-to-end testing.

* **Task 7.10: Frontend Project Setup**
    - [ ] Initialize a basic React/Vue/Angular project in the `frontend/` directory.
    - [ ] Set up basic routing.
* **Task 7.20: Core Frontend Integration**
    - [ ] Implement user registration and login forms, consuming `/auth/register` and `/auth/login`.
    - [ ] Develop pages for browsing movies, series, and live channels, consuming `/ondemand/*` and `/livetv/*` endpoints.
    - [ ] Integrate the global search bar, consuming `/search/global`.
* **Task 7.30: Playback Integration**
    - [ ] Implement video player (placeholder) that can use `playback_url` from `/play/*` endpoints.
* **Task 7.40: End-to-End Testing & Demo Preparation**
    - [ ] Execute full end-to-end tests covering all critical user flows.
    - [ ] Ensure all services function correctly together.
    - [ ] Prepare demonstration scenarios.