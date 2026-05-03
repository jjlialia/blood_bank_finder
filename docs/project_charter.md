# Project Charter: Blood Bank Finder and Donation Management System

## Project Overview

| Project Title | Blood Bank Finder and Donation Management System |
| :--- | :--- |
| **Proponents** | Elvira A. Medio (Programmer/Coder) |
| **Instructors** | Mr. Panfilo Remedio, Mrs. Annalyn P. Gelicame, LPT |
| **Date** | March 23, 2021 |

---

## 1. Project Description
The **Blood Bank Finder Mobile Application** is designed to connect blood donors, patients, hospitals, and administrators in one centralized system. It allows users to search for available blood banks, donate blood, or request blood. It streamlines communication between donors and hospitals while allowing administrators to manage requests, users, and hospital records efficiently through a role-based system.

---

## 2. Project Scope
The system focuses on providing a mobile-based solution for blood donation and blood request management. 
- **In-Scope:** User registration and authentication, hospital listings, blood request processing, donation approvals, and administrative monitoring. Mobile access for general users, system administrators, and hospital administrators.
- **Out-of-Scope:** Direct medical processing, physical blood storage management hardware, or integration with external government health databases.

---

## 3. System Features
- **User Registration and Login:** Secure authentication via Firebase Authentication.
- **Role-based Access Control:** Distinct interfaces and permissions for **General Users**, **Hospital Admins**, and **System Admins**.
- **Search Functionality:** Search for hospitals by city to check blood availability.
- **Form Submissions:** Dedicated forms for Blood Donation and Blood Request.
- **Approval System:** Workflow for hospital administrators to review, approve, or reject requests.
- **Notification System:** Real-time push notifications for request status updates.
- **Admin Dashboard:** Centralized panel for managing hospital accounts, users, and system-wide activity.
- **Real-time Database:** Synchronized data updates using Firebase Firestore.

---

## 4. System Users

### General Users (Mobile)
- Register and log in.
- Search blood banks by city.
- View hospital details and blood inventory.
- Submit blood donation and blood request forms.
- Receive real-time approval or rejection notifications.
- View profile and personal request history.

### System Admin (Mobile)
- Manage hospital accounts (Add/Delete).
- Manage user accounts (View, Ban, Monitor).
- Monitor all blood requests and donations system-wide.
- View system activity reports and analytics.

### Hospital Admin
- Log in to the dedicated hospital management panel.
- View and process incoming blood requests and donation offers.
- Approve or reject requests based on inventory.
- Update real-time blood inventory levels.
- Manage hospital profile information.
- Track history of pending, approved, and rejected requests.

---

## 5. Limitations
- **Connectivity:** Requires a stable internet connection to function.
- **Dependency:** Heavily dependent on Firebase services (Auth, Firestore, Messaging).
- **Data Accuracy:** Blood availability data is dependent on timely updates from hospital administrators.
- **No GPS Integration:** No direct real-time GPS tracking for users or blood transport.
- **Restricted Access:** Limited to hospitals registered within the system.

---

## 6. Risks
- **Security:** Potential data privacy risks if security rules are not strictly configured.
- **Data Integrity:** Risk of false information or fraudulent requests submitted by users.
- **Availability:** System downtime if Firebase cloud services experience outages.
- **Latency:** Potential for delayed responses from hospital administrators in critical situations.
- **Misuse:** Potential for misuse of the emergency request features.

---

## 7. Alternative Solutions
- Manual hospital hotline or telephone-based coordination.
- SMS-based blood request and broadcast system.
- Integration with existing third-party health management systems.
- Development of a web-based admin panel for easier desk-based management.
- Integration with a government-centralized national blood database.

---

## 8. Advantages
- **Efficiency:** Significantly faster processing of blood requests compared to manual methods.
- **Centralization:** Digital record management eliminates paper-based tracking errors.
- **Transparency:** Real-time updates on request status for all stakeholders.
- **Enhanced Communication:** Direct link between donors and hospitals.
- **Monitoring:** Streamlined oversight for system administrators.
- **Accessibility:** 24/7 access via mobile devices.

---

## 9. System Flow (Mobile)
1. **Launch:** User opens the app (Splash Screen).
2. **Auth:** User selects Login or Sign Up.
3. **Home:** After authentication, the user enters the main dashboard.
4. **Functional Paths:**
   - **Find Blood Bank:** Select City → View Hospitals → View Details.
   - **Donate Blood:** Fill Form → Submit → Hospital Review → Approve/Reject → User Notification.
   - **Request Blood:** Fill Form → Submit → Hospital Review → Approve/Reject → User Confirmation.
   - **Hospital Management:** Admin logs in → Reviews Requests → Updates Inventory.
   - **System Oversight:** System Admin logs in → Manages Entities → Monitors Reports.

