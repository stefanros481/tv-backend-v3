# ---

**TV Streaming Backend Application: Design Solution Document**

Date: June 20, 2025  
Location: Stavanger Municipality, Rogaland, Norway

## **1\. Introduction**

This document outlines the design and architecture of the TV Streaming Backend Application, which will initially serve as a technology demonstrator. The application will be developed using a microservices design pattern with FastAPI, Python, and Docker, focusing on scalability, maintainability, and a clear separation of concerns.

## **2\. High-Level Architecture**

The system adopts a microservices architecture, with an API Gateway acting as the single entry point for all client applications.

\+---------------------+         \+---------------------+         \+---------------------+  
| Client Applications | \<-----\> | API Gateway (FastAPI)| \<-----\> | Backend Microservices|  
| (TV, Web, Mobile)   |         |                     |         | (FastAPI Apps)      |  
\+---------------------+         \+---------------------+         \+---------------------+  
           ^                                 ^  
           |                                 |  
\+---------------------+         \+---------------------+  
| Admin Dashboard     | \<-----\> | API Gateway         |  
\+---------------------+         | (Admin Access)      |  
                                 \+---------------------+

## **3\. Core Components (Backend Microservices)**

The backend is composed of the following independent FastAPI microservices, each running in its own Docker container and communicating via REST APIs:

1. **User Management Service:**  
   * **Purpose:** Manages customer accounts, including registration, profile creation, and core customer data.  
   * **Models:** Customer, Profile.  
   * **Database:** Own tables within the shared PostgreSQL instance.  
2. **Authentication Service:**  
   * **Purpose:** Handles user authentication (login, JWT generation), token validation, and token refresh.  
   * **Functionality:** Interacts with the User Management Service for credential verification during login.  
   * **Database:** Primarily stateless; may use Redis for JWT blacklisting/revocation if needed.  
3. **On-Demand Video Service:**  
   * **Purpose:** Manages the catalog of on-demand video titles (movies, series, episodes) and their associated metadata (genres, actors, directors).  
   * **Models:** Movie, Series, Episode, Genre, Person.  
   * **Database:** Own tables within the shared PostgreSQL instance for metadata. Actual video files are stored externally (e.g., AWS S3).  
4. **Live TV Service:**  
   * **Purpose:** Manages the list of available live TV channels and their Electronic Program Guide (EPG) data.  
   * **Models:** Channel, EPGEntry.  
   * **Database:** Own tables within the shared PostgreSQL instance for metadata. Live streams are managed by external infrastructure.  
5. **Rights Management Service:**  
   * **Purpose:** Controls content access based on various models: Subscription Video On-Demand (SVOD), Transactional Video On-Demand (TVOD \- purchase and rental), and Live TV channel subscriptions.  
   * **Models:** SubscriptionPlan, PurchasedContent, RentedContent, ContentAccessRule.  
   * **Logic:** The core /rights/check\_access logic verifies user entitlements by checking active subscriptions, purchase records, and valid rental periods against requested content or channels.  
   * **Database:** Own tables within the shared PostgreSQL instance.  
6. **Global Search Service:**  
   * **Purpose:** Provides a unified, low-latency global search across all metadata for continuous "search-as-you-type" functionality.  
   * **Indexing:** Maintains a dedicated search index (e.g., Elasticsearch/OpenSearch) that is asynchronously updated by other services upon data changes.  
   * **API:** Serves search queries (e.g., /search/global).  
7. **API Gateway Service:**  
   * **Purpose:** Acts as the single entry point for all external client requests. It routes requests to the appropriate backend microservice, centralizes authentication, and enforces authorization rules (especially for admin access).  
   * **Technology:** Implemented as a dedicated FastAPI application.  
   * **Communication:** Makes internal HTTP requests to backend microservices using their Docker Compose service names.

## **4\. API Design Principles**

* **RESTful APIs:** Adhere to RESTful principles using JSON data format and standard HTTP methods.  
* **Clear Endpoints:** Intuitive and well-documented API paths.  
* **Input Validation:** Robust validation using Pydantic.  
* **Security:** JWT-based authentication and Role-Based Access Control (RBAC).  
* **Error Handling:** Meaningful error responses with appropriate HTTP status codes.  
* **Efficiency:** Implement pagination, filtering, and rate limiting.

