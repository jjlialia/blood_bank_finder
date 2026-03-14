from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import users, hospitals, requests, inventory, notifications, geocoding

app = FastAPI(title="Blood Bank Finder API")

# Add CORS middleware to allow the Flutter web app to talk to FastAPI
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Permits all origins (adjust for production)
    allow_credentials=True,
    allow_methods=["*"],  # Permits all methods
    allow_headers=["*"],  # Permits all headers
)

app.include_router(users.router)
app.include_router(hospitals.router)
app.include_router(requests.router)
app.include_router(inventory.router)
app.include_router(notifications.router)
app.include_router(geocoding.router)

@app.get("/")
async def root():
    return {"message": "Welcome to Blood Bank Finder API"}
