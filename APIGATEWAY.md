# ---

**API Gateway Design Document: TV Streaming Backend**

## **1\. Introduction**

This document details the design and implementation of the API Gateway for the TV Streaming Backend Application. In a microservices architecture, an API Gateway serves as the single, centralized entry point for all client requests, abstracting the complexity of the underlying distributed system from the clients.

## **2\. Purpose and Responsibilities**

The API Gateway is a critical component responsible for a range of functionalities that ensure efficient, secure, and manageable interaction between client applications and the backend microservices. Its primary responsibilities include:

* **Single Entry Point:** Provides a unified URL for all client applications (Web, Mobile, TV apps, Admin Dashboard) to interact with the backend, simplifying client-side configuration.  
* **Request Routing:** Directs incoming client requests to the appropriate backend microservice based on predefined routing rules (e.g., URL paths).  
* **Authentication:** Centralizes user authentication by validating JWTs or other authentication credentials present in incoming requests. This offloads authentication logic from individual microservices.  
* **Authorization (Role-Based Access Control \- RBAC):** Enforces access control policies by checking the authenticated user's roles and permissions against the requested resource or endpoint. This is particularly crucial for distinguishing between regular user and administrative access.  
* **Cross-Cutting Concerns:** Acts as a centralized point for implementing other cross-cutting concerns such as:  
  * **Rate Limiting:** Protecting backend services from excessive requests.  
  * **Logging & Monitoring:** Centralizing request logging for observability.  
  * **Request/Response Transformation (Optional):** Modifying requests or responses on the fly if needed (e.g., for compatibility with older clients).  
  * **Load Balancing (Implicit within Docker Compose):** In a scaled environment, an external load balancer would distribute traffic to multiple API Gateway instances, which then distributes to multiple microservice instances.

## **3\. Architectural Placement**

The API Gateway sits as the outermost layer of the backend, acting as a facade to the microservices. Clients never directly interact with the individual microservices.

\+---------------------+  
| Client Applications |  
| (Web, Mobile, TV)   |  
\+---------------------+  
           |  
           v  
\+---------------------+  
| API Gateway Service | (FastAPI Application)  
|  (api\_gateway\_service)  
\+---------------------+  
  |      |      |  
  v      v      v  
\+----------+ \+----------+ \+----------+  
| User     | | On-Demand| | Rights   |  
| Mgmt     | | Video    | | Mgmt     |  
| Service  | | Service  | | Service  |  ... (Other Microservices)  
\+----------+ \+----------+ \+----------+

## **4\. Internal Mechanism (FastAPI Implementation)**

The API Gateway will be implemented as a dedicated FastAPI application (api\_gateway\_service) within the Docker Compose setup.

### **4.1. Request Handling Flow**

1. **Receive Request:** The api\_gateway\_service receives an HTTP request from a client (e.g., GET /ondemand/movies).  
2. **Authentication:**  
   * It extracts the JWT from the Authorization: Bearer \<token\> header.  
   * It validates the JWT's signature, expiry, and basic integrity. For a demonstrator, it might decode the JWT locally to extract claims (e.g., user\_id, roles). In a production system, it might make an internal call to the **Authentication Service** for robust token validation and user details retrieval.  
   * If the token is invalid or missing, it returns 401 Unauthorized.  
3. **Authorization (RBAC):**  
   * Based on the validated user's roles (e.g., from JWT claims) and the requested URL path, the Gateway determines if the user is permitted to access the resource.  
   * **Admin Endpoints:** If the path starts with /admin/, the Gateway explicitly checks for an "admin" role. If the user lacks this role, it returns 403 Forbidden.  
   * This ensures that no request to an /admin endpoint can ever reach the backend microservice unless the user is properly authenticated *and* authorized as an administrator.  
