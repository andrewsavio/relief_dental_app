RELIEF DENTAL HOSPITAL APP
____________________________________________________________________________________
This application is a cross-platform mobile solution (built with Flutter and Supabase) designed to streamline appointment scheduling, user management, and communication between patients and medical staff.

🌟 Core Features & Purpose
The app implements a robust Role-Based Access Control (RBAC) system, ensuring that Patients, Standard Doctors, and Admins have separate, secure experiences.

Feature	Description	Status
Secure Authentication	Supports sign-up/login using either Email or Username.	✅ Implemented
Role Segregation	Users are categorized into Patient, Standard Doctor, or Admin roles upon sign-in.	✅ Implemented
Session Persistence	Users remain logged in after closing the app.	✅ Implemented
Data Synchronization	All data (appointments, users) is stored securely in Supabase (PostgreSQL).	✅ Implemented
🛠️ Patient Features
The Patient Dashboard is focused on managing upcoming appointments and communicating with the clinic.

Feature	Detail	Access Steps
Flexible Booking	Allows patients to schedule two types of appointments: In-Person Visits or Video Calls (Telehealth).	Tap the Green Plus button (⊞) in the center of the bottom bar.
Rescheduling	If an appointment is Declined by the doctor, the patient can expand the card, view the custom reason, and tap the Reschedule button to quickly re-submit the form with pre-filled details.	Click Declined Card → View Message → Tap Reschedule This Appointment.
Status Visibility	Clearly displays the status of all requests: PENDING, CONFIRMED (Green), or DECLINED (Red).	View appointment list. Status is shown on the card.
In-Person Details	For Confirmed In-Person appointments, the card expands to show the Clinic Location Card with the full address and contact information.	Click Confirmed Card → Tap Get Directions → Launches Google Maps App.
Video Link Access	For Confirmed Video Call appointments, the card provides a Join Video Call button, which will launch the meeting link provided by the doctor.	Click Confirmed Card → Tap Join Video Call.

⚕️ Doctor/Admin Features (Workflow & Security)
The Doctor Portal is designed for managing patient requests, controlling user access, and ensuring security.

1. User Management (Admin Dashboard)
Action	Access	Detail
Manual User Approval	Admin Dashboard (Pending tab)	The app uses a manual approval system. When a new user signs up, the Admin must click Approve to grant access. This action automatically bypasses email verification and confirms the user.
User Management	Active Patients/Doctors tabs	Admins can view full details (name, email, UUID) of all active users by clicking the user's name.
Deletion	Active/Pending tabs (Trash Icon)	The Admin can delete any other user. The red trash icon is disabled for the Admin's own account (security feature).
Bulk Deletion	Top-right Broom Icon	Allows the Admin to securely delete all non-admin user accounts with a single click.
Settings/Theming	Profile Icon → Settings	Users can toggle the Light/Dark Mode. The theme change is persistent across the entire application.
2. Appointment Management (Standard Doctor/Admin)
Action	Access	Detail
Tabbed Views	Bottom Tab Bar (in the App Bar)	The schedule is split into Pending, Accepted, and Declined tabs, with real-time counters.
Booking Confirmation	Click Pending Card → Open Details Page	Provides two clear buttons: DECLINE and ACCEPT.
Rejection Workflow	Click DECLINE	Shows a required Reason for Decline dropdown (data stored in the database) and a Custom Reschedule Message field.
Visual Confirmation	After clicking ACCEPT or DECLINE	Triggers a full-screen Lottie Animation (Green Check or Red Cross) and changes the screen background color to confirm the action visually.

🏃 Getting Started
Prerequisites
Flutter SDK (must be installed)

Supabase Account (with URL and Anon Key configured in lib/main.dart)

Lottie File: A success.json and Rejected.json file in assets/animations/.

Initial Setup Steps
Install Packages: Run flutter pub get after checking your pubspec.yaml dependencies.

Create Admin:

Go to the Sign Up page.

Select the Doctor toggle.

Create a primary account (e.g., andresaviom).

Approve Admin (CRITICAL):

Go to Supabase Table Editor → doctors table.

Find the row for your admin user and manually set the approved column to true.

Launch: Log in as your newly approved Admin. You now have full control of the system!
