"""
FILE: config.py

DESCRIPTION:
This file manages the "Vital Life Support" of the backend—its connection to 
external services like Firebase and Google Maps. It handles environment 
variables and service authentication.

DATA FLOW OVERVIEW:
1. RECEIVES DATA FROM: 
   - '.env' file: Securely reads 'FIREBASE_SERVICE_ACCOUNT_PATH' and 'GOOGLE_MAPS_API_KEY'.
2. PROCESSING:
   - Environment Setup: Loads keys into the system process.
   - Firebase Boot: Initializes the official Admin SDK using the provided JSON key.
3. SENDS DATA TO:
   - The rest of the Backend: Provides a live 'db' (Firestore Client) to all routers.
4. OUTPUTS:
   - A single connection point it uses to authenticate all database reads and writes.
"""

import os
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv

# STEP: Load secret keys from the .env file.
load_dotenv()

def get_google_maps_key():
    """Returns the API key for Google Maps geocoding services."""
    key = os.getenv("GOOGLE_MAPS_API_KEY")
    if not key:
        raise ValueError("GOOGLE_MAPS_API_KEY not found in environment variables")
    return key

def initialize_firebase():
    """
    Connects the Python backend to the Firebase Project.
    Uses a 'Service Account Key' (JSON) to grant this server full admin access.
    """
    cred_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH")
    if not cred_path:
        raise ValueError("FIREBASE_SERVICE_ACCOUNT_PATH not found in environment variables")
    
    # Preventing double-initialization errors.
    if not firebase_admin._apps:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)

def get_db():
    """
    FASTAPI DEPENDENCY:
    Provides a database client to any endpoint that needs to read/write data.
    """
    initialize_firebase()
    return firestore.client()
