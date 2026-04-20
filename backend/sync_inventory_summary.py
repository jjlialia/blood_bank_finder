
import os
from firebase_admin import credentials, firestore, initialize_app
from dotenv import load_dotenv

# 1. Setup Environment
load_dotenv()
cred_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH")
if not cred_path:
    print("Error: FIREBASE_SERVICE_ACCOUNT_PATH not found in .env")
    exit(1)

# 2. Initialize Firebase
cred = credentials.Certificate(cred_path)
initialize_app(cred)
db = firestore.client()

def sync_all_hospitals():
    print("--- Starting Inventory Sync ---")
    hospitals_ref = db.collection('hospitals')
    hospitals = hospitals_ref.stream()
    
    count = 0
    for h_doc in hospitals:
        hospital_id = h_doc.id
        h_data = h_doc.to_dict()
        h_name = h_data.get('name', 'Unknown Hospital')
        
        print(f"Checking: {h_name} ({hospital_id})...")
        
        # Get inventory sub-collection
        inventory_stream = hospitals_ref.document(hospital_id).collection('inventory').stream()
        available_types = []
        for i_doc in inventory_stream:
            i_data = i_doc.to_dict()
            if i_data.get('units', 0) > 0:
                available_types.append(i_data.get('blood_type', i_doc.id))
        
        # Update main doc
        if set(available_types) != set(h_data.get('availableBloodTypes', [])):
            print(f"  -> Updating summary: {available_types}")
            hospitals_ref.document(hospital_id).update({
                'availableBloodTypes': available_types
            })
            count += 1
        else:
            print("  -> Already in sync.")

    print(f"--- Finished! Updated {count} hospitals. ---")

if __name__ == "__main__":
    sync_all_hospitals()
