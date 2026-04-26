
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import users, hospitals, requests, inventory, notifications, geocoding

# INITIALIZATION: Creating the core server instance.
app = FastAPI(title="Blood Bank Finder API")

# STEP: Configure CORS (Cross-Origin Resource Sharing).
# This is a security "bouncer" that decides which external apps can call this API.
# Currently set to "*" (Allow All), which is great for development.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Permits all origins (adjust for production)
    allow_credentials=True,
    allow_methods=["*"],  # Permits all methods (GET, POST, etc.)
    allow_headers=["*"],  # Permits all headers
)

# STEP: Routing.
# These lines connect the "central brain" to specialized departments.
app.include_router(users.router)         # Handles profile creation/updates and banning.
app.include_router(hospitals.router)     # Handles hospital registration and updates.
app.include_router(requests.router)      # Handles the core blood request/donation logic.
app.include_router(inventory.router)     # Handles stock level updates.
app.include_router(notifications.router) # Handles alert creation.
app.include_router(geocoding.router)    # Handles backend-side coordinate lookups.
from app.routers import auth
app.include_router(auth.router)          # Handles OTP verification.

# ROOT ENDPOINT: A simple "I'm alive" check.
@app.get("/")
async def root():
    return {"message": "Welcome to Blood Bank Finder API"}





























"""
FILE: main.py (FastAPI Backend)

DESCRIPTION:
This is the entry point and configuration file for the 'Blood Bank Finder' backend server.
It sets up the FastAPI application, configures security (CORS), and organizes 
the API endpoints into logical 'routers'.

DATA FLOW OVERVIEW:
1. RECEIVES DATA FROM: 
   - The Flutter Frontend (Mobile or Web) via HTTP requests (GET, POST, PUT, PATCH, DELETE).
2. PROCESSING:
   - CORS Middleware: Intercepts every incoming request to check if the caller (origin) 
     is allowed to talk to this server.
   - Routing: Directs incoming requests to the specific file handled by a 'router' 
     (e.g., requests for users go to 'routers/users.py').
3. SENDS DATA TO:
   - The respective Router handlers, which then interact with Firebase Firestore.
4. OUTPUTS/RESPONSES:
   - JSON data back to the Flutter app.
   - Standard HTTP status codes (200 OK, 201 Created, 404 Not Found, etc.).

KEY COMPONENTS:
- CORS: Vital for Web support; allows browsers to let the Flutter app access this API.
- app.include_router: Plugs in the modular pieces of the API (Users, Hospitals, Inventory, etc.).
"""
