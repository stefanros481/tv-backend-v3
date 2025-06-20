# ---

**TV Streaming Backend API Documentation**

## **1\. Introduction**

Welcome to the TV Streaming Backend API documentation. This API provides the interface for client applications (TV apps, web, mobile) and the Admin Dashboard to interact with the TV streaming platform. It is built on a microservices architecture using FastAPI, ensuring high performance, scalability, and modularity.

### **1.1. Base URL**

All API requests should be made to the API Gateway. The base URL for the API in the demonstrator environment is:

http://localhost/

For a deployed environment, this would be your domain, e.g., https://api.yourdomain.com/

### **1.2. Authentication**

The TV Streaming API uses **JSON Web Tokens (JWT)** for authentication.

* **Mechanism:** After successful login, the /auth/login endpoint returns an access\_token (JWT). This token must be included in the Authorization header of subsequent requests.  
* **Header Format:** Authorization: Bearer \<your\_access\_token\>  
* **Token Expiry:** Access tokens have a limited lifetime. Your client application should handle token expiration and use a refresh token mechanism (if implemented) or prompt the user to re-authenticate.  
* **Admin Access:** Administrative endpoints (prefixed with /admin) require an access\_token associated with a user possessing "admin" roles or permissions. The API Gateway enforces this access control.

## **2\. General API Usage**

### **2.1. Request & Response Format**

* All API requests and responses utilize the **JSON** (JavaScript Object Notation) format.  
* Requests with a body (e.g., POST, PUT) must include the Content-Type: application/json header.

### **2.2. HTTP Methods**

* GET: Retrieve resources.  
* POST: Create new resources.  
* PUT: Update existing resources (full replacement).  
* DELETE: Delete resources.

### **2.3. Pagination and Filtering**

List endpoints (e.g., /ondemand/movies, /admin/users) support pagination and filtering via query parameters:

* limit (integer, optional): The maximum number of items to return in a single response. Default is typically 10 or 20\.  
* offset (integer, optional): The number of items to skip from the beginning of the result set. Useful for pagination. Default is 0\.  
* sort\_by (string, optional): Field to sort results by (e.g., title, release\_date).  
* order (string, optional): Sort order (asc for ascending, desc for descending). Default asc.  
* **Filtering:** Specific filter parameters will be noted per endpoint (e.g., genre, year).

### **2.4. Error Handling**

The API uses standard HTTP status codes to indicate the success or failure of a request. In case of an error1 (4xx or 5xx status codes), the API will return a JSON object with details about the error.

**Common Error Response Format:**

JSON

{  
  "detail": "A descriptive error message."  
}

**Common HTTP Status Codes:**

* 200 OK: Request successful.  
* 201 Created: Resource successfully created (for POST requests).  
* 204 No Content: Request successful, but no content to return (e.g., successful DELETE).  
* 400 Bad Request: The request was malformed or invalid.  
* 401 Unauthorized: Authentication is required or has failed.  
* 403 Forbidden: The authenticated user does not have permission to access the resource.  
* 404 Not Found: The requested resource could not be found.  
* 405 Method Not Allowed: The HTTP method used is not supported for this endpoint.  
* 429 Too Many Requests: Rate limit exceeded.  
* 500 Internal Server Error: An unexpected error occurred on the server.

## ---

**3\. API Endpoint Documentation**

### **3.1. Client API Endpoints**

These endpoints are designed for integration with user-facing applications.

#### **3.1.1. Authentication**

* **Service:** Authentication Service (via API Gateway)  
* **POST /auth/register**  
  * **Description:** Registers a new customer account.  
  * **Authentication:** None (public endpoint).  
  * **Request Body:**  
    JSON  
    {  
      "email": "user@example.com",  
      "password": "StrongPassword123\!",  
      "first\_name": "John",  
      "last\_name": "Doe"  
    }

  * **Success Response (201 Created):**  
    JSON  
    {  
      "message": "User registered successfully",  
      "user\_id": "user-uuid-123"  
    }

  * **Error Responses:**  
    * 400 Bad Request: {"detail": "Email already registered"} or {"detail": "Invalid password format"}  
    * 500 Internal Server Error  
