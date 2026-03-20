# Blood Bank Finder: Full Project Inventory

This document provides a comprehensive list of all source files in the application, explaining **What** each file is and **Why** it exists in the architecture.

---

## 🚀 Root & Configuration
| File | What? | Why? |
| :--- | :--- | :--- |
| `pubspec.yaml` | Flutter dependency manifest. | Defines all packages (Firebase, Google Maps, Provider) needed for the app. |
| `analysis_options.yaml` | Dart linter rules. | Ensures code quality and consistent styling across the frontend. |
| `backend/main.py` | FastAPI entry point. | Initializes the server, includes all routers, and handles CORS settings. |
| `backend/requirements.txt` | Python dependency list. | Lists all backend libraries (fastapi, firebase-admin, uvicorn) for the environment. |

---

## 📱 Flutter Frontend (`lib/`)

### 1. Core Layer (`lib/core/`)
| File | What? | Why? |
| :--- | :--- | :--- |
| `main.dart` | The app's heartbeat. | Initializes Firebase, sets up global Providers (Auth), and defines the initial route. |
| `firebase_options.dart` | Firebase config constants. | Generated file connecting the Flutter app to specific Firebase project credentials. |
| **Models/** | Data structures (User, Hospital, Request). | Standardizes how data looks throughout the app for type-safety and consistency. |
| `services/api_service.dart` | Network bridge. | Centralizes all HTTP calls to the FastAPI backend (Signup, Requests, Inventory). |
| `services/db_service.dart` | Direct Firestore bridge. | Handles real-time data streaming (Reads) directly from the database for speed. |
| `services/location_service.dart` | Location helper. | Interfaces with the PSGC API to provide hierarchical Philippine location data. |

### 2. Features Layer (`lib/features/`)
| Folder | What? | Why? |
| :--- | :--- | :--- |
| `auth/` | Screens for Login/Signup. | Manages the user's entry into the system and identity verification. |
| `super_admin/` | High-level control panels. | Allows "God Mode" access to manage hospitals, ban users, and see global logs. |
| `hospital/` | Site-specific management. | Tools for Hospital Admins to update their local blood stock and process requests. |
| `user/` | Normal user interface. | The main consumer experience: find blood banks, request units, or pledge donations. |

### 3. Shared Layer (`lib/shared/`)
| File | What? | Why? |
| :--- | :--- | :--- |
| `widgets/` | Reusable UI components. | Standardizes the look of buttons, text fields, and pickers to avoid code duplication. |

---

## ⚙️ FastAPI Backend (`backend/app/`)

### 1. App Engine
| File | What? | Why? |
| :--- | :--- | :--- |
| `config.py` | Environment settings. | Manages sensitive keys and constants (Firebase credentials, API settings). |
| `models.py` | Pydantic data models. | Validates incoming JSON data from the Flutter app before it touches the database. |
| `services/firestore_service.py` | Database logic. | The "Brain" that performs the actual Firestore writes, updates, and transactions. |

### 2. Routers (`backend/app/routers/`)
| File | What? | Why? |
| :--- | :--- | :--- |
| `users.py` | User identity endpoints. | Routes for creating users, updating roles, and banning accounts. |
| `hospitals.py` | Facility management. | Routes for CRUD operations on hospital profiles. |
| `inventory.py` | Stock control logic. | Handles the delicate transactional logic for incrementing/decrementing blood units. |
| `requests.py` | Transactional flow. | Manages the lifecycle of blood requests and automated status notifications. |
| `geocoding.py` | GPS bridge. | Safely proxies requests to the Google Maps API so API keys aren't exposed in the app. |

---
**END OF PROJECT INVENTORY**
