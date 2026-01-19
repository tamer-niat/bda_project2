from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
from typing import Optional, List, Literal
import mysql.connector
from mysql.connector import Error
from contextlib import contextmanager
import json
from datetime import datetime, date, time

app = FastAPI(title="Exam Scheduler API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DB_CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": "",
    "database": "exam_scheduler_db",
    "charset": "utf8mb4"
}


# ============================================
# PYDANTIC MODELS
# ============================================

class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: int
    email: str
    role: str
    nom: Optional[str] = None
    prenom: Optional[str] = None
    department_id: Optional[int] = None
    department: Optional[str] = None  # ✅ Added department name field
    formation_id: Optional[int] = None
    groupe_id: Optional[int] = None  # ✅ Added groupe_id for students
    promo: Optional[str] = None
    groupe: Optional[str] = None
    speciality: Optional[str] = None
    grade: Optional[str] = None
    date_naissance: Optional[str] = None


class LoginResponse(BaseModel):
    success: bool
    message: str
    user: Optional[UserResponse] = None


class TimeSlot(BaseModel):
    label: str
    start: str  # Format: "HH:MM"
    end: str    # Format: "HH:MM"


class GenerateScheduleRequest(BaseModel):
    annee_universitaire: str  # e.g., "2023-2024"
    semester: str  # "S1" or "S2"
    start_date: str  # Format: "YYYY-MM-DD"
    end_date: str  # Format: "YYYY-MM-DD"
    time_slots: List[TimeSlot]
    created_by: int  # User ID


class GenerateScheduleResponse(BaseModel):
    success: bool
    message: str
    result: Optional[dict] = None


class ClearSchedulesRequest(BaseModel):
    annee_universitaire: str
    semester: str


class ChefApprovalRequest(BaseModel):
    schedule_id: int
    chef_id: int
    action: Literal['APPROVE', 'REJECT']
    comment: Optional[str] = None


class DoyenApprovalRequest(BaseModel):
    schedule_id: int
    doyen_id: int
    action: Literal['APPROVE', 'REJECT']
    comment: Optional[str] = None


class ApprovalResponse(BaseModel):
    status: str
    message: str
    new_status: Optional[str] = None
    current_status: Optional[str] = None


# ============================================
# DATABASE CONNECTION
# ============================================

@contextmanager
def get_db_connection():
    connection = None
    try:
        connection = mysql.connector.connect(**DB_CONFIG)
        yield connection
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database connection failed: {str(e)}")
    finally:
        if connection and connection.is_connected():
            connection.close()


# ============================================
# BASIC ENDPOINTS
# ============================================

@app.get("/")
async def root():
    return {
        "message": "Exam Scheduler API is running",
        "version": "2.0.0",
        "status": "active",
        "features": [
            "Dynamic time slots",
            "Smart room allocation",
            "Balanced teacher assignment",
            "Conflict detection & logging",
            "Multi-level approval workflow",
            "Schedule utilities",
            "Department-filtered exam views"
        ]
    }


@app.get("/health")
async def health_check():
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            cursor.fetchone()
            cursor.close()
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Service unavailable: {str(e)}")


@app.post("/api/login", response_model=LoginResponse)
async def login(credentials: LoginRequest):
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)

            cursor.callproc(
                "verify_login",
                [credentials.email, credentials.password]
            )

            user = None
            for result in cursor.stored_results():
                user = result.fetchone()

            cursor.close()

            if not user or user.get("id") is None:
                return LoginResponse(
                    success=False,
                    message=user.get("error", "Email ou mot de passe incorrect") if user else "Email ou mot de passe incorrect"
                )

            if "date_naissance" in user and user["date_naissance"]:
                user["date_naissance"] = str(user["date_naissance"])

            return LoginResponse(
                success=True,
                message="Connexion réussie",
                user=UserResponse(**user)
            )

    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Server error: {str(e)}")


@app.get("/api/user/{user_id}")
async def get_user(user_id: int):
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)

            cursor.execute(
                "SELECT id, email, role FROM utilisateurs WHERE id = %s",
                (user_id,)
            )
            base_user = cursor.fetchone()

            if not base_user:
                raise HTTPException(status_code=404, detail="Utilisateur non trouvé")

            role = base_user["role"]

            if role in ("Doyen", "Vice-doyen"):
                query = "SELECT nom, prenom FROM doyens WHERE id = %s"
            elif role == "Chef-departement":
                query = "SELECT nom, prenom, department_id FROM chefs_departement WHERE id = %s"
            elif role == "Admin-examens":
                query = "SELECT nom, prenom FROM admins_examens WHERE id = %s"
            elif role == "Enseignant":
                query = "SELECT nom, prenom, department_id, speciality, grade FROM enseignants WHERE id = %s"
            elif role == "Etudiant":
                query = """
                    SELECT nom, prenom, formation_id, promo, date_naissance, groupe
                    FROM etudiants
                    WHERE id = %s
                """
            else:
                raise HTTPException(status_code=400, detail="Role invalide")

            cursor.execute(query, (user_id,))
            role_data = cursor.fetchone()
            cursor.close()

            if role_data:
                base_user.update(role_data)
                if "date_naissance" in base_user and base_user["date_naissance"]:
                    base_user["date_naissance"] = str(base_user["date_naissance"])

            return {"success": True, "user": base_user}

    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.get("/api/users")
