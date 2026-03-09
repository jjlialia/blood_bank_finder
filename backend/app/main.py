from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import users, hospitals, requests, inventory, notifications, auth, locations

app = FastAPI(title="Blood Bank Finder API")

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(locations.router)
app.include_router(users.router)
app.include_router(hospitals.router)
app.include_router(requests.router)
app.include_router(inventory.router)
app.include_router(notifications.router)

@app.get("/")
async def root():
    return {"message": "Welcome to Blood Bank Finder API"}