* **POST /auth/login**  
  * **Description:** Authenticates a customer and returns a JWT access token.  
  * **Authentication:** None (public endpoint).  
  * **Request Body:**  
    JSON  
    {  
      "email": "user@example.com",  
      "password": "StrongPassword123\!"  
    }

  * **Success Response (200 OK):**  
    JSON  
    {  
      "access\_token": "eyJhbGciOiJIUzI1NiIsInR5c...",  
      "token\_type": "bearer",  
      "expires\_in": 3600 \# seconds  
    }

  * **Error Responses:**  
    * 400 Bad Request: {"detail": "Invalid credentials"}  
    * 500 Internal Server Error

#### **3.1.2. User Profiles**

* **Service:** User Management Service (via API Gateway)  
* **GET /users/me**  
  * **Description:** Retrieves the details of the currently authenticated customer.  
  * **Authentication:** Required (Bearer Token).  
  * **Parameters:** None.  
  * **Success Response (200 OK):**  
    JSON  
    {  
      "id": "user-uuid-123",  
      "email": "user@example.com",  
      "first\_name": "John",  
      "last\_name": "Doe",  
      "created\_at": "2024-01-15T10:00:00Z",  
      "profiles": \[  
        {"id": "profile-uuid-abc", "name": "Main Profile", "avatar\_url": null},  
        {"id": "profile-uuid-def", "name": "Kids Profile", "avatar\_url": "kids.png"}  
      \]  
    }

  * **Error Responses:**  
    * 401 Unauthorized: {"detail": "Not authenticated"}  
    * 404 Not Found: {"detail": "User not found"} (rare, should imply invalid token)  
* **GET /users/profiles**  
  * **Description:** Lists all profiles associated with the currently authenticated customer.  
  * **Authentication:** Required (Bearer Token).  
  * **Parameters:** None.  
  * **Success Response (200 OK):**  
    JSON  
    \[  
      {"id": "profile-uuid-abc", "name": "Main Profile", "avatar\_url": null},  
      {"id": "profile-uuid-def", "name": "Kids Profile", "avatar\_url": "kids.png"}  
    \]

  * **Error Responses:**  
    * 401 Unauthorized

#### **3.1.3. On-Demand Content**

* **Service:** On-Demand Video Service (via API Gateway)  
* **GET /ondemand/movies**  
  * **Description:** Lists available movies. Supports filtering and pagination.  
  * **Authentication:** Optional (authenticated users might get personalized recommendations or rights info).  
  * **Query Parameters:**  
    * genre (string, optional): Filter by genre name (e.g., "Action", "Comedy").  
    * year (integer, optional): Filter by release year.  
    * limit (integer, optional): Max results per page.  
    * offset (integer, optional): Offset for pagination.  
  * **Success Response (200 OK):**  
    JSON  
    {  
      "total": 150,  
      "movies": \[  
        {  
          "id": "movie-uuid-001",  
          "title": "The Quantum Leap",  
          "description": "A thrilling sci-fi adventure...",  
          "release\_date": "2023-05-20",  
          "genres": \["Sci-Fi", "Adventure"\],  
          "director": "Jane Director",  
          "cast": \["Actor A", "Actor B"\],  
          "poster\_url": "https://cdn.example.com/posters/movie001.jpg",  
          "duration\_minutes": 130  
        },  
        // ... more movies  
      \]  
    }

  * **Error Responses:**  
    * 400 Bad Request: {"detail": "Invalid genre"} or {"detail": "Invalid year format"}

#### **3.1.4. Content Playback**

* **Service:** On-Demand Video Service / Live TV Service (via API Gateway, involves Rights Management Service)  
* **GET /play/ondemand/{content\_id}**  
  * **Description:** Initiates playback for a specific on-demand content item (movie or episode). Performs a rights check to ensure the user has access.  
  * **Authentication:** Required (Bearer Token).  
  * **Path Parameters:**  
    * content\_id (string, required): The UUID of the movie or episode to play.  
  * **Logic:** The API Gateway will forward this request to the On-Demand Video Service. This service, in turn, will call the internal Rights Management Service (POST /rights/check\_access) with the user's ID and content\_id. If authorized, it returns the streaming URL; otherwise, it returns a 403 Forbidden.  
  * **Success Response (200 OK):**  
    JSON  
    {  
      "playback\_url": "https://stream.example.com/movie-uuid-001/manifest.m3u8?token=secure\_playback\_token",  
      "drm\_info": {  
        "type": "Widevine",  
        "license\_server\_url": "https://drm.example.com/license"  
      },  
      "content\_type": "movie"  
    }

  * **Error Responses:**  
    * 401 Unauthorized: {"detail": "Not authenticated"}  
    * 403 Forbidden: {"detail": "Access denied: Content not purchased, rented, or not part of your subscription."}  
    * 404 Not Found: {"detail": "Content not found"}  
    * 500 Internal Server Error