### Comprehensive System Flowchart
```mermaid
graph TD
    %% Global Entry
    Start((Splash Screen)) --> Auth{Authentication}
    Auth --> Login[Login Screen]
    Auth --> SignUp[Sign Up Screen]
    SignUp --> OTP[OTP Verification]
    OTP --> RoleSelect[Role Initialization]
    Login --> RoleDispatch{Role Check}

    %% Role Dispatching
    RoleDispatch -- "General User" --> UserHome[User Dashboard]
    RoleDispatch -- "Hospital Admin" --> HAdminHome[Hospital Dashboard]
    RoleDispatch -- "System Admin" --> SAdminHome[Super Admin Dashboard]

    %% USER FEATURES
    subgraph "General User Features"
        UserHome --> Search[Find Blood Bank]
        UserHome --> UProfile[Profile & History]
        UserHome --> UNotifs[Notifications]

        Search --> CityFilter[Select City]
        CityFilter --> HList[Hospital Listings]
        HList --> HDetails[Hospital Details & Inventory]
        
        HDetails --> DonateForm[Donate Blood Form]
        HDetails --> RequestForm[Request Blood Form]
        
        DonateForm --> DSubmit[Submit Donation]
        RequestForm --> RSubmit[Submit Request]
        
        UProfile --> EditProfile[Edit Personal Info]
        UProfile --> RequestHistory[View Past Requests]
    end

    %% HOSPITAL ADMIN FEATURES
    subgraph "Hospital Admin Features"
        HAdminHome --> HRequests[Manage Blood Requests]
        HAdminHome --> HDonations[Manage Donations]
        HAdminHome --> HInventory[Inventory Management]
        HAdminHome --> HSettings[Hospital Profile]

        HRequests --> RList[Incoming Requests]
        RList --> RApprove[Approve / Reject]
        RApprove -- Success --> InvSync1[Auto-Update Inventory]

        HDonations --> DList[Incoming Donations]
        DList --> DApprove[Approve / Reject]
        DApprove -- Success --> InvSync2[Auto-Update Inventory]

        HInventory --> ManualUpdate[Add/Edit Blood Stock]
    end

    %% SYSTEM ADMIN FEATURES
    subgraph "System Admin Features"
        SAdminHome --> M_Hospitals[Manage Hospitals]
        SAdminHome --> M_Users[Manage Users]
        SAdminHome --> M_Logs[Audit Logs]
        SAdminHome --> M_Stats[System Analytics]

        M_Hospitals --> AddHosp[Add New Hospital Account]
        M_Hospitals --> DelHosp[Deactivate Hospital]
        
        M_Users --> UserSearch[Search Users]
        M_Users --> UserBan[Ban/Unban Users]
    end

    %% COLOR STYLING
    classDef startNode fill:#f9f,stroke:#333,stroke-width:2px,color:#000
    classDef userNode fill:#e1f5fe,stroke:#01579b,stroke-width:2px,color:#01579b
    classDef hospNode fill:#fff3e0,stroke:#e65100,stroke-width:2px,color:#e65100
    classDef adminNode fill:#f1f8e9,stroke:#33691e,stroke-width:2px,color:#33691e
    classDef decision fill:#fff9c4,stroke:#fbc02d,stroke-width:2px,color:#000

    class Start startNode
    class Auth,RoleDispatch,RApprove,DApprove decision
    class UserHome,Search,UProfile,UNotifs,CityFilter,HList,HDetails,DonateForm,RequestForm,EditProfile,RequestHistory userNode
    class HAdminHome,HRequests,HDonations,HInventory,HSettings,RList,DList,ManualUpdate,InvSync1,InvSync2 hospNode
    class SAdminHome,M_Hospitals,M_Users,M_Logs,M_Stats,AddHosp,DelHosp,UserSearch,UserBan adminNode
```

---

## 10. Approval

**Approved by:**

| Name | Signature | Date |
| :--- | :--- | :--- |
| **Mr. Panfilo Remedio** (Instructor) | ____________________ | ____________________ |
| **Mrs. Annalyn P. Gelicame, LPT** (Instructor) | ____________________ | ____________________ |
