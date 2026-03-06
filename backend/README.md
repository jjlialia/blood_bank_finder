# Blood Bank Finder - FastAPI Backend

This is the FastAPI backend for the Blood Bank Finder application. It handles all CRUD operations and coordinates with Google Firestore using the Firebase Admin SDK.

## Setup Instructions

1.  **Environment Setup**:
    *   Ensure you have Python 3.8+ installed.
    *   Create a virtual environment:
        ```bash
        python -m venv venv
        source venv/bin/activate  # On Windows: venv\Scripts\activate
        ```
    *   Install dependencies:
        ```bash
        pip install -r requirements.txt
        ```

2.  **Firebase Credentials**:
    *   Place your Firebase Service Account JSON file in the `backend/` directory.
    *   Update the `.env` file with the correct path:
        ```env
        FIREBASE_SERVICE_ACCOUNT_PATH=your-service-account-file.json
        ```

3.  **Running the Server**:
    *   From the `backend/` directory, run:
        ```bash
        python main.py
        ```
    *   The server will start at `http://localhost:8000`.

4.  **API Documentation**:
    *   Once the server is running, visit `http://localhost:8000/docs` to view the interactive Swagger UI.

## Project Structure

*   `app/main.py`: Entry point and router registration.
*   `app/models.py`: Pydantic schemas for data validation.
*   `app/services/firestore_service.py`: Business logic and Firestore interactions.
*   `app/routers/`: Individual API modules for Users, Hospitals, Requests, Inventory, and Notifications.

## Logic Implementation

*   **Status Updates**: When a blood request status is updated to 'approved' or 'rejected', the backend automatically creates a notification for the requesting user in the Firestore `notifications` collection.
*   **Filtering**: Hospital indices support filtering by `islandGroup`, `city`, and `barangay`.
