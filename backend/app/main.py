from fastapi import FastAPI
from .routers import users, hospitals, requests, inventory, notifications, geocoding

app = FastAPI(title="Blood Bank Finder API")

app.include_router(users.router)
app.include_router(hospitals.router)
app.include_router(requests.router)
app.include_router(inventory.router)
app.include_router(notifications.router)
app.include_router(geocoding.router)

@app.get("/")
async def root():
    return {"message": "Welcome to Blood Bank Finder API"}