## **5\. API Endpoint Structure**

API endpoints are clearly segregated and managed by the API Gateway:

### **5.1. Client API Endpoints (via API Gateway)**

These endpoints are exposed through the api\_gateway\_service and consumed by end-user applications.

* **Authentication:**  
  * POST /auth/register  
  * POST /auth/login  
* **User Profiles (via User Management Service):**  
  * GET /users/me  
  * GET /users/profiles (List & Create)  
  * GET/PUT/DELETE /users/profiles/{profile\_id}  
* **On-Demand Content (via On-Demand Video Service):**  
  * GET /ondemand/movies (List & Details)  
  * GET /ondemand/series (List & Details)  
  * GET /ondemand/series/{series\_id}/episodes (List episodes for a series)  
  * GET /ondemand/episodes/{episode\_id} (Episode details)  
* **Live TV (via Live TV Service):**  
  * GET /livetv/channels (List & Details)  
  * GET /livetv/epg (Retrieve EPG data)  
* **Subscriptions & Purchases/Rentals (via Rights Management Service):**  
  * GET /subscriptions (List available plans)  
  * GET /users/subscriptions (Get active subscriptions)  
  * POST /users/subscriptions (Subscribe to a plan)  
  * DELETE /users/subscriptions (Cancel subscription)  
  * POST /ondemand/purchase/{content\_id} (Purchase content)  
  * GET /users/purchases (List purchased content)  
  * POST /ondemand/rent/{content\_id} (Rent content with duration)  
  * GET /users/rentals (List rented content and expiry dates)  
* **Content Playback (via respective content service, after Rights Management check):**  
  * GET /play/ondemand/{content\_id} (Initiate playback for on-demand content)  
  * GET /play/live/{channel\_id} (Initiate playback for a live TV channel)  
* **Global Search (via Global Search Service):**  
  * GET /search/global?q={query}\&limit={int}\&offset={int}\&type={str} (Unified search with continuous search support)

### **5.2. Admin API Endpoints (via API Gateway)**

These endpoints are also exposed through the api\_gateway\_service but are prefixed with /admin and are protected by **Role-Based Access Control (RBAC)**, ensuring only authenticated administrators can access them.

* **User Management (Admin) (via User Management Service):**  
  * GET /admin/users (List & Details)  
  * PUT /admin/users/{user\_id} (Update user details)  
  * DELETE /admin/users/{user\_id} (Delete user)  
* **On-Demand Content Management (Admin) (via On-Demand Video Service):**  
  * GET/POST/PUT/DELETE /admin/ondemand/movies (CRUD for movies)  
  * GET/POST/PUT/DELETE /admin/ondemand/series (CRUD for series)  
  * GET/POST/PUT/DELETE /admin/ondemand/episodes (CRUD for episodes)  
* **Live TV Channel Management (Admin) (via Live TV Service):**  
  * GET/POST/PUT/DELETE /admin/livetv/channels (CRUD for channels)  
  * POST /admin/livetv/epg/upload (Upload/update EPG data)  
* **Rights Management (Admin) (via Rights Management Service):**  
  * GET/POST/PUT/DELETE /admin/rights/plans (CRUD for subscription plans)  
  * GET/POST/PUT/DELETE /admin/rights/rules (CRUD for content access rules, if applicable)

## **6\. Technology Stack**

* **Backend Framework:** FastAPI (Python) \- For building high-performance, asynchronous APIs.  
* **API Gateway:** FastAPI (dedicated service) \- For centralized routing, authentication, and authorization.  
* **Database (Relational):** PostgreSQL \- For structured data across all microservices. Each service will manage its own tables/schema within this single instance for demonstrator simplicity.  
* **Search Engine:** Elasticsearch / OpenSearch \- For the Global Search Service's inverted index.  
* **ORM:** SQLAlchemy (for PostgreSQL).  
* **Authentication:** PyJWT (for JWT implementation), passlib/bcrypt (for password hashing).  
* **Asynchronous Tasks/Message Broker (Optional but Recommended):** Redis (as a Celery broker) \- For background tasks like indexing updates for the Global Search Service, ensuring non-blocking operations.  
* **HTTP Client (for inter-service calls):** httpx (asynchronous).  
* **Python Dependency Management:** uv from Astral \- For fast and reliable dependency resolution and package installation.  
* **Testing:** Pytest for unit and integration tests.