async def get_all_users():
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            cursor.execute("SELECT id, email, role FROM utilisateurs ORDER BY id")
            users = cursor.fetchall()
            cursor.close()

            return {
                "success": True,
                "count": len(users),
                "users": users
            }

    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.get("/api/departements")
async def get_all_departements():
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            
            cursor.callproc('get_all_departements')
            
            departements = []
            for result in cursor.stored_results():
                departements = result.fetchall()
            
            cursor.close()
            
            return {
                "success": True,
                "count": len(departements),
                "departements": departements
            }
            
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


# ============================================
# SCHEDULE GENERATION ENDPOINT
# ============================================

@app.post("/api/generate-schedule", response_model=GenerateScheduleResponse)
async def generate_schedule(request: GenerateScheduleRequest):
    """
    Generate exam schedule with dynamic time slots from UI
    """
    try:
        # Validate inputs
        if not request.time_slots:
            raise HTTPException(status_code=400, detail="At least one time slot is required")
        
        if len(request.time_slots) > 10:
            raise HTTPException(status_code=400, detail="Maximum 10 time slots allowed")
        
        # Convert time slots to JSON format for MySQL
        time_slots_json = json.dumps([
            {
                "label": slot.label,
                "start": slot.start,
                "end": slot.end
            }
            for slot in request.time_slots
        ])
        
        # Validate semester
        if request.semester not in ['S1', 'S2']:
            raise HTTPException(status_code=400, detail="Semester must be S1 or S2")
        
        # Validate dates
        try:
            start_date = datetime.strptime(request.start_date, '%Y-%m-%d').date()
            end_date = datetime.strptime(request.end_date, '%Y-%m-%d').date()
            
            if end_date <= start_date:
                raise HTTPException(status_code=400, detail="End date must be after start date")
            
            days_diff = (end_date - start_date).days
            if days_diff < 14:
                raise HTTPException(status_code=400, detail="Date range must be at least 14 days")
                
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")
        
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            
            # Call the stored procedure with dynamic parameters
            cursor.callproc(
                "sp_generate_exam_schedule",
                [
                    request.annee_universitaire,
                    request.semester,
                    request.start_date,
                    request.end_date,
                    time_slots_json,
                    request.created_by
                ]
            )
            
            # Fetch the result summary
            result = None
            for res in cursor.stored_results():
                result = res.fetchone()
            
            cursor.close()
            
            if result:
                return GenerateScheduleResponse(
                    success=True,
                    message="Schedule generated successfully",
                    result={
                        "examsScheduled": result.get('exams_scheduled', 0),
                        "formationsAffected": result.get('formations_affected', 0),
                        "daysUsed": result.get('days_used', 0),
                        "totalConflicts": result.get('total_conflicts', 0),
                        "studentConflicts": result.get('student_conflicts', 0),
                        "teacherConflicts": result.get('teacher_conflicts', 0),
                        "roomConflicts": result.get('room_conflicts', 0),
                        "timestamp": datetime.now().isoformat(),
                        "dateRange": {
                            "start": request.start_date,
                            "end": request.end_date,
                            "days": days_diff
                        },
                        "timeSlotsUsed": len(request.time_slots)
                    }
                )
            else:
                raise HTTPException(status_code=500, detail="No result from generator")
            
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Server error: {str(e)}")


# ============================================
# SCHEDULE VIEWING ENDPOINTS
# ============================================