#### **3.1.5. Global Search**

* **Service:** Global Search Service (via API Gateway)  
* **GET /search/global**  
  * **Description:** Provides a unified search interface across all metadata (movies, series, episodes, channels, genres, actors, directors). Optimized for continuous "search-as-you-type" functionality.  
  * **Authentication:** Optional (authenticated users might get personalized or access-filtered results).  
  * **Query Parameters:**  
    * q (string, required): The search query string (e.g., "game of thr", "action movie").  
    * limit (integer, optional): Maximum number of results to return (default: 20).  
    * offset (integer, optional): Number of results to skip for pagination (default: 0).  
    * type (string, optional, can be repeated): Filter results by content type (e.g., movie, series, episode, channel).  
    * fields (string, optional, can be repeated): Specify metadata fields to prioritize search within (e.g., title, description, actors).  
  * **Example Request:** GET http://localhost/search/global?q=game of thr\&limit=5\&type=series  
  * **Success Response (200 OK):**  
    JSON  
    {  
      "total\_results": 2,  
      "results": \[  
        {  
          "id": "series-uuid-1",  
          "type": "series",  
          "title": "Game of Thrones",  
          "description": "Nine noble families fight for control over the mythical lands of Westeros.",  
          "thumbnail\_url": "https://example.com/thumbnails/got.jpg",  
          "genres": \["Fantasy", "Drama"\],  
          "release\_year": 2011,  
          "relevance\_score": 0.98  
        },  
        {  
          "id": "episode-uuid-5",  
          "type": "episode",  
          "title": "The Winds of Winter",  
          "series\_title": "Game of Thrones",  
          "season\_number": 6,  
          "episode\_number": 10,  
          "description": "Cersei takes her revenge...",  
          "thumbnail\_url": "https://example.com/thumbnails/got-s6e10.jpg",  
          "relevance\_score": 0.95  
        }  
      \]  
    }

  * **Error Responses:**  
    * 400 Bad Request: {"detail": "Query parameter 'q' is required"}  
    * 500 Internal Server Error: {"detail": "Search service temporarily unavailable"}

### **3.2. Admin API Endpoints**

These endpoints are designed for administrative tasks and are accessed by the Admin Dashboard. They are strictly protected by RBAC at the API Gateway.

#### **3.2.1. User Management (Admin)**

* **Service:** User Management Service (via API Gateway)  
* **GET /admin/users**  
  * **Description:** Lists all users registered on the platform.  
  * **Authentication:** Required (Bearer Token, Admin Role).  
  * **Query Parameters:** limit, offset, email (string, optional, filter by email).  
  * **Success Response (200 OK):**  
    JSON  
    {  
      "total": 100,  
      "users": \[  
        {  
          "id": "user-uuid-123",  
          "email": "admin@example.com",  
          "first\_name": "Admin",  
          "last\_name": "User",  
          "is\_active": true,  
          "roles": \["admin"\]  
        },  
        // ... more users  
      \]  
    }

  * **Error Responses:**  
    * 401 Unauthorized  
    * 403 Forbidden: {"detail": "Admin access required"}  
* **DELETE /admin/users/{user\_id}**  
  * **Description:** Deletes a specific user from the platform.  
  * **Authentication:** Required (Bearer Token, Admin Role).  
  * **Path Parameters:**  
    * user\_id (string, required): The UUID of the user to delete.  
  * **Success Response (204 No Content):** No response body.  
  * **Error Responses:**  
    * 401 Unauthorized, 403 Forbidden  
    * 404 Not Found: {"detail": "User not found"}

#### **3.2.2. On-Demand Content Management (Admin)**