## **7\. Development Workflow**

* **Methodology:** Agile development with iterative sprints.  
* **Version Control:** Git, with a **Single Repository (Monorepo)** setup for the entire project (backend microservices, frontend, docker-compose.yml, shared libraries). This simplifies initial setup, coordination, and CI/CD for a demonstrator.  
* **Code Reviews:** Mandatory for quality assurance.  
* **Continuous Integration/Continuous Deployment (CI/CD):** Implement automated pipelines for building, testing, and deploying the services.  
* **Containerization:** Docker is used for packaging each microservice into an isolated container.  
* **Orchestration (Local/Dev):** Docker Compose is used to define and run the multi-service application locally, enabling independent building and restarting of individual services.  
* **Python Dependency Management:** Each microservice will have its own pyproject.toml file to define its specific dependencies. uv will be used to manage these dependencies efficiently.

### **7.1. Local Development Environment Setup (VS Code)**

* **IDE:** VS Code.  
* **Recommended VS Code Extensions:**  
  * **Python Extension:** For language support, debugging, and testing.  
  * **Docker Extension:** For managing Docker containers, images, and volumes directly within VS Code.  
  * **Remote \- Containers Extension:** Highly recommended for opening the monorepo inside a development container, ensuring a consistent and isolated development environment matching the Docker images.  
  * **SQLAlchemy Extension (if available):** For database ORM support.  
  * **Code Formatters:** Black or Ruff (configured for format-on-save).  
  * **Linters:** Pylint or Flake8.  
* **Debugging:** Configure .vscode/launch.json for remote debugging into individual running Docker containers.  
* **Multi-root Workspaces:** Use VS Code's multi-root workspace feature to easily manage codebases for multiple microservices within a single VS Code window.

## **8\. Security Considerations**

* **HTTPS:** Enforce HTTPS for all API communication to encrypt data in transit.  
* **Input Validation:** Thoroughly validate all incoming data using Pydantic to prevent injection attacks and ensure data integrity.  
* **Authentication and Authorization:** Implement strong JWT-based authentication and RBAC at the API Gateway level for centralized control, with reinforcement checks within individual microservices (defense-in-depth).  
* **Password Security:** Use robust password hashing algorithms (e.g., bcrypt).  
* **Protection Against Common Web Vulnerabilities:** Implement measures to prevent CSRF, XSS, and other common vulnerabilities.  
* **Secrets Management:** Securely manage API keys, database credentials, and JWT secrets (e.g., via Docker secrets in production, environment variables for demonstrator).  
* **Rate Limiting:** Implement rate limiting, especially on the API Gateway and Global Search Service, to protect against abuse and ensure service availability.  
* **Regular Security Audits:** Conduct regular security audits (even for a demonstrator) to identify and address potential vulnerabilities.

## **9\. Scalability and Performance**

* **Asynchronous Operations:** Leverage FastAPI's asynchronous capabilities for all I/O-bound operations.  
* **Database Optimization:** Optimize database queries, use appropriate indexing, and manage connection pools effectively.  
* **Caching:** Implement caching mechanisms (e.g., Redis) at the API Gateway level and within microservices to reduce database/search engine load and improve response times for frequently accessed data.  
* **Load Balancing:** The API Gateway can also act as a load balancer for internal microservice instances. For external traffic, an external load balancer would distribute requests to multiple API Gateway instances.  
* **Horizontal Scaling:** Design microservices to be stateless where possible, allowing them to be horizontally scaled by adding more instances as needed.  
* **CDN (Content Delivery Network):** Utilize a CDN for efficient delivery of actual video content to users, minimizing latency.  
* **Search Engine Optimization:** Configure Elasticsearch/OpenSearch for optimal performance, including sharding, replication, and query optimization, to support low-latency global search.

This comprehensive design provides a solid foundation for developing your TV Streaming Backend Application as a robust, scalable, and secure microservices demonstrator.