4. **Routing Logic:**  
   * The Gateway's FastAPI routes are configured to capture incoming paths using a "catch-all" parameter (e.g., /{path:path}).  
   * It inspects the initial segment of the URL path (e.g., /users, /ondemand, /admin/users) to determine which internal microservice is responsible for handling that specific resource.  
   * It constructs the internal URL for the target microservice using its Docker Compose service name (e.g., http://user\_management\_service:8000/users/me).  
5. **Internal Request Forwarding:**  
   * The Gateway uses an asynchronous HTTP client (like httpx) to forward the client's original request (including method, headers, query parameters, and request body) to the appropriate internal microservice.  
   * Crucially, the Gateway will often pass along validated user information (e.g., user\_id, roles) to the downstream microservice, typically via custom HTTP headers. This allows the microservice to perform its own granular internal authorization checks (defense-in-depth).  
6. **Response Handling:**  
   * The Gateway receives the response from the internal microservice.  
   * It may perform any necessary response transformations (e.g., standardizing error formats) before sending the response back to the original client.

### **4.2. Python Code Sample for API Gateway (backend/api\_gateway\_service/src/main.py)**

This code demonstrates the core routing, authentication placeholder, and request forwarding logic within the FastAPI API Gateway service.

Python

import os  
import httpx  
import jwt  
from fastapi import FastAPI, Request, HTTPException, status, Depends  
from fastapi.responses import JSONResponse  
from typing import Dict, Any, Optional, List

\# Initialize FastAPI app  
app \= FastAPI(title="TV Streaming API Gateway")

\# Initialize HTTPX client for making internal requests to microservices  
\# Use a global client for connection pooling  
internal\_http\_client \= httpx.AsyncClient()

\# Load microservice URLs from environment variables  
\# These environment variables will be set in docker-compose.yml  
USER\_MANAGEMENT\_SERVICE\_URL \= os.getenv("USER\_MANAGEMENT\_SERVICE\_URL", "http://user\_management\_service:8000")  
AUTHENTICATION\_SERVICE\_URL \= os.getenv("AUTHENTICATION\_SERVICE\_URL", "http://authentication\_service:8000")  
ONDEMAND\_SERVICE\_URL \= os.getenv("ONDEMAND\_SERVICE\_URL", "http://ondemand\_service:8000")  
LIVE\_TV\_SERVICE\_URL \= os.getenv("LIVE\_TV\_SERVICE\_URL", "http://live\_tv\_service:8000")  
RIGHTS\_MANAGEMENT\_SERVICE\_URL \= os.getenv("RIGHTS\_MANAGEMENT\_SERVICE\_URL", "http://rights\_management\_service:8000")  
GLOBAL\_SEARCH\_SERVICE\_URL \= os.getenv("GLOBAL\_SEARCH\_SERVICE\_URL", "http://global\_search\_service:8000")

\# JWT Configuration (should come from env variables in production)  
\# This JWT\_SECRET\_KEY must match the one used by the Authentication Service  
JWT\_SECRET\_KEY \= os.getenv("JWT\_SECRET\_KEY", "your\_super\_secret\_jwt\_key\_from\_auth\_service")  
JWT\_ALGORITHM \= os.getenv("JWT\_ALGORITHM", "HS256")

\# \--- Authentication and Authorization Dependencies \---

async def get\_current\_user\_from\_token(request: Request) \-\> Dict\[str, Any\]:  
    """  
    Dependency to authenticate user via JWT token and extract user details and roles.  
    This is a simplified version. In a real app, you might call the Authentication Service  
    to validate the token and fetch fresh user data.  
    """  
    auth\_header \= request.headers.get("Authorization")  
    if not auth\_header or not auth\_header.startswith("Bearer "):  
        raise HTTPException(  
            status\_code=status.HTTP\_401\_UNAUTHORIZED,  
            detail="Authorization header missing or malformed",  
            headers={"WWW-Authenticate": "Bearer"},  
        )

    token \= auth\_header.split(" ")\[1\]  
    try:  
        \# Decode the JWT. Ensure the secret key and algorithm match your Authentication Service.  
        payload \= jwt.decode(token, JWT\_SECRET\_KEY, algorithms=\[JWT\_ALGORITHM\])  
        user\_id: str \= payload.get("sub")  
        roles: List\[str\] \= payload.get("roles", \[\]) \# Assuming roles are in JWT payload  
        if user\_id is None:  
            raise HTTPException(status\_code=status.HTTP\_401\_UNAUTHORIZED, detail="Invalid token payload")  
          
        \# Return user details including roles, which can be used for authorization  
        return {"user\_id": user\_id, "roles": roles, "raw\_auth\_header": auth\_header}  
    except jwt.PyJWTError:  
        raise HTTPException(status\_code=status.HTTP\_401\_UNAUTHORIZED, detail="Could not validate credentials")

def require\_admin\_role(current\_user: Dict\[str, Any\] \= Depends(get\_current\_user\_from\_token)):  
    """  
    Dependency to check if the authenticated user has an 'admin' role.  
    """  
    if "admin" not in current\_user.get("roles", \[\]):  
        raise HTTPException(status\_code=status.HTTP\_403\_FORBIDDEN, detail="Admin access required")  
    return current\_user

\# \--- Generic Request Forwarding Function \---

async def forward\_request(  
    request: Request,  
    service\_base\_url: str,  
    path: str,  
    current\_user: Optional\[Dict\[str, Any\]\] \= None \# Optional for public endpoints  
):  
    """  
    Forwards the incoming request to the specified microservice.  
    """  
    internal\_url \= f"{service\_base\_url}/{path}"  
      
    \# Prepare headers to pass downstream. Include original auth header or user info.  
    headers \= {key: value for key, value in request.headers.items()}  
    if current\_user:  
        \# Pass the original Authorization header  
        if "raw\_auth\_header" in current\_user:  
             headers\["Authorization"\] \= current\_user\["raw\_auth\_header"\]  
        \# Optionally, pass structured user info as custom headers for defense-in-depth  
        headers\["X-User-ID"\] \= current\_user\["user\_id"\]  
        headers\["X-User-Roles"\] \= ",".join(current\_user\["roles"\])

    try:  
        \# Read the request body only if the method typically has one  
        request\_body \= None  
        if request.method in \["POST", "PUT", "PATCH"\]:  
            request\_body \= await request.body() \# Read raw body

        \# Forward the request  
        response \= await internal\_http\_client.request(  
            method=request.method,  
            url=internal\_url,  
            headers=headers,  
            params=request.query\_params,  
            content=request\_body, \# Pass raw content  
            \# files=await request.form() if "multipart/form-data" in request.headers.get("Content-Type", "") else None,  
            timeout=30.0 \# Define a timeout for internal calls  
        )  
        response.raise\_for\_status() \# Raise HTTPException for 4xx/5xx responses from downstream

        \# Return the response from the microservice directly  
        return JSONResponse(content=response.json(), status\_code=response.status\_code)

    except httpx.HTTPStatusError as e:  
        \# Catch HTTP errors from downstream services and propagate  
        return JSONResponse(  
            content={"detail": e.response.json().get("detail", "Internal service error")},  
            status\_code=e.response.status\_code  
        )  
    except httpx.RequestError as e:  
        \# Catch network or connection errors  
        raise HTTPException(  
            status\_code=status.HTTP\_503\_SERVICE\_UNAVAILABLE,  
            detail=f"Service unavailable: {e}"  
        )  
    except Exception as e:  
        \# Catch any other unexpected errors  
        raise HTTPException(  
            status\_code=status.HTTP\_500\_INTERNAL\_SERVER\_ERROR,  
            detail=f"Gateway internal error: {e}"  
        )

\# \--- API Gateway Routes \---

\# Public Authentication Endpoints (no auth required at gateway for these)  
@app.post("/auth/{path:path}")  
async def route\_auth\_public(request: Request, path: str):  
    return await forward\_request(request, AUTHENTICATION\_SERVICE\_URL, f"auth/{path}")

\# Client-Facing API Endpoints (require authentication)  
@app.api\_route("/users/{path:path}", methods=\["GET", "POST", "PUT", "DELETE"\])  
async def route\_users(request: Request, path: str, current\_user: Dict\[str, Any\] \= Depends(get\_current\_user\_from\_token)):  
    return await forward\_request(request, USER\_MANAGEMENT\_SERVICE\_URL, f"users/{path}", current\_user)

@app.api\_route("/ondemand/{path:path}", methods=\["GET", "POST", "PUT", "DELETE"\])  
async def route\_ondemand(request: Request, path: str, current\_user: Dict\[str, Any\] \= Depends(get\_current\_user\_from\_token)):  
    return await forward\_request(request, ONDEMAND\_SERVICE\_URL, f"ondemand/{path}", current\_user)

@app.api\_route("/livetv/{path:path}", methods=\["GET", "POST", "PUT", "DELETE"\])  
async def route\_livetv(request: Request, path: str, current\_user: Dict\[str, Any\] \= Depends(get\_current\_user\_from\_token)):  
    return await forward\_request(request, LIVE\_TV\_SERVICE\_URL, f"livetv/{path}", current\_user)

@app.api\_route("/subscriptions/{path:path}", methods=\["GET", "POST", "PUT", "DELETE"\])  
async def route\_subscriptions(request: Request, path: str, current\_user: Dict\[str, Any\] \= Depends(get\_current\_user\_from\_token)):  
    return await forward\_request(request, RIGHTS\_MANAGEMENT\_SERVICE\_URL, f"subscriptions/{path}", current\_user)

@app.api\_route("/play/{path:path}", methods=\["GET"\]) \# Playback typically GET  
async def route\_play(request: Request, path: str, current\_user: Dict\[str, Any\] \= Depends(get\_current\_user\_from\_token)):  
    \# Note: The Rights Management Service itself will be called by the On-Demand/Live TV service  
    \# to perform the final rights check before returning the playback URL.  
    \# The API Gateway just ensures the user is authenticated here.  
    if path.startswith("ondemand/"):  
        return await forward\_request(request, ONDEMAND\_SERVICE\_URL, f"play/{path}", current\_user)  
    elif path.startswith("live/"):  
        return await forward\_request(request, LIVE\_TV\_SERVICE\_URL, f"play/{path}", current\_user)  
    else:  
        raise HTTPException(status\_code=status.HTTP\_404\_NOT\_FOUND, detail="Playback path not recognized")

@app.api\_route("/search/global", methods=\["GET"\]) \# Global search is typically GET  
async def route\_global\_search(request: Request, current\_user: Optional\[Dict\[str, Any\]\] \= Depends(get\_current\_user\_from\_token)):  
    \# Note: Global Search might be accessible without auth, or provide different results based on auth.  
    \# The 'current\_user' dependency is optional here, just to demonstrate it can receive auth if present.  
    return await forward\_request(request, GLOBAL\_SEARCH\_SERVICE\_URL, "search/global", current\_user)

\# Admin API Endpoints (require admin role)  
@app.api\_route("/admin/{path:path}", methods=\["GET", "POST", "PUT", "DELETE"\])  
async def route\_admin(request: Request, path: str, current\_admin\_user: Dict\[str, Any\] \= Depends(require\_admin\_role)):  
    \# Determine which admin module the request belongs to based on the 'path'  
    if path.startswith("users/"):  
        service\_url \= USER\_MANAGEMENT\_SERVICE\_URL  
        internal\_path\_segment \= "admin/users/" \+ path\[len("users/"):\]  
    elif path.startswith("ondemand/"):  
        service\_url \= ONDEMAND\_SERVICE\_URL  
        internal\_path\_segment \= "admin/ondemand/" \+ path\[len("ondemand/"):\]  
    elif path.startswith("livetv/"):  
        service\_url \= LIVE\_TV\_SERVICE\_URL  
        internal\_path\_segment \= "admin/livetv/" \+ path\[len("livetv/"):\]  
    elif path.startswith("rights/"):  
        service\_url \= RIGHTS\_MANAGEMENT\_SERVICE\_URL  
        internal\_path\_segment \= "admin/rights/" \+ path\[len("rights/"):\]  
    else:  
        raise HTTPException(status\_code=status.HTTP\_404\_NOT\_FOUND, detail="Admin path not recognized")

    return await forward\_request(request, service\_url, internal\_path\_segment, current\_admin\_user)

\# \--- Health Check (Optional but Recommended) \---  
@app.get("/health")  
async def health\_check():  
    return {"status": "ok", "message": "API Gateway is running"}

### **4.3. Internal Service Communication**

* **Service Discovery:** Within the Docker Compose network, microservices can be reached by their service names (as defined in docker-compose.yml). For example, the API Gateway accesses the User Management Service at http://user\_management\_service:8000. These internal URLs are passed to the Gateway via environment variables (USER\_MANAGEMENT\_SERVICE\_URL, etc.).  
* **Configuration:** The internal URLs of the backend microservices are configured as environment variables within the api\_gateway\_service Docker container, making the Gateway easily adaptable to different deployment environments.

### **4.4. Error Standardization**

The API Gateway is responsible for catching errors originating from backend microservices and transforming them into a consistent, user-friendly error format before returning them to the client. This ensures a predictable error experience for developers integrating with the API. The forward\_request function in the sample above demonstrates how httpx.HTTPStatusError can be caught and its details propagated.

## **5\. Key Features and Advantages**

* **Simplifies Client-Side Development:** Clients only need to know one base URL for the entire backend, regardless of how many microservices are behind it.  
* **Centralized Security:** Authentication and core authorization logic are handled in one place, reducing redundancy and ensuring consistent security policies across all API calls.  
* **Reduced Microservice Complexity:** Individual microservices can focus solely on their specific business logic, without needing to implement authentication, routing, or other gateway-level concerns directly for external requests.  
* **Improved Observability:** Centralized logging at the Gateway provides a comprehensive view of all incoming requests and their initial processing.  
* **Enhanced Maintainability:** Changes to backend microservices (e.g., adding a new service, refactoring an existing one) can often be managed within the Gateway's routing rules without requiring changes to client applications.

## **6\. Considerations for Demonstrator**

For the initial technology demonstrator, the API Gateway implementation will prioritize:

* **Basic Routing:** Direct path-based routing to microservices.  
* **Essential Authentication/Authorization:** Robust JWT validation and clear role-based access for /admin endpoints.  
* **Standard Error Handling:** Catching and re-packaging common HTTP errors.

As the project evolves beyond a demonstrator, the API Gateway could be extended to include:

* Advanced request/response transformations.  
* Advanced caching mechanisms.  
* More sophisticated load balancing and circuit breaking.  
* Integration with service mesh technologies.

## **7\. Docker Compose Integration**

The api\_gateway\_service will be defined as a distinct service in docker-compose.yml, typically exposed on a standard HTTP/HTTPS port (e.g., 80 or 443). All other backend microservices will *not* have their ports directly exposed to the host machine, making them only accessible internally via the API Gateway within the Docker network.

YAML

\# Simplified docker-compose.yml snippet focusing on API Gateway

services:  
  \# The API Gateway \- exposed to the outside world  
  api\_gateway\_service:  
    build:  
      context: ./backend/api\_gateway\_service  
      dockerfile: Dockerfile  
    ports:  
      \- "80:8000" \# Maps host port 80 to container port 8000 (FastAPI default)  
    environment:  
      \# Internal URLs for dependent services. Use Docker service names.  
      USER\_MANAGEMENT\_SERVICE\_URL: http://user\_management\_service:8000  
      AUTHENTICATION\_SERVICE\_URL: http://authentication\_service:8000  
      ONDEMAND\_SERVICE\_URL: http://ondemand\_service:8000  
      LIVE\_TV\_SERVICE\_URL: http://live\_tv\_service:8000  
      RIGHTS\_MANAGEMENT\_SERVICE\_URL: http://rights\_management\_service:8000  
      GLOBAL\_SEARCH\_SERVICE\_URL: http://global\_search\_service:8000  
      \# JWT secret key needed by Gateway to validate tokens. Must match Auth Service's secret.  
      JWT\_SECRET\_KEY: ${JWT\_SECRET\_KEY} \# Best practice: load from .env or Docker secrets  
      JWT\_ALGORITHM: ${JWT\_ALGORITHM}  
    depends\_on:  
      \# Ensure all downstream services are started before the gateway  
      user\_management\_service: {condition: service\_started}  
      authentication\_service: {condition: service\_started}  
      ondemand\_service: {condition: service\_started}  
      live\_tv\_service: {condition: service\_started}  
      rights\_management\_service: {condition: service\_started}  
      global\_search\_service: {condition: service\_started}  
      db: {condition: service\_healthy} \# Gateway might need DB if it stores anything directly (e.g., rate limits)  
    restart: on-failure

  \# Example of an internal service (not exposed directly)  
  user\_management\_service:  
    build:  
      context: ./backend/user\_management\_service  
      dockerfile: Dockerfile  
    \# No 'ports' mapping here, only accessible internally by api\_gateway\_service  
    environment:  
      DATABASE\_URL: postgresql://user:password@db:5432/tv\_streaming\_db  
      \# JWT\_SECRET\_KEY (if user service also needs to decode JWT for internal logic)  
      JWT\_SECRET\_KEY: ${JWT\_SECRET\_KEY}  
      JWT\_ALGORITHM: ${JWT\_ALGORITHM}  
    depends\_on:  
      db: {condition: service\_healthy}  
    restart: on-failure

  \# ... (other internal services like authentication\_service, ondemand\_service, etc.)

  \# Database Service (also not directly exposed to external clients)  
  db:  
    image: postgres:16-alpine  
    restart: always  
    environment:  
      POSTGRES\_DB: tv\_streaming\_db  
      POSTGRES\_USER: user  
      POSTGRES\_PASSWORD: password  
    volumes:  
      \- pg\_data:/var/lib/postgresql/data  
    healthcheck:  
      test: \["CMD-SHELL", "pg\_isready \-U user \-d tv\_streaming\_db"\]  
      interval: 5s  
      timeout: 5s  
      retries: 5

volumes:  
  pg\_data:  
  \# ... other volumes

**Sources**  
1\. [https://github.com/33may/vbti\_intern](https://github.com/33may/vbti_intern)  
2\. [https://github.com/ashutoshramteke/lightspeed-backend](https://github.com/ashutoshramteke/lightspeed-backend)  
3\. [https://github.com/notarious2/fastapi-chat](https://github.com/notarious2/fastapi-chat)  
4\. [https://github.com/devthuan/coffee-fastapi-react](https://github.com/devthuan/coffee-fastapi-react)