* **Service:** On-Demand Video Service (via API Gateway)  
* **POST /admin/ondemand/movies**  
  * **Description:** Adds a new movie to the platform's catalog.  
  * **Authentication:** Required (Bearer Token, Admin Role).  
  * **Request Body:**  
    JSON  
    {  
      "title": "The New Epic",  
      "description": "A thrilling new movie.",  
      "release\_date": "2025-01-01",  
      "genres": \["Action", "Sci-Fi"\],  
      "director\_id": "person-uuid-dir1",  
      "cast\_ids": \["person-uuid-actor1", "person-uuid-actor2"\],  
      "poster\_url": "https://cdn.example.com/new\_epic.jpg",  
      "duration\_minutes": 150,  
      "video\_file\_path": "/path/to/movie/file.mp4" \# Internal path for processing  
    }

  * **Success Response (201 Created):**  
    JSON  
    {  
      "id": "movie-uuid-newly-created",  
      "title": "The New Epic",  
      "status": "pending\_processing" \# Or "ready" if processed instantly  
    }

  * **Error Responses:**  
    * 400 Bad Request: {"detail": "Missing required fields"} or {"detail": "Invalid genre provided"}  
    * 401 Unauthorized, 403 Forbidden

## ---

**4\. How to Use the API (Developer Guide)**

This section guides developers through the typical workflow of interacting with the TV Streaming API.

### **4.1. Step 1: Obtain API Access**

* **Register:** To get started, your application (or an admin user) must register an account by calling POST /auth/register.  
* **Login:** After registration, log in using POST /auth/login with the registered email and password. This will return your access\_token.

### **4.2. Step 2: Authenticate Requests**

* Store the access\_token securely on the client-side (e.g., in localStorage for web apps, secure storage for mobile apps).  
* For every subsequent API call (except public ones like register/login), include the Authorization header with the Bearer token: Authorization: Bearer YOUR\_ACCESS\_TOKEN

### **4.3. Step 3: Browse Content**

* **Movies:** Use GET /ondemand/movies to list available movies. You can filter by genre, year, and paginate using limit and offset.  
* **Series:** Use GET /ondemand/series to list series, and GET /ondemand/series/{series\_id}/episodes to get episodes for a specific series.  
* **Live TV:** Use GET /livetv/channels to see available live channels.  
* **Global Search:** Implement continuous search by sending GET /search/global?q=\<user\_input\> requests as the user types, adjusting limit and offset as needed.

### **4.4. Step 4: Manage User Profiles**

* After logging in, a user can manage their profiles using GET /users/profiles and POST /users/profiles.  
* Specific profiles can be retrieved, updated, or deleted using GET/PUT/DELETE /users/profiles/{profile\_id}.

### **4.5. Step 5: Purchase, Rent, or Subscribe**

* **View Plans:** Call GET /subscriptions to see available subscription plans (SVOD, Live TV packages).  
* **Subscribe:** Use POST /users/subscriptions to subscribe the current user to a chosen plan.  
* **Purchase On-Demand:** For TVOD (Purchase), use POST /ondemand/purchase/{content\_id}.  
* **Rent On-Demand:** For TVOD (Rental), use POST /ondemand/rent/{content\_id} (remember to specify rental duration).  
* **View User's Content:** Check GET /users/purchases and GET /users/rentals to see content the user owns or currently rents.

### **4.6. Step 6: Play Content**

* To initiate playback for any content (on-demand or live TV), use the /play endpoints:  
  * GET /play/ondemand/{content\_id}  
  * GET /play/live/{channel\_id}  
* **Important:** These endpoints perform a real-time rights check via the Rights Management Service. Ensure the user is authenticated and has the necessary entitlement (subscription, purchase, or valid rental) for the requested content. If authorized, the response will provide a playback\_url and potentially DRM information.

### **4.7. Step 7: Administer the Platform (for Admin Users)**

* Admin users must log in with credentials associated with an "admin" role.  
* All administrative tasks are performed via endpoints prefixed with /admin.  
* Example: POST /admin/ondemand/movies to add new movies, GET /admin/users to manage users.  
* These endpoints are protected by RBAC at the API Gateway, requiring explicit admin permissions.

## **5\. Next Steps**

For a complete and interactive API documentation, consider using tools like:

* **FastAPI's built-in OpenAPI/Swagger UI:** FastAPI automatically generates interactive documentation at /docs (and ReDoc at /redoc) based on your endpoint definitions. This is the recommended approach for the demonstrator.  
* **Postman/Insomnia Collections:** Create collections with pre-configured requests to share with developers.  
* **Stoplight Studio/SwaggerHub:** For more advanced API design and documentation workflows.

This document serves as a comprehensive guide for integrating with and utilizing the TV Streaming Backend API effectively.

**Sources**  
1\. [https://rapidapi.com/kidddevs/api/calcx-loan-calculator](https://rapidapi.com/kidddevs/api/calcx-loan-calculator)