@app.get("/api/schedules")
async def get_schedules(
    annee: Optional[str] = None,
    semester: Optional[str] = None
):
    """
    Get all schedules, optionally filtered by year and semester
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            
            if annee and semester:
                query = """
                    SELECT 
                        s.id,
                        f.nom AS formation,
                        f.code AS formation_code,
                        s.annee_universitaire,
                        s.semester,
                        s.statut,
                        s.created_at,
                        COUNT(DISTINCT se.id) AS exam_count
                    FROM schedules s
                    JOIN formations f ON f.id = s.formation_id
                    LEFT JOIN schedule_examens se ON se.schedule_id = s.id
                    WHERE s.annee_universitaire = %s AND s.semester = %s
                    GROUP BY s.id
                    ORDER BY f.nom
                """
                cursor.execute(query, (annee, semester))
            else:
                query = """
                    SELECT 
                        s.id,
                        f.nom AS formation,
                        f.code AS formation_code,
                        s.annee_universitaire,
                        s.semester,
                        s.statut,
                        s.created_at,
                        COUNT(DISTINCT se.id) AS exam_count
                    FROM schedules s
                    JOIN formations f ON f.id = s.formation_id
                    LEFT JOIN schedule_examens se ON se.schedule_id = s.id
                    GROUP BY s.id
                    ORDER BY s.created_at DESC
                    LIMIT 50
                """
                cursor.execute(query)
            
            schedules = cursor.fetchall()
            cursor.close()
            
            # Convert datetime to string
            for schedule in schedules:
                if 'created_at' in schedule and schedule['created_at']:
                    schedule['created_at'] = str(schedule['created_at'])
            
            return {
                "success": True,
                "count": len(schedules),
                "schedules": schedules
            }
            
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.get("/api/schedule/{schedule_id}/stats")
async def get_schedule_stats(schedule_id: int):
    """
    Get statistics for a specific schedule
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            
            cursor.callproc("sp_get_schedule_stats", [schedule_id])
            
            stats = None
            for result in cursor.stored_results():
                stats = result.fetchone()
            
            cursor.close()
            
            if not stats:
                raise HTTPException(status_code=404, detail="Schedule not found")
            
            # Convert dates to strings
            if 'first_exam' in stats and stats['first_exam']:
                stats['first_exam'] = str(stats['first_exam'])
            if 'last_exam' in stats and stats['last_exam']:
                stats['last_exam'] = str(stats['last_exam'])
            
            return {
                "success": True,
                "stats": stats
            }
            
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.get("/api/schedule/{schedule_id}/details")
async def get_schedule_details(schedule_id: int):
    """
    Get detailed exam schedule for a specific schedule
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            
            cursor.callproc("sp_get_schedule_details", [schedule_id])
            
            details = []
            for result in cursor.stored_results():
                details = result.fetchall()
            
            cursor.close()
            
            # Convert dates and times to strings
            for detail in details:
                if 'date_exam' in detail and detail['date_exam']:
                    detail['date_exam'] = str(detail['date_exam'])
                if 'heure_debut' in detail and detail['heure_debut']:
                    detail['heure_debut'] = str(detail['heure_debut'])
            
            return {
                "success": True,
                "count": len(details),
                "exams": details
            }
            
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


# ============================================
# NEW: DEPARTMENT-FILTERED EXAM ENDPOINTS
# ============================================

@app.get("/api/schedule/{schedule_id}/details/department/{department_id}")
async def get_schedule_details_by_department(schedule_id: int, department_id: int):
    """
    Get detailed exam schedule for a specific schedule filtered by department
    This is used by Chef de Département to see only their department's exams
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            
            cursor.callproc("sp_get_department_exams", [schedule_id, department_id])
            
            details = []
            for result in cursor.stored_results():
                details = result.fetchall()
            
            cursor.close()
            
            # Convert dates and times to strings
            for detail in details:
                if 'date_exam' in detail and detail['date_exam']:
                    detail['date_exam'] = str(detail['date_exam'])
                if 'heure_debut' in detail and detail['heure_debut']:
                    detail['heure_debut'] = str(detail['heure_debut'])
            
            return {
                "success": True,
                "count": len(details),
                "exams": details,
                "department_id": department_id,
                "schedule_id": schedule_id
            }
            
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.get("/api/debug/department/{department_id}/exams")
async def debug_department_exams(
    department_id: int,
    annee: str = "2025-2026",
    semester: str = "S1"
):
    """
    Debug endpoint to check what exams exist for a department
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            
            # Check exams
            cursor.execute("""
                SELECT 
                    e.id AS exam_id,
                    m.nom AS matiere,
                    f.nom AS formation,
                    d.nom AS department,
                    d.id AS department_id,
                    e.annee_universitaire,
                    e.semester
                FROM examens e
                JOIN matieres m ON m.id = e.matiere_id
                JOIN formations f ON f.id = e.formation_id
                JOIN departements d ON d.id = f.department_id
                WHERE d.id = %s
                  AND e.annee_universitaire = %s
                  AND e.semester = %s
            """, (department_id, annee, semester))
            
            exams = cursor.fetchall()
            
            # Check schedules
            cursor.execute("""
                SELECT 
                    s.id AS schedule_id,
                    f.nom AS formation,
                    d.nom AS department,
                    s.statut,
                    COUNT(se.id) AS exam_count
                FROM schedules s
                JOIN formations f ON f.id = s.formation_id
                JOIN departements d ON d.id = f.department_id
                LEFT JOIN schedule_examens se ON se.schedule_id = s.id
                WHERE d.id = %s
                  AND s.annee_universitaire = %s
                  AND s.semester = %s
                GROUP BY s.id, f.nom, d.nom, s.statut
            """, (department_id, annee, semester))
            
            schedules = cursor.fetchall()
            
            # Check if exams are scheduled
            cursor.execute("""
                SELECT 
                    se.id AS schedule_exam_id,
                    e.id AS exam_id,
                    m.nom AS matiere,
                    se.date_exam,
                    se.heure_debut,
                    s.statut
                FROM schedule_examens se
                JOIN schedules s ON s.id = se.schedule_id
                JOIN examens e ON e.id = se.examen_id
                JOIN matieres m ON m.id = e.matiere_id
                JOIN formations f ON f.id = e.formation_id
                WHERE f.department_id = %s
                  AND s.annee_universitaire = %s
                  AND s.semester = %s
            """, (department_id, annee, semester))
            
            scheduled_exams = cursor.fetchall()
            
            # Convert dates
            for exam in scheduled_exams:
                if 'date_exam' in exam and exam['date_exam']:
                    exam['date_exam'] = str(exam['date_exam'])
                if 'heure_debut' in exam and exam['heure_debut']:
                    exam['heure_debut'] = str(exam['heure_debut'])
            
            cursor.close()
            
            return {
                "success": True,
                "department_id": department_id,
                "total_exams": len(exams),
                "total_schedules": len(schedules),
                "total_scheduled_exams": len(scheduled_exams),
                "exams": exams,
                "schedules": schedules,
                "scheduled_exams": scheduled_exams
            }
            
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


# ============================================
# CONFLICTS ENDPOINT
# ============================================

@app.get("/api/conflicts")
async def get_conflicts(
    annee: Optional[str] = None,
    semester: Optional[str] = None
):
    """
    Get all schedule conflicts, optionally filtered
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            
            if annee and semester:
                cursor.callproc("sp_get_schedule_conflicts", [annee, semester])
                
                conflicts = []
                for result in cursor.stored_results():
                    conflicts = result.fetchall()
            else:
                cursor.execute("""
                    SELECT 
                        sc.*,
                        e.formation_id,
                        m.nom AS matiere_nom,
                        f.nom AS formation_nom,
                        ens.nom AS enseignant_nom,
                        l.nom AS lieu_nom
                    FROM schedule_conflicts sc
                    LEFT JOIN examens e ON e.id = sc.examen_id
                    LEFT JOIN matieres m ON m.id = e.matiere_id
                    LEFT JOIN formations f ON f.id = COALESCE(e.formation_id, sc.formation_id)
                    LEFT JOIN enseignants ens ON ens.id = sc.enseignant_id
                    LEFT JOIN lieux_examen l ON l.id = sc.lieu_id
                    ORDER BY sc.created_at DESC
                    LIMIT 100
                """)
                conflicts = cursor.fetchall()
            
            cursor.close()
            
            # Convert datetime to string
            for conflict in conflicts:
                if 'created_at' in conflict and conflict['created_at']:
                    conflict['created_at'] = str(conflict['created_at'])
            
            return {
                "success": True,
                "count": len(conflicts),
                "conflicts": conflicts
            }
            
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.post("/api/clear-schedules")
async def clear_schedules(request: ClearSchedulesRequest):
    """
    Clear all schedules for a specific period (for regeneration)
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            
            cursor.callproc(
                "sp_clear_schedules",
                [request.annee_universitaire, request.semester]
            )
            
            result = None
            for res in cursor.stored_results():
                result = res.fetchone()
            
            cursor.close()
            
            return {
                "success": True,
                "message": result.get('message', 'Schedules cleared successfully') if result else 'Schedules cleared successfully'
            }
            
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.get("/api/exams/all")
async def get_all_exams(
    annee: str,
    semester: str
):
    """
    Get ALL exam details for a year/semester across all formations
    Used by Exam Admin to see all exams regardless of status
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            
            cursor.callproc("sp_get_all_exam_details", [annee, semester])
            
            exams = []
            for result in cursor.stored_results():
                exams = result.fetchall()
            
            cursor.close()
            
            # Convert dates and times to strings
            for exam in exams:
                if 'date_exam' in exam and exam['date_exam']:
                    exam['date_exam'] = str(exam['date_exam'])
                if 'heure_debut' in exam and exam['heure_debut']:
                    exam['heure_debut'] = str(exam['heure_debut'])
            
            return {
                "success": True,
                "count": len(exams),
                "exams": exams
            }
            
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.get("/api/exams/published")
async def get_published_exams(
    annee: str,
    semester: str
):
    """
    Get PUBLISHED exam details for a year/semester
    Only returns exams with status 'PUBLIE' (approved by Doyen)
    Used by Students and Teachers to see their exam schedules
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            
            cursor.callproc("sp_get_published_exam_details", [annee, semester])
            
            exams = []
            for result in cursor.stored_results():
                exams = result.fetchall()
            
            cursor.close()
            
            # Convert dates and times to strings
            for exam in exams:
                if 'date_exam' in exam and exam['date_exam']:
                    exam['date_exam'] = str(exam['date_exam'])
                if 'heure_debut' in exam and exam['heure_debut']:
                    exam['heure_debut'] = str(exam['heure_debut'])
            
            return {
                "success": True,
                "count": len(exams),
                "exams": exams
            }
            
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.get("/api/exams/student/{student_id}")
async def get_student_exams(
    student_id: int,
    annee: str,
    semester: str
):
    """
    Get PUBLISHED exams for a specific student
    Filters by student's formation_id and optionally groupe_id
    Only returns exams with status 'PUBLIE' (approved by Doyen)
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            
            # First verify the user exists and is a student
            cursor.execute("""
                SELECT id, role 
                FROM utilisateurs 
                WHERE id = %s AND role = 'Etudiant'
            """, (student_id,))
            
            user = cursor.fetchone()
            if not user:
                raise HTTPException(
                    status_code=404, 
                    detail=f"Student with ID {student_id} not found or user is not a student"
                )
            
            # Get student's formation_id and groupe_id from etudiants table
            # Note: etudiants.id should match utilisateurs.id
            cursor.execute("""
                SELECT e.formation_id, e.groupe_id, f.nom AS formation_name
                FROM etudiants e
                LEFT JOIN formations f ON f.id = e.formation_id
                WHERE e.id = %s
            """, (student_id,))
            
            student = cursor.fetchone()
            if not student:
                raise HTTPException(
                    status_code=404, 
                    detail=f"Student record not found in etudiants table for ID {student_id}"
                )
            
            formation_id = student.get('formation_id')
            groupe_id = student.get('groupe_id')
            formation_name = student.get('formation_name')
            
            if not formation_id:
                raise HTTPException(
                    status_code=400, 
                    detail=f"Student {student_id} has no formation assigned"
                )
            
            print(f"🔍 Fetching exams for student {student_id}:")
            print(f"   Formation ID: {formation_id} ({formation_name})")
            print(f"   Groupe ID: {groupe_id}")
            print(f"   Academic Year: {annee}, Semester: {semester}")
            
            # Get exams for this student's formation
            # Pass NULL if groupe_id is None or 0
            cursor.callproc("sp_get_student_exams", [
                annee, 
                semester, 
                formation_id, 
                groupe_id if groupe_id else None
            ])
            
            exams = []
            for result in cursor.stored_results():
                exams = result.fetchall()
            
            cursor.close()
            
            print(f"✅ Found {len(exams)} exams for formation_id={formation_id}")
            
            # Convert dates and times to strings
            for exam in exams:
                if 'date_exam' in exam and exam['date_exam']:
                    exam['date_exam'] = str(exam['date_exam'])
                if 'heure_debut' in exam and exam['heure_debut']:
                    exam['heure_debut'] = str(exam['heure_debut'])
            
            return {
                "success": True,
                "count": len(exams),
                "exams": exams,
                "formation_id": formation_id,
                "formation_name": formation_name,
                "groupe_id": groupe_id
            }
            
    except HTTPException:
        raise
    except Error as e:
        print(f"❌ Database error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        print(f"❌ Unexpected error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Server error: {str(e)}")


@app.get("/api/debug/student/{student_id}")
async def debug_student(student_id: int):
    """
    Debug endpoint to check if student exists and get their data
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            
            # Check utilisateurs
            cursor.execute("""
                SELECT id, email, role 
                FROM utilisateurs 
                WHERE id = %s
            """, (student_id,))
            user = cursor.fetchone()
            
            # Check etudiants
            cursor.execute("""
                SELECT e.id, e.nom, e.prenom, e.formation_id, e.groupe_id, 
                       f.nom AS formation_name, g.nom AS groupe_name
                FROM etudiants e
                LEFT JOIN formations f ON f.id = e.formation_id
                LEFT JOIN groupes g ON g.id = e.groupe_id
                WHERE e.id = %s
            """, (student_id,))
            student = cursor.fetchone()
            
            cursor.close()
            
            return {
                "user_id": student_id,
                "user_exists": user is not None,
                "user_data": user,
                "student_exists": student is not None,
                "student_data": student
            }
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.get("/api/exams/teacher/{teacher_id}")
async def get_teacher_exams(
    teacher_id: int,
    annee: str,
    semester: str
):
    """
    Get PUBLISHED exams for a specific teacher
    Filters by teacher's surveillances (exams where they are assigned)
    Only returns exams with status 'PUBLIE' (approved by Doyen)
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            
            # Verify teacher exists
            cursor.execute("SELECT id FROM enseignants WHERE id = %s", (teacher_id,))
            if not cursor.fetchone():
                raise HTTPException(status_code=404, detail="Teacher not found")
            
            # Get exams where teacher is assigned
            cursor.callproc("sp_get_teacher_exams", [
                annee, 
                semester, 
                teacher_id
            ])
            
            exams = []
            for result in cursor.stored_results():
                exams = result.fetchall()
            
            cursor.close()
            
            # Convert dates and times to strings
            for exam in exams:
                if 'date_exam' in exam and exam['date_exam']:
                    exam['date_exam'] = str(exam['date_exam'])
                if 'heure_debut' in exam and exam['heure_debut']:
                    exam['heure_debut'] = str(exam['heure_debut'])
            
            return {
                "success": True,
                "count": len(exams),
                "exams": exams,
                "teacher_id": teacher_id
            }
            
    except HTTPException:
        raise
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.get("/api/debug/student-by-email/{email}")
async def debug_student_by_email(email: str):
    """
    Debug endpoint to check student by email (e.g., ahmed.benamar@etu.univ.dz)
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            
            # Decode URL-encoded email
            import urllib.parse
            email = urllib.parse.unquote(email)
            
            # Check utilisateurs by email
            cursor.execute("""
                SELECT u.id, u.email, u.role 
                FROM utilisateurs u
                WHERE u.email = %s
            """, (email,))
            user = cursor.fetchone()
            
            if not user:
                return {
                    "email": email,
                    "user_exists": False,
                    "message": "User not found with this email",
                    "suggestion": "Check if the email exists in the utilisateurs table"
                }
            
            user_id = user['id']
            
            # Check etudiants
            cursor.execute("""
                SELECT e.id, e.nom, e.prenom, e.formation_id, e.groupe_id, 
                       f.nom AS formation_name, f.code AS formation_code,
                       g.nom AS groupe_name, g.id AS groupe_id
                FROM etudiants e
                LEFT JOIN formations f ON f.id = e.formation_id
                LEFT JOIN groupes g ON g.id = e.groupe_id
                WHERE e.id = %s
            """, (user_id,))
            student = cursor.fetchone()
            
            # Check if there are any published exams for this formation
            exams_count = 0
            all_exams_count = 0
            if student and student.get('formation_id'):
                # Count published exams
                cursor.execute("""
                    SELECT COUNT(DISTINCT se.id) as exam_count
                    FROM schedule_examens se
                    JOIN schedules s ON s.id = se.schedule_id
                    JOIN examens e ON e.id = se.examen_id
                    WHERE s.annee_universitaire = '2025-2026'
                      AND s.semester = 'S1'
                      AND s.statut = 'PUBLIE'
                      AND e.formation_id = %s
                """, (student['formation_id'],))
                result = cursor.fetchone()
                exams_count = result['exam_count'] if result else 0
                
                # Count all exams (any status)
                cursor.execute("""
                    SELECT COUNT(DISTINCT se.id) as exam_count
                    FROM schedule_examens se
                    JOIN schedules s ON s.id = se.schedule_id
                    JOIN examens e ON e.id = se.examen_id
                    WHERE s.annee_universitaire = '2025-2026'
                      AND s.semester = 'S1'
                      AND e.formation_id = %s
                """, (student['formation_id'],))
                result = cursor.fetchone()
                all_exams_count = result['exam_count'] if result else 0
            
            # Check schedule statuses
            schedule_statuses = []
            if student and student.get('formation_id'):
                cursor.execute("""
                    SELECT DISTINCT s.statut, COUNT(*) as count
                    FROM schedules s
                    JOIN schedule_examens se ON se.schedule_id = s.id
                    JOIN examens e ON e.id = se.examen_id
                    WHERE s.annee_universitaire = '2025-2026'
                      AND s.semester = 'S1'
                      AND e.formation_id = %s
                    GROUP BY s.statut
                """, (student['formation_id'],))
                schedule_statuses = cursor.fetchall()
            
            cursor.close()
            
            return {
                "email": email,
                "user_id": user_id,
                "user_exists": True,
                "user_data": user,
                "student_exists": student is not None,
                "student_data": student,
                "published_exams_count": exams_count,
                "all_exams_count": all_exams_count,
                "schedule_statuses": schedule_statuses,
                "diagnosis": {
                    "has_formation": student is not None and student.get('formation_id') is not None,
                    "has_published_exams": exams_count > 0,
                    "has_any_exams": all_exams_count > 0,
                    "issue": "No published exams found" if (student and student.get('formation_id') and exams_count == 0) else "OK" if exams_count > 0 else "Student has no formation assigned" if (student and not student.get('formation_id')) else "Student record not found"
                }
            }
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.get("/api/test/student-exams-example")
async def get_test_student_exams_example():
    """
    Returns example exam data for testing purposes
    This is a legitimate example of what the API should return when working correctly
    """
    from datetime import datetime, timedelta
    
    # Create example exam data
    example_exams = [
        {
            "date_exam": str(datetime.now() + timedelta(days=7)),
            "heure_debut": "08:00:00",
            "matiere": "Database Systems",
            "matiere_code": "DB101",
            "duree_minutes": 120,
            "formation": "Licence Informatique",
            "formation_code": "L1-INFO",
            "niveau": "L1",
            "department": "Informatique",
            "groupe": "Groupe A",
            "groupe_id": 1,
            "salle": "Amphi A",
            "salle_capacite": 200,
            "surveillant": "Dr. Ahmed Benali, Dr. Fatima Khelifi",
            "schedule_id": 1,
            "schedule_exam_id": 1,
            "exam_groupe_id": 1,
            "lieu_id": 1,
            "formation_id": 1
        },
        {
            "date_exam": str(datetime.now() + timedelta(days=10)),
            "heure_debut": "10:00:00",
            "matiere": "Web Development",
            "matiere_code": "WEB101",
            "duree_minutes": 120,
            "formation": "Licence Informatique",
            "formation_code": "L1-INFO",
            "niveau": "L1",
            "department": "Informatique",
            "groupe": "Groupe A",
            "groupe_id": 1,
            "salle": "Lab 201",
            "salle_capacite": 50,
            "surveillant": "Dr. Mohamed Ali",
            "schedule_id": 1,
            "schedule_exam_id": 2,
            "exam_groupe_id": 1,
            "lieu_id": 2,
            "formation_id": 1
        },
        {
            "date_exam": str(datetime.now() + timedelta(days=14)),
            "heure_debut": "14:00:00",
            "matiere": "Algorithms",
            "matiere_code": "ALG101",
            "duree_minutes": 180,
            "formation": "Licence Informatique",
            "formation_code": "L1-INFO",
            "niveau": "L1",
            "department": "Informatique",
            "groupe": "Groupe A",
            "groupe_id": 1,
            "salle": "Room 302",
            "salle_capacite": 30,
            "surveillant": "Dr. Sara Benali, Dr. Youssef Khelifi",
            "schedule_id": 1,
            "schedule_exam_id": 3,
            "exam_groupe_id": 1,
            "lieu_id": 3,
            "formation_id": 1
        }
    ]
    
    return {
        "success": True,
        "count": len(example_exams),
        "exams": example_exams,
        "formation_id": 1,
        "formation_name": "Licence Informatique",
        "groupe_id": 1,
        "note": "This is example data for testing. Replace this endpoint call with the actual student endpoint once the database is properly configured."
    }


# ============================================
# DASHBOARD ENDPOINTS
# ============================================

@app.get("/api/dashboard/stats")
async def get_dashboard_stats(annee: str, semester: str):
    """Get overall dashboard statistics"""
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            cursor.callproc("sp_get_dashboard_stats", [annee, semester])
            stats = None
            for result in cursor.stored_results():
                stats = result.fetchone()
            cursor.close()
            if not stats:
                return {"success": True, "stats": {"total_exams_target": 0, "total_exams_generated": 0, "total_conflicts": 0, "critical_conflicts": 0, "medium_conflicts": 0, "low_conflicts": 0, "pending_formations": 0}}
            return {"success": True, "stats": stats}
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@app.get("/api/dashboard/departments")
async def get_department_stats(annee: str, semester: str):
    """Get per-department statistics"""
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            cursor.callproc("sp_get_department_stats", [annee, semester])
            departments = []
            for result in cursor.stored_results():
                departments = result.fetchall()
            cursor.close()
            return {"success": True, "count": len(departments), "departments": departments}
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@app.get("/api/dashboard/conflicts-by-type")
async def get_conflicts_by_type(annee: str, semester: str):
    """Get conflicts breakdown by type"""
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            cursor.callproc("sp_get_conflicts_by_type", [annee, semester])
            conflicts = []
            for result in cursor.stored_results():
                conflicts = result.fetchall()
            cursor.close()
            return {"success": True, "count": len(conflicts), "conflicts": conflicts}
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@app.get("/api/dashboard/recent-activities")
async def get_recent_activities(annee: str, semester: str, limit: int = 10):
    """Get recent scheduling activities"""
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            cursor.callproc("sp_get_recent_activities", [annee, semester, limit])
            activities = []
            for result in cursor.stored_results():
                activities = result.fetchall()
            cursor.close()
            for activity in activities:
                if 'time' in activity and activity['time']:
                    activity['time'] = str(activity['time'])
            return {"success": True, "count": len(activities), "activities": activities}
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


# ============================================
# APPROVAL ENDPOINTS
# ============================================

@app.get("/api/approvals/chef/{chef_id}")
async def get_chef_approvals(
    chef_id: int,
    annee: str,
    semester: str
):
    """
    Get all schedules pending approval for a specific Chef de Département
    Returns schedules with status 'GENERE' (pending chef approval)
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            
            cursor.callproc("sp_get_schedules_for_chef", [chef_id, annee, semester])
            
            schedules = []
            for result in cursor.stored_results():
                schedules = result.fetchall()
            
            cursor.close()
            
            # Check if error response
            if schedules and schedules[0].get('status') == 'ERROR':
                raise HTTPException(status_code=400, detail=schedules[0].get('message'))
            
            # Convert datetime to string
            for schedule in schedules:
                if 'created_at' in schedule and schedule['created_at']:
                    schedule['created_at'] = str(schedule['created_at'])
            
            return {
                "success": True,
                "count": len(schedules),
                "schedules": schedules
            }
            
    except HTTPException:
        raise
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.get("/api/approvals/doyen")
async def get_doyen_approvals(
    annee: str,
    semester: str
):
    """
    Get all schedules approved by Chef, pending Doyen approval
    Returns schedules with status 'VALIDE_DEPARTEMENT'
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            
            cursor.callproc("sp_get_schedules_for_doyen", [annee, semester])
            
            schedules = []
            for result in cursor.stored_results():
                schedules = result.fetchall()
            
            cursor.close()
            
            # Convert datetime to string
            for schedule in schedules:
                if 'created_at' in schedule and schedule['created_at']:
                    schedule['created_at'] = str(schedule['created_at'])
                if 'chef_approved_at' in schedule and schedule['chef_approved_at']:
                    schedule['chef_approved_at'] = str(schedule['chef_approved_at'])
            
            return {
                "success": True,
                "count": len(schedules),
                "schedules": schedules
            }
            
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.get("/api/approvals/details/{schedule_id}")
async def get_approval_details(schedule_id: int):
    """
    Get detailed approval information for a specific schedule
    Returns schedule info + approval history
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            
            cursor.callproc("sp_get_approval_details", [schedule_id])
            
            # First result set: schedule details
            schedule_info = None
            for result in cursor.stored_results():
                schedule_info = result.fetchone()
                break
            
            # Second result set: approval history
            approval_history = []
            for result in cursor.stored_results():
                approval_history = result.fetchall()
            
            cursor.close()
            
            if not schedule_info:
                raise HTTPException(status_code=404, detail="Schedule not found")
            
            # Convert datetime to string
            if 'schedule_created_at' in schedule_info and schedule_info['schedule_created_at']:
                schedule_info['schedule_created_at'] = str(schedule_info['schedule_created_at'])
            
            for approval in approval_history:
                if 'approved_at' in approval and approval['approved_at']:
                    approval['approved_at'] = str(approval['approved_at'])
            
            return {
                "success": True,
                "schedule": schedule_info,
                "approval_history": approval_history
            }
            
    except HTTPException:
        raise
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.post("/api/approvals/chef/approve", response_model=ApprovalResponse)
async def chef_approve_schedule(request: ChefApprovalRequest):
    """
    Chef de Département approves or rejects a schedule
    
    Status transitions:
    - APPROVE: GENERE → VALIDE_DEPARTEMENT
    - REJECT: GENERE → BROUILLON
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            
            cursor.callproc(
                "sp_chef_approve_schedule",
                [
                    request.schedule_id,
                    request.chef_id,
                    request.action,
                    request.comment
                ]
            )
            
            result = None
            for res in cursor.stored_results():
                result = res.fetchone()
            
            cursor.close()
            
            if result and result.get('status') == 'ERROR':
                raise HTTPException(status_code=400, detail=result.get('message'))
            
            return ApprovalResponse(
                status=result.get('status', 'SUCCESS'),
                message=result.get('message', 'Action completed'),
                new_status=result.get('new_status')
            )
            
    except HTTPException:
        raise
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.post("/api/approvals/doyen/approve", response_model=ApprovalResponse)
async def doyen_approve_schedule(request: DoyenApprovalRequest):
    """
    Doyen or Vice-Doyen approves or rejects a schedule
    
    Status transitions:
    - APPROVE: VALIDE_DEPARTEMENT → PUBLIE
    - REJECT: VALIDE_DEPARTEMENT → GENERE
    
    Can only approve if status is VALIDE_DEPARTEMENT (Chef approved first)
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            
            cursor.callproc(
                "sp_doyen_approve_schedule",
                [
                    request.schedule_id,
                    request.doyen_id,
                    request.action,
                    request.comment
                ]
            )
            
            result = None
            for res in cursor.stored_results():
                result = res.fetchone()
            
            cursor.close()
            
            if result and result.get('status') == 'ERROR':
                raise HTTPException(
                    status_code=400, 
                    detail=result.get('message')
                )
            
            return ApprovalResponse(
                status=result.get('status', 'SUCCESS'),
                message=result.get('message', 'Action completed'),
                new_status=result.get('new_status')
            )
            
    except HTTPException:
        raise
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.get("/api/approvals/status/{schedule_id}")
async def get_approval_status(schedule_id: int):
    """Quick status check for a schedule"""
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            
            query = """
                SELECT 
                    s.id, s.statut, f.nom as formation, d.nom as department, s.created_at,
                    (SELECT action FROM schedule_approvals sa 
                     WHERE sa.schedule_id = s.id AND sa.approval_level = 'CHEF_DEPARTEMENT'
                     ORDER BY sa.approved_at DESC LIMIT 1) as last_chef_action,
                    (SELECT approved_at FROM schedule_approvals sa 
                     WHERE sa.schedule_id = s.id AND sa.approval_level = 'CHEF_DEPARTEMENT'
                     ORDER BY sa.approved_at DESC LIMIT 1) as last_chef_date,
                    (SELECT action FROM schedule_approvals sa 
                     WHERE sa.schedule_id = s.id AND sa.approval_level = 'DOYEN'
                     ORDER BY sa.approved_at DESC LIMIT 1) as last_doyen_action,
                    (SELECT approved_at FROM schedule_approvals sa 
                     WHERE sa.schedule_id = s.id AND sa.approval_level = 'DOYEN'
                     ORDER BY sa.approved_at DESC LIMIT 1) as last_doyen_date
                FROM schedules s
                JOIN formations f ON f.id = s.formation_id
                JOIN departements d ON d.id = f.department_id
                WHERE s.id = %s
            """
            
            cursor.execute(query, (schedule_id,))
            status = cursor.fetchone()
            cursor.close()
            
            if not status:
                raise HTTPException(status_code=404, detail="Schedule not found")
            
            datetime_fields = ['created_at', 'last_chef_date', 'last_doyen_date']
            for field in datetime_fields:
                if status.get(field):
                    status[field] = str(status[field])
            
            return {"success": True, "status": status}
            
    except HTTPException:
        raise
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.get("/api/approvals/statistics")
async def get_approval_statistics(annee: str, semester: str):
    """Get approval statistics for dashboard"""
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            cursor.callproc("sp_get_approval_statistics", [annee, semester])
            stats = []
            for result in cursor.stored_results():
                stats = result.fetchall()
            cursor.close()
            return {"success": True, "statistics": stats}
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.get("/api/approvals/pending-count")
async def get_pending_approval_count(user_id: int, annee: str, semester: str):
    """Get count of schedules pending approval for notification badges"""
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor(dictionary=True)
            cursor.execute("SELECT role FROM utilisateurs WHERE id = %s", (user_id,))
            user = cursor.fetchone()
            
            if not user:
                raise HTTPException(status_code=404, detail="User not found")
            
            role = user['role']
            count = 0
            
            if role == 'Chef-departement':
                cursor.execute("SELECT department_id FROM chefs_departement WHERE id = %s", (user_id,))
                dept = cursor.fetchone()
                
                if dept:
                    cursor.execute("""
                        SELECT COUNT(*) as count FROM schedules s
                        JOIN formations f ON f.id = s.formation_id
                        WHERE f.department_id = %s AND s.statut = 'GENERE'
                        AND s.annee_universitaire = %s AND s.semester = %s
                    """, (dept['department_id'], annee, semester))
                    result = cursor.fetchone()
                    count = result['count'] if result else 0
            
            elif role in ('Doyen', 'Vice-doyen'):
                cursor.execute("""
                    SELECT COUNT(*) as count FROM schedules
                    WHERE statut = 'VALIDE_DEPARTEMENT'
                    AND annee_universitaire = %s AND semester = %s
                """, (annee, semester))
                result = cursor.fetchone()
                count = result['count'] if result else 0
            
            cursor.close()
            return {"success": True, "user_id": user_id, "role": role, "pending_count": count}
            
    except HTTPException:
        raise
    except Error as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)