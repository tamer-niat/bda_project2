-- ============================================
-- EXAM SCHEDULER DATABASE - COMPLETE SCRIPT
-- WITH DYNAMIC TIME SLOTS SUPPORT
-- ============================================

CREATE DATABASE IF NOT EXISTS `exam_scheduler_db`
DEFAULT CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE `exam_scheduler_db`;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS schedule_exam_salles;
DROP TABLE IF EXISTS schedule_examens;
DROP TABLE IF EXISTS schedules;
DROP TABLE IF EXISTS schedule_conflicts;
DROP TABLE IF EXISTS surveillances;
DROP TABLE IF EXISTS examens;
DROP TABLE IF EXISTS formation_matieres;
DROP TABLE IF EXISTS etudiants;
DROP TABLE IF EXISTS groupes;
DROP TABLE IF EXISTS formations;
DROP TABLE IF EXISTS matieres;
DROP TABLE IF EXISTS lieux_examen;
DROP TABLE IF EXISTS enseignants;
DROP TABLE IF EXISTS chefs_departement;
DROP TABLE IF EXISTS admins_examens;
DROP TABLE IF EXISTS doyens;
DROP TABLE IF EXISTS departements;
DROP TABLE IF EXISTS utilisateurs;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- TABLES
-- ============================================

CREATE TABLE `utilisateurs` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `email` VARCHAR(100) NOT NULL UNIQUE,
  `password` VARCHAR(255) NOT NULL,
  `role` ENUM(
    'Doyen',
    'Vice-doyen',
    'Chef-departement',
    'Admin-examens',
    'Enseignant',
    'Etudiant'
  ) NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_user_role` (`role`),
  INDEX `idx_user_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE `departements` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `nom` VARCHAR(150) NOT NULL,
  `code` VARCHAR(20) UNIQUE,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `formations` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `nom` VARCHAR(150) NOT NULL,
  `code` VARCHAR(50) NOT NULL UNIQUE,
  `cycle` ENUM('Licence', 'Master', 'Doctorat') NOT NULL,
  `niveau` ENUM('L1', 'L2', 'L3', 'M1', 'M2') NOT NULL,
  `semester` ENUM('S1', 'S2') NOT NULL,
  `department_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_formations_dept`
    FOREIGN KEY (`department_id`)
    REFERENCES `departements`(`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `groupes` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `nom` VARCHAR(50) NOT NULL,         
  `formation_id` INT NOT NULL,

  PRIMARY KEY (`id`),

  CONSTRAINT `fk_groupes_formation`
    FOREIGN KEY (`formation_id`)
    REFERENCES `formations`(`id`)
    ON DELETE CASCADE,

  CONSTRAINT `uk_group_unique`
    UNIQUE (`nom`, `formation_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `etudiants` (
  `id` INT NOT NULL PRIMARY KEY,
  `nom` VARCHAR(100) NOT NULL,
  `prenom` VARCHAR(100) NOT NULL,
  `formation_id` INT NOT NULL,
  `groupe_id` INT NOT NULL,
  `promo` VARCHAR(50),
  `date_naissance` DATE,

  CONSTRAINT `fk_etudiants_user`
    FOREIGN KEY (`id`)
    REFERENCES `utilisateurs`(`id`)
    ON DELETE CASCADE,

  CONSTRAINT `fk_etudiants_formation`
    FOREIGN KEY (`formation_id`)
    REFERENCES `formations`(`id`)
    ON DELETE CASCADE,

  CONSTRAINT `fk_etudiants_groupe`
    FOREIGN KEY (`groupe_id`)
    REFERENCES `groupes`(`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE `doyens` (
  `id` INT NOT NULL PRIMARY KEY,
  `nom` VARCHAR(100) NOT NULL,
  `prenom` VARCHAR(100) NOT NULL,
  CONSTRAINT `fk_doyens_utilisateurs`
    FOREIGN KEY (`id`)
    REFERENCES `utilisateurs`(`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `admins_examens` (
  `id` INT NOT NULL PRIMARY KEY,
  `nom` VARCHAR(100) NOT NULL,
  `prenom` VARCHAR(100) NOT NULL,
  CONSTRAINT `fk_admins_examens_utilisateurs`
    FOREIGN KEY (`id`)
    REFERENCES `utilisateurs`(`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `chefs_departement` (
  `id` INT NOT NULL PRIMARY KEY,
  `nom` VARCHAR(100) NOT NULL,
  `prenom` VARCHAR(100) NOT NULL,
  `department_id` INT DEFAULT NULL,
  CONSTRAINT `fk_chefs_dep_user`
    FOREIGN KEY (`id`)
    REFERENCES `utilisateurs`(`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_chefs_dep_dept`
    FOREIGN KEY (`department_id`)
    REFERENCES `departements`(`id`)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `enseignants` (
  `id` INT NOT NULL PRIMARY KEY,
  `nom` VARCHAR(100) NOT NULL,
  `prenom` VARCHAR(100) NOT NULL,
  `department_id` INT DEFAULT NULL,
  `speciality` VARCHAR(100),
  `grade` ENUM(
    'Professeur',
    'Maitre de conferences A',
    'Maitre de conferences B',
    'Maitre assistant A',
    'Maitre assistant B'
  ),
  CONSTRAINT `fk_enseignants_user`
    FOREIGN KEY (`id`)
    REFERENCES `utilisateurs`(`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_enseignants_dept`
    FOREIGN KEY (`department_id`)
    REFERENCES `departements`(`id`)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `matieres` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `nom` VARCHAR(150) NOT NULL,
  `code` VARCHAR(50) NOT NULL UNIQUE,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `formation_matieres` (
  `formation_id` INT NOT NULL,
  `matiere_id` INT NOT NULL,
  PRIMARY KEY (`formation_id`, `matiere_id`),
  CONSTRAINT `fk_fm_formation`
    FOREIGN KEY (`formation_id`)
    REFERENCES `formations`(`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_fm_matiere`
    FOREIGN KEY (`matiere_id`)
    REFERENCES `matieres`(`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE `examens` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `formation_id` INT NOT NULL,
  `matiere_id` INT NOT NULL,
  `duree_minutes` INT NOT NULL,
  `annee_universitaire` VARCHAR(20) NOT NULL,
  `semester` ENUM('S1', 'S2') NOT NULL,

  PRIMARY KEY (`id`),

  CONSTRAINT `uk_exam_unique`
    UNIQUE (`formation_id`, `matiere_id`, `annee_universitaire`, `semester`),

  CONSTRAINT `fk_exam_fm`
    FOREIGN KEY (`formation_id`, `matiere_id`)
    REFERENCES `formation_matieres`(`formation_id`, `matiere_id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE `lieux_examen` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `nom` VARCHAR(50) NOT NULL,
  `code` VARCHAR(20) NOT NULL UNIQUE,
  `capacite` INT NOT NULL CHECK (`capacite` > 0),
  `type` ENUM('Amphitheatre', 'Salle', 'Labo') NOT NULL,
  `department_id` INT DEFAULT NULL,
  `disponible` BOOLEAN DEFAULT TRUE,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_lieux_dept`
    FOREIGN KEY (`department_id`)
    REFERENCES `departements`(`id`)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE surveillances (
  examen_id INT NOT NULL,
  groupe_id INT NOT NULL,
  enseignant_id INT NOT NULL,
  
  PRIMARY KEY (examen_id, groupe_id),
  
  FOREIGN KEY (examen_id) REFERENCES examens(id) ON DELETE CASCADE,
  FOREIGN KEY (groupe_id) REFERENCES groupes(id) ON DELETE CASCADE,
  FOREIGN KEY (enseignant_id) REFERENCES enseignants(id) ON DELETE CASCADE
);


CREATE TABLE `schedules` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `formation_id` INT NOT NULL,
  `annee_universitaire` VARCHAR(20) NOT NULL,
  `semester` ENUM('S1', 'S2') NOT NULL,

  `statut` ENUM(
    'BROUILLON',
    'GENERE',
    'VALIDE_DEPARTEMENT',
    'VALIDE_DOYEN',
    'PUBLIE'
  ) DEFAULT 'BROUILLON',

  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `created_by` INT DEFAULT NULL,

  PRIMARY KEY (`id`),

  CONSTRAINT `fk_schedule_formation`
    FOREIGN KEY (`formation_id`)
    REFERENCES `formations`(`id`)
    ON DELETE CASCADE,

  CONSTRAINT `fk_schedule_creator`
    FOREIGN KEY (`created_by`)
    REFERENCES `utilisateurs`(`id`)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE `schedule_examens` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `schedule_id` INT NOT NULL,
  `examen_id` INT NOT NULL,

  `date_exam` DATE NOT NULL,
  `heure_debut` TIME NOT NULL,

  PRIMARY KEY (`id`),

  -- EXACTLY ONE EXAM PER DAY PER SCHEDULE
  CONSTRAINT `uk_schedule_one_exam_per_day`
    UNIQUE (`schedule_id`, `date_exam`),

  CONSTRAINT `uk_exam_once_per_schedule`
    UNIQUE (`schedule_id`, `examen_id`),

  CONSTRAINT `fk_se_schedule`
    FOREIGN KEY (`schedule_id`)
    REFERENCES `schedules`(`id`)
    ON DELETE CASCADE,

  CONSTRAINT `fk_se_examen`
    FOREIGN KEY (`examen_id`)
    REFERENCES `examens`(`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `schedule_exam_salles` (
  `schedule_exam_id` INT NOT NULL,
  `groupe_id` INT NOT NULL,
  `lieu_id` INT NOT NULL,

  PRIMARY KEY (`schedule_exam_id`, `groupe_id`),

  CONSTRAINT `fk_ses_schedule_exam`
    FOREIGN KEY (`schedule_exam_id`)
    REFERENCES `schedule_examens`(`id`)
    ON DELETE CASCADE,

  CONSTRAINT `fk_ses_groupe`
    FOREIGN KEY (`groupe_id`)
    REFERENCES `groupes`(`id`)
    ON DELETE CASCADE,

  CONSTRAINT `fk_ses_lieu`
    FOREIGN KEY (`lieu_id`)
    REFERENCES `lieux_examen`(`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE schedule_conflicts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    examen_id INT NULL,
    formation_id INT NULL,
    enseignant_id INT NULL,
    lieu_id INT NULL,
    conflict_type ENUM(
        'STUDENT_OVERLOAD',
        'TEACHER_OVERLOAD',
        'ROOM_CAPACITY'
    ) NOT NULL,
    conflict_reason TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT `fk_conflict_examen`
        FOREIGN KEY (`examen_id`)
        REFERENCES `examens`(`id`)
        ON DELETE SET NULL,
    
    CONSTRAINT `fk_conflict_formation`
        FOREIGN KEY (`formation_id`)
        REFERENCES `formations`(`id`)
        ON DELETE SET NULL,
        
    CONSTRAINT `fk_conflict_enseignant`
        FOREIGN KEY (`enseignant_id`)
        REFERENCES `enseignants`(`id`)
        ON DELETE SET NULL,
        
    CONSTRAINT `fk_conflict_lieu`
        FOREIGN KEY (`lieu_id`)
        REFERENCES `lieux_examen`(`id`)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add this after schedule_conflicts table creation
 DROP TABLE IF EXISTS schedule_approvals;
 
CREATE TABLE `schedule_approvals` (
    id INT AUTO_INCREMENT PRIMARY KEY,
    schedule_id INT NOT NULL,
    
    -- Approval level
    approval_level ENUM('CHEF_DEPARTEMENT', 'DOYEN') NOT NULL,
    
    -- Approver info
    approver_id INT NOT NULL,
    action ENUM('APPROVED', 'REJECTED') NOT NULL,
    comment TEXT NULL,
    
    -- Timestamps
    approved_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT fk_approval_schedule FOREIGN KEY (schedule_id) 
        REFERENCES schedules(id) ON DELETE CASCADE,
    CONSTRAINT fk_approval_user FOREIGN KEY (approver_id) 
        REFERENCES utilisateurs(id) ON DELETE CASCADE,
    
    -- Index for querying
    INDEX idx_approval_schedule (schedule_id, approval_level)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- ============================================
-- INSERT DATA
-- ============================================

-- UTILISATEURS
INSERT INTO `utilisateurs` (`email`, `password`, `role`) VALUES
-- Doyen
('doyen@univ.dz', 'doyen123', 'Doyen'),

-- Vice-doyen
('vice.doyen@univ.dz', 'vice123', 'Vice-doyen'),

-- Admin examens
('admin.examen@univ.dz', 'admin123', 'Admin-examens'),

-- Chefs de département
('chef.info@univ.dz', 'chef123', 'Chef-departement'),
('chef.math@univ.dz', 'chef123', 'Chef-departement'),
('chef.phys@univ.dz', 'chef123', 'Chef-departement'),
('chef.chim@univ.dz', 'chef123', 'Chef-departement'),
('chef.bio@univ.dz', 'chef123', 'Chef-departement'),

-- Enseignants (id 9-23)
('benali@univ.dz', 'ens123', 'Enseignant'),
('ahmed@univ.dz', 'ens123', 'Enseignant'),
('saidi@univ.dz', 'ens123', 'Enseignant'),
('khelifi@univ.dz', 'ens123', 'Enseignant'),
('mansour@univ.dz', 'ens123', 'Enseignant'),
('hamdi@univ.dz', 'ens123', 'Enseignant'),
('cherif@univ.dz', 'ens123', 'Enseignant'),
('said@univ.dz', 'ens123', 'Enseignant'),
('salem@univ.dz', 'ens123', 'Enseignant'),
('mansouri@univ.dz', 'ens123', 'Enseignant'),
('baghdad@univ.dz', 'ens123', 'Enseignant'),
('zerrouki@univ.dz', 'ens123', 'Enseignant'),
('amara@univ.dz', 'ens123', 'Enseignant'),
('bouazza@univ.dz', 'ens123', 'Enseignant'),
('bouraoui@univ.dz', 'ens123', 'Enseignant'),

-- Étudiants (id 24-31)
('ahmed.benamar@etu.univ.dz', 'etu123', 'Etudiant'),
('fatima.mohamed@etu.univ.dz', 'etu123', 'Etudiant'),
('karim.ouali@etu.univ.dz', 'etu123', 'Etudiant'),
('sarah.belkacem@etu.univ.dz', 'etu123', 'Etudiant'),
('youcef.tahri@etu.univ.dz', 'etu123', 'Etudiant'),
('amina.kadri@etu.univ.dz', 'etu123', 'Etudiant'),
('mehdi.cherif@etu.univ.dz', 'etu123', 'Etudiant'),
('nadia.bouaziz@etu.univ.dz', 'etu123', 'Etudiant');

-- DEPARTEMENTS
INSERT INTO `departements` (`nom`, `code`) VALUES
('Informatique', 'INFO'),
('Mathématiques', 'MATH'),
('Physique', 'PHYS'),
('Chimie', 'CHIM'),
('Biologie', 'BIO');

-- DOYENS
INSERT INTO `doyens` (`id`, `nom`, `prenom`) VALUES
(1, 'Benali', 'Mohammed');

-- ADMINS EXAMENS
INSERT INTO `admins_examens` (`id`, `nom`, `prenom`) VALUES
(3, 'Zerrouki', 'Fatima');

-- CHEFS DEPARTEMENT
INSERT INTO `chefs_departement` (`id`, `nom`, `prenom`, `department_id`) VALUES
(4, 'Saidi', 'Ahmed', 1),
(5, 'Khelifi', 'Rachid', 2),
(6, 'Mansour', 'Karim', 3),
(7, 'Hamdi', 'Nadia', 4),
(8, 'Cherif', 'Yacine', 5);

-- ENSEIGNANTS
INSERT INTO `enseignants` (`id`, `nom`, `prenom`, `department_id`, `speciality`, `grade`) VALUES
-- Informatique
(9, 'Benali', 'Farid', 1, 'Algorithmes', 'Professeur'),
(10, 'Ahmed', 'Salim', 1, 'Base de données', 'Maitre de conferences A'),
(11, 'Saidi', 'Khaled', 1, 'Intelligence Artificielle', 'Maitre de conferences B'),
(12, 'Khelifi', 'Mourad', 1, 'Réseaux', 'Maitre assistant A'),

-- Mathématiques
(13, 'Mansour', 'Ali', 2, 'Analyse', 'Professeur'),
(14, 'Hamdi', 'Rachida', 2, 'Algèbre', 'Maitre de conferences A'),
(15, 'Bouraoui', 'Tarek', 2, 'Probabilités', 'Maitre assistant B'),

-- Physique
(16, 'Cherif', 'Nabil', 3, 'Mécanique quantique', 'Professeur'),
(17, 'Said', 'Leila', 3, 'Électromagnétisme', 'Maitre de conferences A'),

-- Chimie
(18, 'Salem', 'Zineb', 4, 'Chimie organique', 'Professeur'),
(19, 'Mansouri', 'Hichem', 4, 'Chimie analytique', 'Maitre de conferences B'),

-- Biologie
(20, 'Baghdad', 'Malika', 5, 'Génétique', 'Maitre de conferences A'),
(21, 'Zerrouki', 'Nassim', 5, 'Biologie moléculaire', 'Maitre assistant A'),
(22, 'Amara', 'Khadija', 5, 'Écologie', 'Maitre assistant B'),
(23, 'Bouazza', 'Bilal', 5, 'Microbiologie', 'Maitre assistant B');

-- FORMATIONS
INSERT INTO `formations`
(`nom`, `code`, `cycle`, `niveau`, `semester`, `department_id`) VALUES

-- Informatique
('Licence Informatique', 'L3-INFO', 'Licence', 'L3', 'S1', 1),
('Master Intelligence Artificielle', 'M1-IA', 'Master', 'M1', 'S1', 1),
('Master Réseaux et Sécurité', 'M1-RS', 'Master', 'M1', 'S1', 1),

-- Mathématiques
('Licence Mathématiques', 'L3-MATH', 'Licence', 'L3', 'S1', 2),
('Master Mathématiques Appliquées', 'M1-MA', 'Master', 'M1', 'S1', 2),

-- Physique
('Licence Physique', 'L3-PHYS', 'Licence', 'L3', 'S1', 3),
('Master Physique Théorique', 'M1-PT', 'Master', 'M1', 'S1', 3),

-- Chimie
('Licence Chimie', 'L3-CHIM', 'Licence', 'L3', 'S1', 4),
('Master Chimie Organique', 'M1-CO', 'Master', 'M1', 'S1', 4),

-- Biologie
('Licence Biologie', 'L3-BIO', 'Licence', 'L3', 'S1', 5),
('Master Biotechnologie', 'M1-BIOTECH', 'Master', 'M1', 'S1', 5);

-- GROUPES
INSERT INTO `groupes` (`nom`, `formation_id`) VALUES
-- Licence Informatique
('G1', 1), ('G2', 1),

-- Master IA
('G1', 2),

-- Master Réseaux
('G1', 3),

-- Licence Mathématiques
('G1', 4), ('G2', 4),

-- Master Mathématiques Appliquées
('G1', 5),

-- Licence Physique
('G1', 6), ('G2', 6),

-- Master Physique Théorique
('G1', 7),

-- Licence Chimie
('G1', 8),

-- Master Chimie Organique
('G1', 9),

-- Licence Biologie
('G1', 10), ('G2', 10),

-- Master Biotechnologie
('G1', 11);

-- ETUDIANTS
INSERT INTO etudiants
(id, nom, prenom, formation_id, groupe_id, promo, date_naissance)
VALUES
-- Licence Informatique
(24, 'Benamar', 'Ahmed', 1, 1, '2025-2026', '2003-05-15'),
(25, 'Mohamed', 'Fatima', 1, 1, '2025-2026', '2003-08-22'),
(26, 'Ouali', 'Karim', 1, 2, '2025-2026', '2003-03-10'),
(27, 'Belkacem', 'Sarah', 1, 2, '2025-2026', '2003-11-30'),

-- Master IA
(28, 'Tahri', 'Youcef', 2, 3, '2025-2026', '2001-07-18'),
(29, 'Kadri', 'Amina', 2, 3, '2025-2026', '2001-09-25'),

-- Master Réseaux
(30, 'Cherif', 'Mehdi', 3, 4, '2025-2026', '2001-12-05'),
(31, 'Bouaziz', 'Nadia', 3, 4, '2025-2026', '2002-02-14');

-- LIEUX EXAMEN
INSERT INTO `lieux_examen` (`nom`, `code`, `capacite`, `type`, `department_id`, `disponible`) VALUES
-- Amphithéâtres
('Amphithéâtre A', 'AMPHI-A', 300, 'Amphitheatre', NULL, TRUE),
('Amphithéâtre B', 'AMPHI-B', 250, 'Amphitheatre', NULL, TRUE),
('Amphithéâtre C', 'AMPHI-C', 200, 'Amphitheatre', NULL, TRUE),

-- Salles Informatique
('Salle Info 1', 'INFO-S1', 40, 'Salle', 1, TRUE),
('Salle Info 2', 'INFO-S2', 40, 'Salle', 1, TRUE),
('Salle Info 3', 'INFO-S3', 35, 'Salle', 1, TRUE),

-- Salles Mathématiques
('Salle Math 1', 'MATH-S1', 50, 'Salle', 2, TRUE),
('Salle Math 2', 'MATH-S2', 45, 'Salle', 2, TRUE),

-- Salles Physique
('Salle Physique 1', 'PHYS-S1', 45, 'Salle', 3, TRUE),
('Labo Physique', 'PHYS-L1', 25, 'Labo', 3, TRUE),

-- Salles Chimie
('Salle Chimie 1', 'CHIM-S1', 40, 'Salle', 4, TRUE),
('Labo Chimie 1', 'CHIM-L1', 20, 'Labo', 4, TRUE),
('Labo Chimie 2', 'CHIM-L2', 20, 'Labo', 4, TRUE),

-- Salles Biologie
('Salle Bio 1', 'BIO-S1', 45, 'Salle', 5, TRUE),
('Labo Bio 1', 'BIO-L1', 25, 'Labo', 5, TRUE),
('Labo Bio 2', 'BIO-L2', 25, 'Labo', 5, TRUE);

-- MATIERES
INSERT INTO `matieres` (`nom`, `code`) VALUES
-- Informatique
('Algorithmes avancés', 'INFO-301'),
('Base de données', 'INFO-302'),
('Réseaux informatiques', 'INFO-303'),
('Génie logiciel', 'INFO-304'),
('Intelligence Artificielle', 'INFO-401'),
('Machine Learning', 'INFO-402'),
('Sécurité réseau', 'INFO-403'),
('Cryptographie', 'INFO-404'),

-- Mathématiques
('Analyse fonctionnelle', 'MATH-301'),
('Algèbre linéaire', 'MATH-302'),
('Topologie', 'MATH-303'),
('Probabilités', 'MATH-304'),
('Statistiques avancées', 'MATH-401'),
('Analyse numérique', 'MATH-402'),

-- Physique
('Mécanique quantique', 'PHYS-301'),
('Thermodynamique', 'PHYS-302'),
('Électromagnétisme', 'PHYS-303'),
('Physique nucléaire', 'PHYS-401'),
('Physique des particules', 'PHYS-402'),

-- Chimie
('Chimie organique', 'CHIM-301'),
('Chimie inorganique', 'CHIM-302'),
('Chimie analytique', 'CHIM-303'),
('Spectroscopie', 'CHIM-401'),
('Synthèse organique', 'CHIM-402'),

-- Biologie
('Génétique', 'BIO-301'),
('Biologie cellulaire', 'BIO-302'),
('Biochimie', 'BIO-303'),
('Microbiologie', 'BIO-304'),
('Biologie moléculaire', 'BIO-401'),
('Génie génétique', 'BIO-402');

-- FORMATION_MATIERES
INSERT INTO `formation_matieres` (`formation_id`, `matiere_id`) VALUES
-- Licence Informatique (Formation 1)
(1, 1), (1, 2), (1, 3), (1, 4),

-- Master IA (Formation 2)
(2, 5), (2, 6),

-- Master Réseaux (Formation 3)
(3, 7), (3, 8),

-- Licence Mathématiques (Formation 4)
(4, 9), (4, 10), (4, 11), (4, 12),

-- Master Mathématiques Appliquées (Formation 5)
(5, 13), (5, 14),

-- Licence Physique (Formation 6)
(6, 15), (6, 16), (6, 17),

-- Master Physique Théorique (Formation 7)
(7, 18), (7, 19),

-- Licence Chimie (Formation 8)
(8, 20), (8, 21), (8, 22),

-- Master Chimie Organique (Formation 9)
(9, 23), (9, 24),

-- Licence Biologie (Formation 10)
(10, 25), (10, 26), (10, 27), (10, 28),

-- Master Biotechnologie (Formation 11)
(11, 29), (11, 30);

-- EXAMENS
INSERT INTO `examens` (`formation_id`, `matiere_id`, `duree_minutes`, `annee_universitaire`, `semester`) VALUES
-- Licence Informatique
(1, 1, 120, '2025-2026', 'S1'),
(1, 2, 120, '2025-2026', 'S1'),
(1, 3, 120, '2025-2026', 'S1'),
(1, 4, 120, '2025-2026', 'S1'),

-- Master IA
(2, 5, 120, '2025-2026', 'S1'),
(2, 6, 120, '2025-2026', 'S1'),

-- Master Réseaux
(3, 7, 120, '2025-2026', 'S1'),
(3, 8, 120, '2025-2026', 'S1'),
-- Licence Mathématiques
(4, 9, 120, '2025-2026', 'S1'),
(4, 10, 120, '2025-2026', 'S1'),
(4, 11, 120, '2025-2026', 'S1'),
(4, 12, 120, '2025-2026', 'S1'),

-- Master Mathématiques Appliquées
(5, 13, 120, '2025-2026', 'S1'),
(5, 14, 120, '2025-2026', 'S1'),
-- Licence Physique
(6, 15, 120, '2025-2026', 'S1'),
(6, 16, 120, '2025-2026', 'S1'),
(6, 17, 120, '2025-2026', 'S1'),

-- Master Physique Théorique
(7, 18, 120, '2025-2026', 'S1'),
(7, 19, 120, '2025-2026', 'S1'),
-- Licence Chimie
(8, 20, 120, '2025-2026', 'S1'),
(8, 21, 120, '2025-2026', 'S1'),
(8, 22, 120, '2025-2026', 'S1'),

-- Master Chimie Organique
(9, 23, 120, '2025-2026', 'S1'),
(9, 24, 120, '2025-2026', 'S1'),

-- Licence Biologie
(10, 25, 120, '2025-2026', 'S1'),
(10, 26, 120, '2025-2026', 'S1'),
(10, 27, 120, '2025-2026', 'S1'),
(10, 28, 120, '2025-2026', 'S1'),

-- Master Biotechnologie
(11, 29, 120, '2025-2026', 'S1'),
(11, 30, 120, '2025-2026', 'S1');

-- ============================================
-- STORED PROCEDURES
-- ============================================

-- Drop existing procedures
DROP PROCEDURE IF EXISTS verify_login;
DROP PROCEDURE IF EXISTS get_all_departements;
DROP PROCEDURE IF EXISTS sp_phase1_plan_time_slots;
DROP PROCEDURE IF EXISTS sp_phase2_allocate_rooms;
DROP PROCEDURE IF EXISTS sp_phase3_assign_surveillance;
DROP PROCEDURE IF EXISTS sp_phase4_persist;
DROP PROCEDURE IF EXISTS sp_generate_exam_schedule;

-- ============================================
-- LOGIN PROCEDURE
-- ============================================
DELIMITER $$

CREATE PROCEDURE `verify_login`(
    IN p_email VARCHAR(100),
    IN p_password VARCHAR(255)
)
BEGIN
    DECLARE v_user_id INT;
    DECLARE v_role VARCHAR(50);

    SELECT id, role
    INTO v_user_id, v_role
    FROM utilisateurs
    WHERE email = p_email AND password = p_password
    LIMIT 1;

    IF v_user_id IS NOT NULL THEN

        CASE v_role

            WHEN 'Etudiant' THEN
                SELECT 
                    u.id,
                    u.email,
                    u.role,
                    et.nom,
                    et.prenom,
                    et.formation_id,
                    f.nom AS formation,
                    g.id AS groupe_id,
                    g.nom AS groupe,
                    et.promo,
                    et.date_naissance
                FROM utilisateurs u
                JOIN etudiants et ON et.id = u.id
                JOIN formations f ON f.id = et.formation_id
                JOIN groupes g ON g.id = et.groupe_id
                WHERE u.id = v_user_id;

            WHEN 'Enseignant' THEN
                SELECT 
                    u.id,
                    u.email,
                    u.role,
                    ens.nom,
                    ens.prenom,
                    ens.department_id,
                    d.nom AS department,
                    ens.speciality,
                    ens.grade
                FROM utilisateurs u
                JOIN enseignants ens ON ens.id = u.id
                LEFT JOIN departements d ON d.id = ens.department_id
                WHERE u.id = v_user_id;

            WHEN 'Chef-departement' THEN
                SELECT 
                    u.id,
                    u.email,
                    u.role,
                    cd.nom,
                    cd.prenom,
                    cd.department_id,
                    d.nom AS department
                FROM utilisateurs u
                JOIN chefs_departement cd ON cd.id = u.id
                LEFT JOIN departements d ON d.id = cd.department_id
                WHERE u.id = v_user_id;

            WHEN 'Admin-examens' THEN
                SELECT 
                    u.id,
                    u.email,
                    u.role,
                    ae.nom,
                    ae.prenom
                FROM utilisateurs u
                JOIN admins_examens ae ON ae.id = u.id
                WHERE u.id = v_user_id;

            WHEN 'Doyen' THEN
                SELECT 
                    u.id,
                    u.email,
                    u.role,
                    d.nom,
                    d.prenom
                FROM utilisateurs u
                JOIN doyens d ON d.id = u.id
                WHERE u.id = v_user_id;

            WHEN 'Vice-doyen' THEN
                SELECT 
                    u.id,
                    u.email,
                    u.role
                FROM utilisateurs u
                WHERE u.id = v_user_id;

            ELSE
                SELECT 
                    NULL AS id,
                    'Rôle inconnu' AS error;
        END CASE;

    ELSE
        SELECT 
            NULL AS id,
            'Email ou mot de passe incorrect' AS error;
    END IF;
END$$

DELIMITER ;

-- ============================================
-- GET ALL DEPARTEMENTS PROCEDURE
-- ============================================
DELIMITER $$

CREATE PROCEDURE get_all_departements()
BEGIN
    SELECT 
        id,
        nom,
        code
    FROM departements
    ORDER BY nom;
END$$

DELIMITER ;



-- ============================================
-- PHASE 1: GROUPED SCHEDULING BY DEPT+NIVEAU
-- Same department + same niveau = SAME TIME SLOT
-- ============================================

-- ============================================
-- PHASE 1: GROUPED SCHEDULING BY DEPT+NIVEAU
-- Same department + same niveau = SAME TIME SLOT
-- ============================================

-- ============================================
-- PHASE 1: SIMPLE GROUPED SCHEDULING
-- Same dept+niveau get SAME time, but still 1 exam/day
-- ============================================

-- ============================================
-- PHASE 1: ABSOLUTE SIMPLEST - NO RESTRICTIONS
-- Only rule: 1 exam per day per formation
-- Everything else handled by Phase 2/3
-- ============================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_phase1_plan_time_slots$$

CREATE PROCEDURE sp_phase1_plan_time_slots(
    IN p_annee VARCHAR(20),
    IN p_semester ENUM('S1','S2'),
    IN p_start DATE,
    IN p_end DATE,
    IN p_time_slots JSON
)
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_exam INT;
    DECLARE v_form INT;
    DECLARE v_duree INT;
    DECLARE v_date DATE;
    DECLARE v_slot_index INT DEFAULT 0;
    DECLARE v_slot_count INT;
    DECLARE v_slot_start TIME;
    DECLARE v_slot_end TIME;
    DECLARE v_slot_label VARCHAR(100);
    
    DECLARE cur CURSOR FOR
        SELECT e.id, e.formation_id, e.duree_minutes
        FROM examens e
        WHERE e.annee_universitaire = p_annee
          AND e.semester = p_semester
        ORDER BY e.formation_id, e.id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    DROP TEMPORARY TABLE IF EXISTS tmp_slots;
    DROP TEMPORARY TABLE IF EXISTS tmp_time_slots;

    CREATE TEMPORARY TABLE tmp_time_slots (
        slot_index INT AUTO_INCREMENT PRIMARY KEY,
        label VARCHAR(100),
        start_time TIME,
        end_time TIME
    );

    -- Parse JSON time slots
    SET @json_length = JSON_LENGTH(p_time_slots);
    SET @slot_idx = 0;
    
    WHILE @slot_idx < @json_length DO
        INSERT INTO tmp_time_slots (label, start_time, end_time)
        VALUES (
            JSON_UNQUOTE(JSON_EXTRACT(p_time_slots, CONCAT('$[', @slot_idx, '].label'))),
            TIME(JSON_UNQUOTE(JSON_EXTRACT(p_time_slots, CONCAT('$[', @slot_idx, '].start')))),
            TIME(JSON_UNQUOTE(JSON_EXTRACT(p_time_slots, CONCAT('$[', @slot_idx, '].end'))))
        );
        SET @slot_idx = @slot_idx + 1;
    END WHILE;

    SELECT COUNT(*) INTO v_slot_count FROM tmp_time_slots;

    CREATE TEMPORARY TABLE tmp_slots (
        exam_id INT,
        formation_id INT,
        date_exam DATE,
        heure_debut TIME,
        heure_fin TIME,
        slot_label VARCHAR(100)
    );

    OPEN cur;

    loop_exam: LOOP
        FETCH cur INTO v_exam, v_form, v_duree;
        IF done = 1 THEN LEAVE loop_exam; END IF;

        SET v_date = p_start;
        SET @exam_placed = FALSE;

        date_loop: WHILE v_date <= p_end AND @exam_placed = FALSE DO
            
            -- CHECK: Does this formation already have an exam today?
            -- (Students from same formation can only have 1 exam per day)
            IF EXISTS (
                SELECT 1 FROM tmp_slots
                WHERE formation_id = v_form AND date_exam = v_date
            ) THEN
                -- Yes, try next day
                SET v_date = DATE_ADD(v_date, INTERVAL 1 DAY);
            ELSE
                -- No exam today, place it at next available slot (rotating)
                -- Count how many exams already scheduled at this date
                SET @exams_today = (
                    SELECT COUNT(*) FROM tmp_slots WHERE date_exam = v_date
                );
                
                -- Use modulo to rotate through slots
                SET v_slot_index = (@exams_today % v_slot_count) + 1;
                
                SELECT start_time, end_time, label
                INTO v_slot_start, v_slot_end, v_slot_label
                FROM tmp_time_slots
                WHERE slot_index = v_slot_index;
                
                INSERT INTO tmp_slots
                VALUES (
                    v_exam, v_form, v_date, v_slot_start,
                    ADDTIME(v_slot_start, SEC_TO_TIME(v_duree*60)),
                    v_slot_label
                );
                
                SET @exam_placed = TRUE;
            END IF;

        END WHILE date_loop;
        
        IF @exam_placed = FALSE THEN
            INSERT INTO schedule_conflicts
            (examen_id, formation_id, conflict_type, conflict_reason)
            VALUES (
                v_exam, v_form, 'STUDENT_OVERLOAD',
                'No dates available in range'
            );
        END IF;

    END LOOP loop_exam;

    CLOSE cur;
    DROP TEMPORARY TABLE IF EXISTS tmp_time_slots;
END$$

DELIMITER ;
-- ============================================
-- PHASE 2: ALLOCATE ROOMS
-- ============================================
-- ============================================
-- PHASE 2: SMART ROOM ALLOCATION (MYSQL COMPATIBLE)
-- Only logs conflicts when TRULY overloaded
-- ============================================

-- ============================================
-- FIX PHASE 2: SKIP GROUPS WITH 0 STUDENTS
-- ============================================

-- ============================================
-- FIX PHASE 2: SKIP GROUPS WITH 0 STUDENTS
-- ============================================

-- ============================================
-- FIX PHASE 2: SKIP GROUPS WITH 0 STUDENTS
-- ============================================

-- ============================================
-- FIX PHASE 2: SKIP GROUPS WITH 0 STUDENTS
-- ============================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_phase2_allocate_rooms$$

CREATE PROCEDURE sp_phase2_allocate_rooms()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_exam_id INT;
    DECLARE v_groupe_id INT;
    DECLARE v_formation_id INT;
    DECLARE v_dept_id INT;
    DECLARE v_date DATE;
    DECLARE v_heure TIME;
    DECLARE v_student_count INT;
    DECLARE v_room_id INT;
    DECLARE v_room_capacity INT;
    
    DECLARE cur CURSOR FOR
        SELECT 
            ts.exam_id,
            g.id AS groupe_id,
            ts.formation_id,
            f.department_id,
            ts.date_exam,
            ts.heure_debut,
            (SELECT COUNT(*) FROM etudiants e WHERE e.groupe_id = g.id) AS student_count
        FROM tmp_slots ts
        JOIN formations f ON f.id = ts.formation_id
        JOIN groupes g ON g.formation_id = ts.formation_id
        WHERE (SELECT COUNT(*) FROM etudiants e WHERE e.groupe_id = g.id) > 0  -- ✅ SKIP EMPTY GROUPS
        ORDER BY ts.date_exam, ts.heure_debut, ts.exam_id;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    DROP TEMPORARY TABLE IF EXISTS tmp_room_alloc;

    CREATE TEMPORARY TABLE tmp_room_alloc (
        exam_id INT,
        groupe_id INT,
        lieu_id INT,
        INDEX idx_exam (exam_id),
        INDEX idx_room_time (lieu_id, exam_id)
    );

    -- ✅ LOG CONFLICTS FOR FORMATIONS WITH 0 STUDENTS
    -- Using a temp table to ensure we only log once per formation
    DROP TEMPORARY TABLE IF EXISTS tmp_logged_formations;
    CREATE TEMPORARY TABLE tmp_logged_formations (formation_id INT PRIMARY KEY);
    
    -- Insert conflicts (will naturally deduplicate via primary key)
    INSERT IGNORE INTO schedule_conflicts (examen_id, formation_id, conflict_type, conflict_reason)
    SELECT 
        MIN(ts.exam_id),
        f.id,
        'NO_STUDENTS',
        CONCAT('Formation ', f.nom, ' has groups with 0 students')
    FROM tmp_slots ts
    JOIN formations f ON f.id = ts.formation_id
    WHERE EXISTS (
        SELECT 1 FROM groupes g 
        WHERE g.formation_id = f.id 
        AND NOT EXISTS (SELECT 1 FROM etudiants e WHERE e.groupe_id = g.id)
    )
    GROUP BY f.id, f.nom;
    
    DROP TEMPORARY TABLE IF EXISTS tmp_logged_formations;

    OPEN cur;

    room_loop: LOOP
        FETCH cur INTO v_exam_id, v_groupe_id, v_formation_id, v_dept_id, v_date, v_heure, v_student_count;
        IF done = 1 THEN LEAVE room_loop; END IF;

        SET v_room_id = NULL;

        -- STRATEGY 1: Try to find room from SAME department
        SELECT l.id, l.capacite
        INTO v_room_id, v_room_capacity
        FROM lieux_examen l
        WHERE l.disponible = TRUE
          AND l.department_id = v_dept_id
          AND l.capacite >= v_student_count
          AND NOT EXISTS (
              SELECT 1 
              FROM tmp_room_alloc tra
              JOIN tmp_slots ts2 ON ts2.exam_id = tra.exam_id
              WHERE tra.lieu_id = l.id
                AND ts2.date_exam = v_date
                AND ts2.heure_debut = v_heure
          )
        ORDER BY l.capacite ASC
        LIMIT 1;

        -- STRATEGY 2: If no same-dept room, use ANY available room
        IF v_room_id IS NULL THEN
            SELECT l.id, l.capacite
            INTO v_room_id, v_room_capacity
            FROM lieux_examen l
            WHERE l.disponible = TRUE
              AND l.capacite >= v_student_count
              AND NOT EXISTS (
                  SELECT 1 
                  FROM tmp_room_alloc tra
                  JOIN tmp_slots ts2 ON ts2.exam_id = tra.exam_id
                  WHERE tra.lieu_id = l.id
                    AND ts2.date_exam = v_date
                    AND ts2.heure_debut = v_heure
              )
            ORDER BY l.capacite ASC
            LIMIT 1;
        END IF;

        -- If found, assign it
        IF v_room_id IS NOT NULL THEN
            INSERT INTO tmp_room_alloc (exam_id, groupe_id, lieu_id)
            VALUES (v_exam_id, v_groupe_id, v_room_id);
        ELSE
            INSERT INTO schedule_conflicts (examen_id, formation_id, conflict_type, conflict_reason)
            VALUES (
                v_exam_id,
                v_formation_id,
                'ROOM_CAPACITY',
                CONCAT('No room available for ', v_student_count, ' students at ', v_date, ' ', v_heure)
            );
        END IF;

    END LOOP room_loop;

    CLOSE cur;
END$$

DELIMITER ;


DELIMITER $$

DROP PROCEDURE IF EXISTS sp_phase3_assign_surveillance$$

CREATE PROCEDURE sp_phase3_assign_surveillance(
    IN p_max_per_day INT
)
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_exam_id INT;
    DECLARE v_form_id INT;
    DECLARE v_dept_id INT;
    DECLARE v_date_exam DATE;
    DECLARE v_heure_debut TIME;
    DECLARE v_groupe_id INT;
    DECLARE v_teacher_id INT;
    DECLARE v_teacher_dept INT;
    DECLARE v_current_count INT;
    DECLARE v_min_workload INT;
    
    DECLARE cur CURSOR FOR
        SELECT 
            tra.exam_id, 
            ts.formation_id, 
            ts.date_exam,
            ts.heure_debut,
            f.department_id,
            tra.groupe_id
        FROM tmp_room_alloc tra
        JOIN tmp_slots ts ON ts.exam_id = tra.exam_id
        JOIN formations f ON f.id = ts.formation_id
        ORDER BY ts.date_exam, ts.heure_debut, tra.exam_id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    DROP TEMPORARY TABLE IF EXISTS tmp_surv;
    DROP TEMPORARY TABLE IF EXISTS tmp_teacher_load;

    -- ✅ FIX #1: Track workload PER DAY, not globally
    CREATE TEMPORARY TABLE tmp_teacher_load (
        enseignant_id INT,
        date_exam DATE,
        surveillances_today INT DEFAULT 0,
        PRIMARY KEY (enseignant_id, date_exam),
        INDEX idx_count (date_exam, surveillances_today)
    );

    CREATE TEMPORARY TABLE tmp_surv (
        exam_id INT,
        enseignant_id INT,
        groupe_id INT,
        date_exam DATE,
        heure_debut TIME,
        PRIMARY KEY (exam_id, enseignant_id, groupe_id),
        INDEX idx_teacher_time (enseignant_id, date_exam, heure_debut)
    );

    -- Initialize ALL teachers for ALL exam dates
    INSERT INTO tmp_teacher_load (enseignant_id, date_exam, surveillances_today)
    SELECT e.id, ds.date_exam, 0
    FROM enseignants e
    CROSS JOIN (SELECT DISTINCT date_exam FROM tmp_slots) ds;

    OPEN cur;

    assign_loop: LOOP
        FETCH cur INTO v_exam_id, v_form_id, v_date_exam, v_heure_debut, v_dept_id, v_groupe_id;
        IF done = 1 THEN LEAVE assign_loop; END IF;

        SET v_teacher_id = NULL;

        -- ✅ FIX #2: Get minimum workload FOR THIS DAY only
        SELECT MIN(surveillances_today) INTO v_min_workload
        FROM tmp_teacher_load
        WHERE date_exam = v_date_exam;

        -- ✅ FIX #3: Don't require EXACT minimum, just prefer it
        -- STRATEGY 1: Same department teacher
        SELECT e.id
        INTO v_teacher_id
        FROM enseignants e
        JOIN tmp_teacher_load tl ON tl.enseignant_id = e.id AND tl.date_exam = v_date_exam
        WHERE e.department_id = v_dept_id
          -- Not at this time already
          AND NOT EXISTS (
              SELECT 1 FROM tmp_surv s
              WHERE s.enseignant_id = e.id
                AND s.date_exam = v_date_exam
                AND s.heure_debut = v_heure_debut
          )
          -- Under daily limit
          AND tl.surveillances_today < p_max_per_day
        ORDER BY 
            tl.surveillances_today ASC,  -- Prefer lowest workload TODAY
            e.id ASC
        LIMIT 1;

        -- STRATEGY 2: Any department teacher (if same-dept exhausted)
        IF v_teacher_id IS NULL THEN
            SELECT e.id, e.department_id
            INTO v_teacher_id, v_teacher_dept
            FROM enseignants e
            JOIN tmp_teacher_load tl ON tl.enseignant_id = e.id AND tl.date_exam = v_date_exam
            WHERE 1=1
              -- Not at this time already
              AND NOT EXISTS (
                  SELECT 1 FROM tmp_surv s
                  WHERE s.enseignant_id = e.id
                    AND s.date_exam = v_date_exam
                    AND s.heure_debut = v_heure_debut
              )
              -- Under daily limit
              AND tl.surveillances_today < p_max_per_day
            ORDER BY 
                -- Prefer same dept
                CASE WHEN e.department_id = v_dept_id THEN 0 ELSE 1 END,
                tl.surveillances_today ASC,
                e.id ASC
            LIMIT 1;
            
            -- Log cross-department assignment
            IF v_teacher_id IS NOT NULL AND v_teacher_dept != v_dept_id THEN
                INSERT INTO schedule_conflicts
                (examen_id, enseignant_id, conflict_type, conflict_reason)
                VALUES (
                    v_exam_id, v_teacher_id, 'TEACHER_CROSS_DEPT',
                    CONCAT('Teacher from dept ', v_teacher_dept, ' helping dept ', v_dept_id)
                );
            END IF;
        END IF;

        -- ASSIGN TEACHER
        IF v_teacher_id IS NOT NULL THEN
            INSERT INTO tmp_surv (exam_id, enseignant_id, groupe_id, date_exam, heure_debut)
            VALUES (v_exam_id, v_teacher_id, v_groupe_id, v_date_exam, v_heure_debut);

            -- Update workload FOR THIS DAY
            UPDATE tmp_teacher_load
            SET surveillances_today = surveillances_today + 1
            WHERE enseignant_id = v_teacher_id
              AND date_exam = v_date_exam;
        ELSE
            -- CRITICAL: No teacher available
            INSERT INTO schedule_conflicts
            (examen_id, formation_id, conflict_type, conflict_reason)
            VALUES (
                v_exam_id, v_form_id, 'TEACHER_UNAVAILABLE',
                CONCAT('CRITICAL: No teacher available at ', v_date_exam, ' ', v_heure_debut)
            );
        END IF;

    END LOOP assign_loop;

    CLOSE cur;
    
    -- Check daily balance
    INSERT INTO schedule_conflicts (conflict_type, conflict_reason)
    SELECT 
        'TEACHER_DAILY_IMBALANCE',
        CONCAT('Date ', date_exam, ': workload gap ', 
               MIN(surveillances_today), ' to ', MAX(surveillances_today))
    FROM tmp_teacher_load
    GROUP BY date_exam
    HAVING (MAX(surveillances_today) - MIN(surveillances_today)) > 2;
    
    DROP TEMPORARY TABLE IF EXISTS tmp_teacher_load;
END$$

DELIMITER ;
-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Check workload balance:
-- SELECT 
--     e.id,
--     e.nom,
--     e.department_id,
--     COUNT(*) as total_surveillances,
--     COUNT(DISTINCT s.date_exam) as days_working
-- FROM tmp_surv s
-- JOIN enseignants e ON e.id = s.enseignant_id
-- GROUP BY e.id
-- ORDER BY total_surveillances DESC;

-- Check cross-department assignments:
-- SELECT 
--     e.nom as teacher,
--     e.department_id as teacher_dept,
--     f.department_id as exam_dept,
--     s.date_exam,
--     COUNT(*) as cross_dept_count
-- FROM tmp_surv s
-- JOIN enseignants e ON e.id = s.enseignant_id
-- JOIN tmp_slots ts ON ts.exam_id = s.exam_id
-- JOIN formations f ON f.id = ts.formation_id
-- WHERE s.is_cross_department = TRUE
-- GROUP BY e.id, s.date_exam
-- ORDER BY s.date_exam;

-- ============================================
-- PHASE 4: PERSIST TO DATABASE
-- ============================================
-- ============================================
-- FIX: Add groupe_id to surveillances table
-- ============================================

-- ============================================
-- FIX: Add groupe_id to surveillances (SAFE METHOD)
-- ============================================

-- Step 1: Drop foreign keys that reference surveillances


-- Step 2: Drop old primary key


-- Step 4: Add new primary key with groupe_id


-- Step 5: Recreate foreign keys

-- Step 6: Add foreign key for groupe_id

-- ============================================
-- FIX: Phase 4 to store surveillances per group
-- ============================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_phase4_persist$$

CREATE PROCEDURE sp_phase4_persist(
    IN p_annee VARCHAR(20),
    IN p_semester ENUM('S1','S2'),
    IN p_creator INT
)
BEGIN
    START TRANSACTION;

    -- Insert schedules per formation
    INSERT INTO schedules (formation_id, annee_universitaire, semester, statut, created_by)
    SELECT DISTINCT formation_id, p_annee, p_semester, 'GENERE', p_creator
    FROM tmp_slots;

    -- Insert schedule examens
    INSERT INTO schedule_examens (schedule_id, examen_id, date_exam, heure_debut)
    SELECT s.id, ts.exam_id, ts.date_exam, ts.heure_debut
    FROM tmp_slots ts
    JOIN schedules s
      ON s.formation_id = ts.formation_id
     AND s.annee_universitaire = p_annee
     AND s.semester = p_semester;

    -- Insert room allocations
    INSERT INTO schedule_exam_salles (schedule_exam_id, groupe_id, lieu_id)
    SELECT 
        se.id,
        tra.groupe_id,
        tra.lieu_id
    FROM tmp_room_alloc tra
    JOIN schedule_examens se ON se.examen_id = tra.exam_id
    JOIN schedules s ON s.id = se.schedule_id
    WHERE s.annee_universitaire = p_annee
      AND s.semester = p_semester;

    -- ✅ FIX: Insert surveillances PER GROUP (no DISTINCT!)
    INSERT INTO surveillances (examen_id, enseignant_id, groupe_id)
    SELECT exam_id, enseignant_id, groupe_id
    FROM tmp_surv;

    COMMIT;
END$$

DELIMITER ;

-- ============================================
-- GET ALL EXAM DETAILS - ONE ROW PER GROUP
-- ============================================

-- ============================================
-- GET ALL EXAM DETAILS - FIXED (NO groupe_id in surveillances)
-- ============================================

-- ============================================
-- GET ALL EXAM DETAILS - FIXED (NO groupe_id in surveillances)
-- ============================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_get_all_exam_details$$

-- ============================================
-- GET ALL EXAM DETAILS - FIXED (NO groupe_id in surveillances)
-- ============================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_get_all_exam_details$$

CREATE PROCEDURE sp_get_all_exam_details(
    IN p_annee VARCHAR(20),
    IN p_semester ENUM('S1','S2')
)
BEGIN
    SELECT 
        se.date_exam,
        se.heure_debut,
        m.nom AS matiere,
        m.code AS matiere_code,
        e.duree_minutes,
        f.nom AS formation,
        f.code AS formation_code,
        f.niveau AS niveau,
        d.nom AS department,
        g.nom AS groupe,
        l.nom AS salle,
        l.capacite AS salle_capacite,
        GROUP_CONCAT(CONCAT(ens.nom, ' ', ens.prenom) ORDER BY ens.nom SEPARATOR ', ') AS surveillant,
        s.id AS schedule_id,
        se.id AS schedule_exam_id,
        ses.groupe_id,
        ses.lieu_id
    FROM schedule_examens se
    JOIN schedules s ON s.id = se.schedule_id
    JOIN examens e ON e.id = se.examen_id
    JOIN matieres m ON m.id = e.matiere_id
    JOIN formations f ON f.id = e.formation_id
    JOIN departements d ON d.id = f.department_id
    LEFT JOIN schedule_exam_salles ses ON ses.schedule_exam_id = se.id
    LEFT JOIN groupes g ON g.id = ses.groupe_id
    LEFT JOIN lieux_examen l ON l.id = ses.lieu_id
    LEFT JOIN surveillances surv ON surv.examen_id = e.id AND surv.groupe_id = ses.groupe_id
    LEFT JOIN enseignants ens ON ens.id = surv.enseignant_id
    WHERE s.annee_universitaire = p_annee
      AND s.semester = p_semester
    GROUP BY se.id, se.date_exam, se.heure_debut, m.nom, m.code, e.duree_minutes, 
             f.nom, f.code, d.nom, g.nom, l.nom, l.capacite, s.id, se.id, ses.groupe_id, ses.lieu_id
    ORDER BY se.date_exam, se.heure_debut, f.nom, g.nom;
END$$

DELIMITER ;

-- ============================================
-- GET PUBLISHED EXAM DETAILS (For Students/Teachers)
-- Only returns exams with status 'PUBLIE' (approved by Doyen)
-- ============================================

DROP PROCEDURE IF EXISTS sp_get_published_exam_details;

DELIMITER $$

CREATE PROCEDURE sp_get_published_exam_details(
    IN p_annee VARCHAR(20),
    IN p_semester ENUM('S1','S2')
)
BEGIN
    SELECT 
        se.date_exam,
        se.heure_debut,
        m.nom AS matiere,
        m.code AS matiere_code,
        e.duree_minutes,
        f.nom AS formation,
        f.code AS formation_code,
        f.niveau AS niveau,
        d.nom AS department,
        g.nom AS groupe,
        l.nom AS salle,
        l.capacite AS salle_capacite,
        GROUP_CONCAT(CONCAT(ens.nom, ' ', ens.prenom) ORDER BY ens.nom SEPARATOR ', ') AS surveillant,
        s.id AS schedule_id,
        se.id AS schedule_exam_id,
        ses.groupe_id,
        ses.lieu_id
    FROM schedule_examens se
    JOIN schedules s ON s.id = se.schedule_id
    JOIN examens e ON e.id = se.examen_id
    JOIN matieres m ON m.id = e.matiere_id
    JOIN formations f ON f.id = e.formation_id
    JOIN departements d ON d.id = f.department_id
    LEFT JOIN schedule_exam_salles ses ON ses.schedule_exam_id = se.id
    LEFT JOIN groupes g ON g.id = ses.groupe_id
    LEFT JOIN lieux_examen l ON l.id = ses.lieu_id
    LEFT JOIN surveillances surv ON surv.examen_id = e.id AND surv.groupe_id = ses.groupe_id
    LEFT JOIN enseignants ens ON ens.id = surv.enseignant_id
    WHERE s.annee_universitaire = p_annee
      AND s.semester = p_semester
      AND s.statut = 'PUBLIE'  -- ✅ Only show published exams (approved by Doyen)
    GROUP BY se.id, se.date_exam, se.heure_debut, m.nom, m.code, e.duree_minutes, 
             f.nom, f.code, d.nom, g.nom, l.nom, l.capacite, s.id, se.id, ses.groupe_id, ses.lieu_id
    ORDER BY se.date_exam, se.heure_debut, f.nom, g.nom;
END$$

DELIMITER ;

-- ============================================
-- GET PUBLISHED EXAMS FOR STUDENT (By Formation)
-- ============================================

DROP PROCEDURE IF EXISTS sp_get_student_exams;

DELIMITER $$

CREATE PROCEDURE sp_get_student_exams(
    IN p_annee VARCHAR(20),
    IN p_semester ENUM('S1','S2'),
    IN p_formation_id INT,
    IN p_groupe_id INT
)
BEGIN
    SELECT 
        se.date_exam,
        se.heure_debut,
        m.nom AS matiere,
        m.code AS matiere_code,
        e.duree_minutes,
        f.nom AS formation,
        f.code AS formation_code,
        f.niveau AS niveau,
        d.nom AS department,
        g.nom AS groupe,
        g.id AS groupe_id,
        l.nom AS salle,
        l.capacite AS salle_capacite,
        GROUP_CONCAT(CONCAT(ens.nom, ' ', ens.prenom) ORDER BY ens.nom SEPARATOR ', ') AS surveillant,
        s.id AS schedule_id,
        se.id AS schedule_exam_id,
        ses.groupe_id AS exam_groupe_id,
        ses.lieu_id,
        e.formation_id
    FROM schedule_examens se
    JOIN schedules s ON s.id = se.schedule_id
    JOIN examens e ON e.id = se.examen_id
    JOIN matieres m ON m.id = e.matiere_id
    JOIN formations f ON f.id = e.formation_id
    JOIN departements d ON d.id = f.department_id
    LEFT JOIN schedule_exam_salles ses ON ses.schedule_exam_id = se.id
    LEFT JOIN groupes g ON g.id = ses.groupe_id
    LEFT JOIN lieux_examen l ON l.id = ses.lieu_id
    LEFT JOIN surveillances surv ON surv.examen_id = e.id AND surv.groupe_id = ses.groupe_id
    LEFT JOIN enseignants ens ON ens.id = surv.enseignant_id
    WHERE s.annee_universitaire = p_annee
      AND s.semester = p_semester
      AND s.statut = 'PUBLIE'  -- ✅ Only published exams
      AND e.formation_id = p_formation_id  -- ✅ CRITICAL: Filter by student's formation
      -- Note: groupe_id filtering is optional - if NULL, show all exams for the formation
    GROUP BY se.id, se.date_exam, se.heure_debut, m.nom, m.code, e.duree_minutes, 
             f.nom, f.code, d.nom, g.nom, g.id, l.nom, l.capacite, s.id, se.id, ses.groupe_id, ses.lieu_id, e.formation_id
    ORDER BY se.date_exam, se.heure_debut, f.nom, g.nom;
END$$

DELIMITER ;

-- ============================================
-- GET PUBLISHED EXAMS FOR TEACHER (By Surveillances)
-- ============================================

DROP PROCEDURE IF EXISTS sp_get_teacher_exams;

DELIMITER $$

CREATE PROCEDURE sp_get_teacher_exams(
    IN p_annee VARCHAR(20),
    IN p_semester ENUM('S1','S2'),
    IN p_teacher_id INT
)
BEGIN
    SELECT 
        se.date_exam,
        se.heure_debut,
        m.nom AS matiere,
        m.code AS matiere_code,
        e.duree_minutes,
        f.nom AS formation,
        f.code AS formation_code,
        f.niveau AS niveau,
        d.nom AS department,
        g.nom AS groupe,
        l.nom AS salle,
        l.capacite AS salle_capacite,
        CONCAT(ens.nom, ' ', ens.prenom) AS surveillant,
        s.id AS schedule_id,
        se.id AS schedule_exam_id,
        ses.groupe_id,
        ses.lieu_id
    FROM schedule_examens se
    JOIN schedules s ON s.id = se.schedule_id
    JOIN examens e ON e.id = se.examen_id
    JOIN matieres m ON m.id = e.matiere_id
    JOIN formations f ON f.id = e.formation_id
    JOIN departements d ON d.id = f.department_id
    LEFT JOIN schedule_exam_salles ses ON ses.schedule_exam_id = se.id
    LEFT JOIN groupes g ON g.id = ses.groupe_id
    LEFT JOIN lieux_examen l ON l.id = ses.lieu_id
    INNER JOIN surveillances surv ON surv.examen_id = e.id AND surv.groupe_id = ses.groupe_id
    INNER JOIN enseignants ens ON ens.id = surv.enseignant_id
    WHERE s.annee_universitaire = p_annee
      AND s.semester = p_semester
      AND s.statut = 'PUBLIE'  -- ✅ Only published exams
      AND surv.enseignant_id = p_teacher_id  -- ✅ Filter by teacher's assignments
    GROUP BY se.id, se.date_exam, se.heure_debut, m.nom, m.code, e.duree_minutes, 
             f.nom, f.code, d.nom, g.nom, l.nom, l.capacite, s.id, se.id, ses.groupe_id, ses.lieu_id,
             ens.nom, ens.prenom
    ORDER BY se.date_exam, se.heure_debut, f.nom, g.nom;
END$$

DELIMITER ;

-- ============================================
-- MAIN GENERATOR PROCEDURE (WITH DYNAMIC TIME SLOTS)
-- ============================================
-- ============================================
-- FIX: Clear old schedules before generating new ones
-- ============================================

-- THE ISSUE: tmp_slots might have duplicate exam entries
-- Solution: Count from the actual schedule_examens table instead of tmp_slots

-- Replace the entire sp_generate_exam_schedule procedure:

-- ============================================
-- SMART MAIN PROCEDURE - ONLY CLEAR SPECIFIC YEAR/SEMESTER
-- ============================================

-- ============================================
-- SMART MAIN PROCEDURE - ONLY CLEAR SPECIFIC YEAR/SEMESTER
-- ============================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_generate_exam_schedule$$

CREATE PROCEDURE sp_generate_exam_schedule(
    IN p_annee VARCHAR(20),
    IN p_semester ENUM('S1','S2'),
    IN p_start DATE,
    IN p_end DATE,
    IN p_time_slots JSON,
    IN p_creator INT
)
BEGIN
    DECLARE v_schedule_exists INT DEFAULT 0;
    
    -- ✅ CHECK: Does schedule already exist for this year/semester?
    SELECT COUNT(*) INTO v_schedule_exists
    FROM schedules
    WHERE annee_universitaire = p_annee
      AND semester = p_semester;
    
    IF v_schedule_exists > 0 THEN
        -- Schedule exists - delete ONLY this year/semester
        DELETE ses FROM schedule_exam_salles ses
        JOIN schedule_examens se ON se.id = ses.schedule_exam_id
        JOIN schedules s ON s.id = se.schedule_id
        WHERE s.annee_universitaire = p_annee AND s.semester = p_semester;
        
        DELETE se FROM schedule_examens se
        JOIN schedules s ON s.id = se.schedule_id
        WHERE s.annee_universitaire = p_annee AND s.semester = p_semester;
        
        DELETE FROM surveillances
        WHERE examen_id IN (
            SELECT id FROM examens 
            WHERE annee_universitaire = p_annee AND semester = p_semester
        );
        
        DELETE FROM schedules
        WHERE annee_universitaire = p_annee AND semester = p_semester;
        
        DELETE FROM schedule_conflicts
        WHERE examen_id IN (
            SELECT id FROM examens 
            WHERE annee_universitaire = p_annee AND semester = p_semester
        );
    END IF;
    
    -- Phase 1: Plan time slots
    CALL sp_phase1_plan_time_slots(p_annee, p_semester, p_start, p_end, p_time_slots);
    
    -- Phase 2: Allocate rooms
    CALL sp_phase2_allocate_rooms();
    
    -- Phase 3: Assign surveillance
    CALL sp_phase3_assign_surveillance(3);
    
    -- Phase 4: Persist to database
    CALL sp_phase4_persist(p_annee, p_semester, p_creator);
    
    -- Return summary
    SELECT 
        (SELECT COUNT(*) FROM tmp_slots) AS exams_scheduled,
        (SELECT COUNT(DISTINCT formation_id) FROM tmp_slots) AS formations_affected,
        (SELECT COUNT(DISTINCT date_exam) FROM tmp_slots) AS days_used,
        (SELECT COUNT(*) FROM schedule_conflicts) AS total_conflicts,
        (SELECT COUNT(*) FROM schedule_conflicts WHERE conflict_type = 'STUDENT_OVERLOAD') AS student_conflicts,
        (SELECT COUNT(*) FROM schedule_conflicts WHERE conflict_type = 'TEACHER_OVERLOAD') AS teacher_conflicts,
        (SELECT COUNT(*) FROM schedule_conflicts WHERE conflict_type = 'ROOM_CAPACITY') AS room_conflicts;
END$$

DELIMITER ;

-- ============================================
-- DASHBOARD STATISTICS PROCEDURE
-- Returns real-time exam scheduling metrics
-- ============================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_get_dashboard_stats$$

CREATE PROCEDURE sp_get_dashboard_stats(
    IN p_annee VARCHAR(20),
    IN p_semester ENUM('S1','S2')
)
BEGIN
    -- Get overall statistics
    SELECT 
        -- Total exams
        (SELECT COUNT(*) 
         FROM examens 
         WHERE annee_universitaire = p_annee AND semester = p_semester) as total_exams_target,
        
        -- Exams with schedules (generated)
        (SELECT COUNT(DISTINCT se.examen_id)
         FROM schedule_examens se
         JOIN schedules s ON s.id = se.schedule_id
         WHERE s.annee_universitaire = p_annee AND s.semester = p_semester) as total_exams_generated,
        
        -- Total conflicts
        (SELECT COUNT(*) 
         FROM schedule_conflicts sc
         WHERE sc.examen_id IN (
             SELECT id FROM examens WHERE annee_universitaire = p_annee AND semester = p_semester
         )) as total_conflicts,
        
        -- Critical conflicts (no room, no teacher)
        (SELECT COUNT(*) 
         FROM schedule_conflicts sc
         WHERE sc.conflict_type IN ('ROOM_CAPACITY', 'TEACHER_UNAVAILABLE')
         AND sc.examen_id IN (
             SELECT id FROM examens WHERE annee_universitaire = p_annee AND semester = p_semester
         )) as critical_conflicts,
        
        -- Medium conflicts (cross-dept, imbalance)
        (SELECT COUNT(*) 
         FROM schedule_conflicts sc
         WHERE sc.conflict_type IN ('TEACHER_CROSS_DEPT', 'TEACHER_DAILY_IMBALANCE')
         AND sc.examen_id IN (
             SELECT id FROM examens WHERE annee_universitaire = p_annee AND semester = p_semester
         )) as medium_conflicts,
        
        -- Low conflicts (empty groups)
        (SELECT COUNT(*) 
         FROM schedule_conflicts sc
         WHERE sc.conflict_type = 'NO_STUDENTS'
         AND sc.examen_id IN (
             SELECT id FROM examens WHERE annee_universitaire = p_annee AND semester = p_semester
         )) as low_conflicts,
        
        -- Pending actions (formations without complete schedules)
        (SELECT COUNT(DISTINCT f.id)
         FROM formations f
         WHERE EXISTS (
             SELECT 1 FROM examens e 
             WHERE e.formation_id = f.id 
             AND e.annee_universitaire = p_annee 
             AND e.semester = p_semester
         )
         AND NOT EXISTS (
             SELECT 1 FROM schedules s 
             WHERE s.formation_id = f.id 
             AND s.annee_universitaire = p_annee 
             AND s.semester = p_semester
         )) as pending_formations;
END$$

DELIMITER ;

-- ============================================
-- DEPARTMENT STATISTICS PROCEDURE
-- Returns per-department exam status
-- ============================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_get_department_stats$$

CREATE PROCEDURE sp_get_department_stats(
    IN p_annee VARCHAR(20),
    IN p_semester ENUM('S1','S2')
)
BEGIN
    SELECT 
        d.id as department_id,
        d.nom as department_name,
        
        -- Total exams for this department
        COUNT(DISTINCT e.id) as total_exams,
        
        -- Generated exams (with schedules)
        COUNT(DISTINCT CASE 
            WHEN se.id IS NOT NULL THEN e.id 
        END) as generated_exams,
        
        -- Conflicts for this department
        COUNT(DISTINCT CASE 
            WHEN sc.id IS NOT NULL THEN sc.id 
        END) as conflicts,
        
        -- Status
        CASE 
            WHEN COUNT(DISTINCT e.id) = 0 THEN 'No Exams'
            WHEN COUNT(DISTINCT se.id) = COUNT(DISTINCT e.id) AND COUNT(DISTINCT sc.id) = 0 
                THEN 'Completed'
            WHEN COUNT(DISTINCT se.id) > 0 
                THEN 'In Progress'
            ELSE 'Pending'
        END as status,
        
        -- Completion percentage
        ROUND(
            (COUNT(DISTINCT CASE WHEN se.id IS NOT NULL THEN e.id END) * 100.0) / 
            NULLIF(COUNT(DISTINCT e.id), 0),
            1
        ) as completion_percentage
        
    FROM departements d
    LEFT JOIN formations f ON f.department_id = d.id
    LEFT JOIN examens e ON e.formation_id = f.id 
        AND e.annee_universitaire = p_annee 
        AND e.semester = p_semester
    LEFT JOIN schedule_examens se ON se.examen_id = e.id
    LEFT JOIN schedules s ON s.id = se.schedule_id 
        AND s.annee_universitaire = p_annee 
        AND s.semester = p_semester
    LEFT JOIN schedule_conflicts sc ON sc.examen_id = e.id
    GROUP BY d.id, d.nom
    HAVING total_exams > 0
    ORDER BY d.nom;
END$$

DELIMITER ;

-- ============================================
-- CONFLICTS BY TYPE PROCEDURE
-- Returns breakdown of conflict types
-- ============================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_get_conflicts_by_type$$

CREATE PROCEDURE sp_get_conflicts_by_type(
    IN p_annee VARCHAR(20),
    IN p_semester ENUM('S1','S2')
)
BEGIN
    SELECT 
        CASE sc.conflict_type
            WHEN 'STUDENT_OVERLOAD' THEN 'Student Overload'
            WHEN 'TEACHER_UNAVAILABLE' THEN 'Teacher Unavailable'
            WHEN 'TEACHER_CROSS_DEPT' THEN 'Cross-Department Teacher'
            WHEN 'ROOM_CAPACITY' THEN 'Room Capacity'
            WHEN 'NO_STUDENTS' THEN 'No Students'
            WHEN 'TEACHER_DAILY_IMBALANCE' THEN 'Teacher Imbalance'
            ELSE sc.conflict_type
        END as conflict_name,
        COUNT(*) as count
    FROM schedule_conflicts sc
    WHERE sc.examen_id IN (
        SELECT id FROM examens 
        WHERE annee_universitaire = p_annee AND semester = p_semester
    )
    GROUP BY sc.conflict_type
    ORDER BY count DESC;
END$$

DELIMITER ;

-- ============================================
-- RECENT ACTIVITIES PROCEDURE
-- Returns recent scheduling activities
-- ============================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_get_recent_activities$$

CREATE PROCEDURE sp_get_recent_activities(
    IN p_annee VARCHAR(20),
    IN p_semester ENUM('S1','S2'),
    IN p_limit INT
)
BEGIN
    -- Get recent schedule generations
    (SELECT 
        'Timetable generated' as action,
        d.nom as department,
        s.created_at as time,
        'auto_fix_high' as icon,
        'green' as color
    FROM schedules s
    JOIN formations f ON f.id = s.formation_id
    JOIN departements d ON d.id = f.department_id
    WHERE s.annee_universitaire = p_annee AND s.semester = p_semester
    ORDER BY s.created_at DESC
    LIMIT p_limit)
    
    UNION ALL
    
    -- Get recent conflicts
    (SELECT 
        CASE 
            WHEN sc.conflict_type IN ('ROOM_CAPACITY', 'TEACHER_UNAVAILABLE') 
                THEN 'Critical conflict detected'
            ELSE 'Conflict detected'
        END as action,
        d.nom as department,
        sc.created_at as time,
        'warning' as icon,
        CASE 
            WHEN sc.conflict_type IN ('ROOM_CAPACITY', 'TEACHER_UNAVAILABLE') 
                THEN 'red'
            ELSE 'orange'
        END as color
    FROM schedule_conflicts sc
    JOIN examens e ON e.id = sc.examen_id
    JOIN formations f ON f.id = e.formation_id
    JOIN departements d ON d.id = f.department_id
    WHERE e.annee_universitaire = p_annee AND e.semester = p_semester
    ORDER BY sc.created_at DESC
    LIMIT p_limit)
    
    ORDER BY time DESC
    LIMIT p_limit;
END$$

DELIMITER ;



DROP PROCEDURE IF EXISTS sp_get_schedule_details;

DELIMITER $$

CREATE PROCEDURE sp_get_schedule_details(
    IN p_schedule_id INT
)
BEGIN
    SELECT 
        se.id AS schedule_exam_id,
        se.date_exam,
        se.heure_debut,
        m.nom AS matiere,
        m.code AS matiere_code,
        e.duree_minutes,
        f.nom AS formation,
        f.code AS formation_code,
        f.niveau AS niveau,
        d.nom AS department,
        d.id AS department_id,
        g.nom AS groupe,
        l.nom AS salle,
        l.capacite AS salle_capacite,
        GROUP_CONCAT(DISTINCT CONCAT(ens.nom, ' ', ens.prenom) ORDER BY ens.nom SEPARATOR ', ') AS surveillant,
        s.id AS schedule_id,
        ses.groupe_id,
        ses.lieu_id
    FROM schedule_examens se
    JOIN schedules s ON s.id = se.schedule_id
    JOIN examens e ON e.id = se.examen_id
    JOIN matieres m ON m.id = e.matiere_id
    JOIN formations f ON f.id = e.formation_id
    JOIN departements d ON d.id = f.department_id
    LEFT JOIN schedule_exam_salles ses ON ses.schedule_exam_id = se.id
    LEFT JOIN groupes g ON g.id = ses.groupe_id
    LEFT JOIN lieux_examen l ON l.id = ses.lieu_id
    LEFT JOIN surveillances surv ON surv.examen_id = e.id AND surv.groupe_id = ses.groupe_id
    LEFT JOIN enseignants ens ON ens.id = surv.enseignant_id
    WHERE s.id = p_schedule_id
    GROUP BY se.id, se.date_exam, se.heure_debut, m.nom, m.code, e.duree_minutes, 
             f.nom, f.code, f.niveau, d.nom, d.id, g.nom, l.nom, l.capacite, 
             s.id, ses.groupe_id, ses.lieu_id
    ORDER BY se.date_exam, se.heure_debut, f.nom, g.nom;
END$$

DELIMITER ;

-- ============================================
-- STEP 2: Create sp_get_department_exams with STRICT filtering
-- ============================================

-- ============================================
-- FIX: sp_get_department_exams - Filter by BOTH formation AND matiere department
-- This ensures we only show exams for subjects that belong to the chef's department
-- ============================================

DROP PROCEDURE IF EXISTS sp_get_department_exams;

DELIMITER $$

CREATE PROCEDURE sp_get_department_exams(
    IN p_schedule_id INT,
    IN p_department_id INT
)
BEGIN
    -- ✅ CRITICAL: Filter by formation.department_id
    -- This ensures we only get exams for formations in this department
    
    SELECT 
        se.id AS schedule_exam_id,
        se.date_exam,
        se.heure_debut,
        m.nom AS matiere,
        m.code AS matiere_code,
        e.duree_minutes,
        f.nom AS formation,
        f.code AS formation_code,
        f.niveau AS niveau,
        d.nom AS department,
        d.id AS department_id,
        g.nom AS groupe,
        l.nom AS salle,
        l.capacite AS salle_capacite,
        GROUP_CONCAT(DISTINCT CONCAT(ens.nom, ' ', ens.prenom) ORDER BY ens.nom SEPARATOR ', ') AS surveillant,
        s.id AS schedule_id,
        ses.groupe_id,
        ses.lieu_id,
        (SELECT COUNT(*) FROM etudiants et WHERE et.groupe_id = g.id) AS student_count
    FROM schedule_examens se
    JOIN schedules s ON s.id = se.schedule_id
    JOIN examens e ON e.id = se.examen_id
    JOIN matieres m ON m.id = e.matiere_id
    JOIN formations f ON f.id = e.formation_id
    JOIN departements d ON d.id = f.department_id
    LEFT JOIN schedule_exam_salles ses ON ses.schedule_exam_id = se.id
    LEFT JOIN groupes g ON g.id = ses.groupe_id
    LEFT JOIN lieux_examen l ON l.id = ses.lieu_id
    LEFT JOIN surveillances surv ON surv.examen_id = e.id AND surv.groupe_id = ses.groupe_id
    LEFT JOIN enseignants ens ON ens.id = surv.enseignant_id
    WHERE s.id = p_schedule_id
      AND f.department_id = p_department_id  -- ✅✅✅ CRITICAL FILTER: Only this department's formations
    GROUP BY se.id, se.date_exam, se.heure_debut, m.nom, m.code, e.duree_minutes, 
             f.nom, f.code, f.niveau, d.nom, d.id, g.nom, l.nom, l.capacite, 
             s.id, ses.groupe_id, ses.lieu_id
    ORDER BY se.date_exam, se.heure_debut, f.nom, g.nom;
END$$

DELIMITER ;

-- ============================================
-- STEP 3: Fix sp_get_schedules_for_chef to return correct info
-- ============================================

DROP PROCEDURE IF EXISTS sp_get_schedules_for_chef;

DELIMITER $$

CREATE PROCEDURE sp_get_schedules_for_chef(
    IN p_chef_id INT,
    IN p_annee VARCHAR(20),
    IN p_semester ENUM('S1', 'S2')
)
BEGIN
    DECLARE v_dept_id INT;
    
    -- Get chef's department
    SELECT department_id INTO v_dept_id
    FROM chefs_departement
    WHERE id = p_chef_id;
    
    IF v_dept_id IS NULL THEN
        SELECT 'ERROR' as status, 'User is not a Chef de Département' as message;
    ELSE
        -- ✅ Return schedules for THIS DEPARTMENT ONLY
        SELECT 
            s.id as schedule_id,
            f.nom as formation,
            f.code as formation_code,
            f.id as formation_id,
            d.nom as department,
            d.id as department_id,  -- ✅ Add department_id to response
            s.statut,
            s.annee_universitaire,
            s.semester,
            COUNT(DISTINCT se.id) as total_exams,
            s.created_at,
            
            -- Check if already reviewed by this chef
            (SELECT action FROM schedule_approvals 
             WHERE schedule_id = s.id 
             AND approval_level = 'CHEF_DEPARTEMENT' 
             ORDER BY approved_at DESC LIMIT 1) as last_action,
            
            (SELECT comment FROM schedule_approvals 
             WHERE schedule_id = s.id 
             AND approval_level = 'CHEF_DEPARTEMENT' 
             ORDER BY approved_at DESC LIMIT 1) as last_comment
            
        FROM schedules s
        JOIN formations f ON f.id = s.formation_id
        JOIN departements d ON d.id = f.department_id
        LEFT JOIN schedule_examens se ON se.schedule_id = s.id
        WHERE f.department_id = v_dept_id  -- ✅ CRITICAL: Filter by chef's department
        AND s.annee_universitaire = p_annee
        AND s.semester = p_semester
        AND s.statut IN ('GENERE', 'BROUILLON')
        GROUP BY s.id, f.nom, f.code, f.id, d.nom, d.id, s.statut, 
                 s.annee_universitaire, s.semester, s.created_at
        ORDER BY s.statut DESC, s.created_at DESC;
    END IF;
END$$

DELIMITER ;
-- ============================================
-- DROP AND RECREATE sp_clear_schedules
-- ============================================

DROP PROCEDURE IF EXISTS sp_clear_schedules;

DELIMITER $$

CREATE PROCEDURE sp_clear_schedules(
    IN p_annee VARCHAR(20),
    IN p_semester ENUM('S1','S2')
)
BEGIN
    -- This will cascade delete schedule_examens and schedule_exam_salles
    DELETE FROM schedules
    WHERE annee_universitaire = p_annee
      AND semester = p_semester;
      
    -- Clear conflicts
    DELETE FROM schedule_conflicts;
    
    SELECT 'Schedules cleared successfully' AS message;
END$$

DELIMITER ;

-- ============================================
-- APPROVAL STORED PROCEDURES
-- Run these in your MySQL database
-- ============================================

USE `exam_scheduler_db`;

-- Drop existing procedures
DROP PROCEDURE IF EXISTS sp_chef_approve_schedule;
DROP PROCEDURE IF EXISTS sp_doyen_approve_schedule;
DROP PROCEDURE IF EXISTS sp_get_schedules_for_chef;
DROP PROCEDURE IF EXISTS sp_get_schedules_for_doyen;
DROP PROCEDURE IF EXISTS sp_get_approval_details;
DROP PROCEDURE IF EXISTS sp_get_approval_statistics;

-- ============================================
-- 1. GET SCHEDULES FOR CHEF APPROVAL
-- ============================================

DELIMITER $$

CREATE PROCEDURE sp_get_schedules_for_chef(
    IN p_chef_id INT,
    IN p_annee VARCHAR(20),
    IN p_semester ENUM('S1', 'S2')
)
BEGIN
    DECLARE v_dept_id INT;
    
    -- Get chef's department
    SELECT department_id INTO v_dept_id
    FROM chefs_departement
    WHERE id = p_chef_id;
    
    IF v_dept_id IS NULL THEN
        SELECT 'ERROR' as status, 'User is not a Chef de Département' as message;
    ELSE
        SELECT 
            s.id as schedule_id,
            f.nom as formation,
            f.code as formation_code,
            d.nom as department,
            s.statut,
            s.annee_universitaire,
            s.semester,
            COUNT(DISTINCT se.id) as total_exams,
            s.created_at,
            
            -- Check if already reviewed by this chef
            (SELECT action FROM schedule_approvals 
             WHERE schedule_id = s.id 
             AND approval_level = 'CHEF_DEPARTEMENT' 
             ORDER BY approved_at DESC LIMIT 1) as last_action,
            
            (SELECT comment FROM schedule_approvals 
             WHERE schedule_id = s.id 
             AND approval_level = 'CHEF_DEPARTEMENT' 
             ORDER BY approved_at DESC LIMIT 1) as last_comment
            
        FROM schedules s
        JOIN formations f ON f.id = s.formation_id
        JOIN departements d ON d.id = f.department_id
        LEFT JOIN schedule_examens se ON se.schedule_id = s.id
        WHERE f.department_id = v_dept_id
        AND s.annee_universitaire = p_annee
        AND s.semester = p_semester
        AND s.statut IN ('GENERE', 'BROUILLON')  -- Show pending or rejected schedules
        GROUP BY s.id, f.nom, f.code, d.nom, s.statut, 
                 s.annee_universitaire, s.semester, s.created_at
        ORDER BY s.statut DESC, s.created_at DESC;
    END IF;
END$$

DELIMITER ;

-- ============================================
-- 2. GET SCHEDULES FOR DOYEN APPROVAL
-- ============================================

DELIMITER $$

CREATE PROCEDURE sp_get_schedules_for_doyen(
    IN p_annee VARCHAR(20),
    IN p_semester ENUM('S1', 'S2')
)
BEGIN
    SELECT 
        s.id as schedule_id,
        f.nom as formation,
        f.code as formation_code,
        d.nom as department,
        s.statut,
        s.annee_universitaire,
        s.semester,
        COUNT(DISTINCT se.id) as total_exams,
        
        -- Chef approval info
        (SELECT CONCAT(cd.nom, ' ', cd.prenom) 
         FROM schedule_approvals sa
         JOIN chefs_departement cd ON cd.id = sa.approver_id
         WHERE sa.schedule_id = s.id 
         AND sa.approval_level = 'CHEF_DEPARTEMENT'
         AND sa.action = 'APPROVED'
         ORDER BY sa.approved_at DESC LIMIT 1) as chef_name,
        
        (SELECT approved_at 
         FROM schedule_approvals 
         WHERE schedule_id = s.id 
         AND approval_level = 'CHEF_DEPARTEMENT'
         AND action = 'APPROVED'
         ORDER BY approved_at DESC LIMIT 1) as chef_approved_at,
        
        s.created_at
        
    FROM schedules s
    JOIN formations f ON f.id = s.formation_id
    JOIN departements d ON d.id = f.department_id
    LEFT JOIN schedule_examens se ON se.schedule_id = s.id
    WHERE s.annee_universitaire = p_annee
    AND s.semester = p_semester
    AND s.statut = 'VALIDE_DEPARTEMENT'  -- Only chef-approved schedules
    GROUP BY s.id, f.nom, f.code, d.nom, s.statut, 
             s.annee_universitaire, s.semester, s.created_at
    ORDER BY s.created_at DESC;
END$$

DELIMITER ;

-- ============================================
-- 3. CHEF APPROVE SCHEDULE
-- ============================================

DELIMITER $$

CREATE PROCEDURE sp_chef_approve_schedule(
    IN p_schedule_id INT,
    IN p_chef_id INT,
    IN p_action ENUM('APPROVE', 'REJECT'),
    IN p_comment TEXT
)
BEGIN
    DECLARE v_department_id INT;
    DECLARE v_chef_department_id INT;
    DECLARE v_current_status VARCHAR(50);
    DECLARE v_formation_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'ERROR' as status, 'Transaction failed' as message;
    END;
    
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    START TRANSACTION;
    
    SELECT department_id INTO v_chef_department_id
    FROM chefs_departement
    WHERE id = p_chef_id;
    
    IF v_chef_department_id IS NULL THEN
        ROLLBACK;
        SELECT 'ERROR' as status, 'User is not a Chef de Département' as message;
    ELSE
        SELECT s.statut, s.formation_id, f.department_id
        INTO v_current_status, v_formation_id, v_department_id
        FROM schedules s
        JOIN formations f ON f.id = s.formation_id
        WHERE s.id = p_schedule_id
        FOR UPDATE;
        
        IF v_current_status IS NULL THEN
            ROLLBACK;
            SELECT 'ERROR' as status, 'Schedule not found' as message;
        
        ELSEIF v_department_id != v_chef_department_id THEN
            ROLLBACK;
            SELECT 'ERROR' as status, 
                   'Chef can only approve schedules from their own department' as message;
        
        ELSEIF v_current_status NOT IN ('GENERE', 'BROUILLON') THEN
            ROLLBACK;
            SELECT 'ERROR' as status, 
                   CONCAT('Schedule status is ', v_current_status, '. Only GENERE schedules can be approved by Chef.') as message;
        
        ELSE
            IF p_action = 'APPROVE' THEN
                UPDATE schedules
                SET statut = 'VALIDE_DEPARTEMENT'
                WHERE id = p_schedule_id;
                
                INSERT INTO schedule_approvals 
                (schedule_id, approval_level, approver_id, action, comment)
                VALUES 
                (p_schedule_id, 'CHEF_DEPARTEMENT', p_chef_id, 'APPROVED', p_comment);
                
                COMMIT;
                SELECT 'SUCCESS' as status, 
                       'Schedule approved by Chef de Département and forwarded to Doyen' as message,
                       'VALIDE_DEPARTEMENT' as new_status;
            ELSE
                UPDATE schedules
                SET statut = 'BROUILLON'
                WHERE id = p_schedule_id;
                
                INSERT INTO schedule_approvals 
                (schedule_id, approval_level, approver_id, action, comment)
                VALUES 
                (p_schedule_id, 'CHEF_DEPARTEMENT', p_chef_id, 'REJECTED', p_comment);
                
                COMMIT;
                SELECT 'SUCCESS' as status, 
                       'Schedule rejected by Chef de Département. Sent back to Admin examens.' as message,
                       'BROUILLON' as new_status;
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;

-- ============================================
-- 4. DOYEN APPROVE SCHEDULE
-- ============================================

DELIMITER $$

CREATE PROCEDURE sp_doyen_approve_schedule(
    IN p_schedule_id INT,
    IN p_doyen_id INT,
    IN p_action ENUM('APPROVE', 'REJECT'),
    IN p_comment TEXT
)
BEGIN
    DECLARE v_current_status VARCHAR(50);
    DECLARE v_user_role VARCHAR(50);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'ERROR' as status, 'Transaction failed' as message;
    END;
    
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    START TRANSACTION;
    
    SELECT role INTO v_user_role
    FROM utilisateurs
    WHERE id = p_doyen_id;
    
    IF v_user_role NOT IN ('Doyen', 'Vice-doyen') THEN
        ROLLBACK;
        SELECT 'ERROR' as status, 'User must be Doyen or Vice-Doyen' as message;
    ELSE
        SELECT statut INTO v_current_status
        FROM schedules
        WHERE id = p_schedule_id
        FOR UPDATE;
        
        IF v_current_status IS NULL THEN
            ROLLBACK;
            SELECT 'ERROR' as status, 'Schedule not found' as message;
        
        ELSEIF v_current_status != 'VALIDE_DEPARTEMENT' THEN
            ROLLBACK;
            SELECT 'ERROR' as status, 
                   CONCAT('Cannot approve: Schedule status is ', v_current_status, 
                          '. Chef de Département must approve first (status must be VALIDE_DEPARTEMENT).') as message,
                   v_current_status as current_status;
        
        ELSE
            IF p_action = 'APPROVE' THEN
                UPDATE schedules
                SET statut = 'PUBLIE'
                WHERE id = p_schedule_id;
                
                INSERT INTO schedule_approvals 
                (schedule_id, approval_level, approver_id, action, comment)
                VALUES 
                (p_schedule_id, 'DOYEN', p_doyen_id, 'APPROVED', p_comment);
                
                COMMIT;
                SELECT 'SUCCESS' as status, 
                       'Schedule approved by Doyen and published successfully' as message,
                       'PUBLIE' as new_status;
            ELSE
                UPDATE schedules
                SET statut = 'GENERE'
                WHERE id = p_schedule_id;
                
                INSERT INTO schedule_approvals 
                (schedule_id, approval_level, approver_id, action, comment)
                VALUES 
                (p_schedule_id, 'DOYEN', p_doyen_id, 'REJECTED', p_comment);
                
                COMMIT;
                SELECT 'SUCCESS' as status, 
                       'Schedule rejected by Doyen. Sent back for re-evaluation.' as message,
                       'GENERE' as new_status;
            END IF;
        END IF;
    END IF;
END$$

DELIMITER ;

-- ============================================
-- 5. GET APPROVAL DETAILS
-- ============================================

DELIMITER $$

CREATE PROCEDURE sp_get_approval_details(
    IN p_schedule_id INT
)
BEGIN
    -- Main schedule info
    SELECT 
        s.id as schedule_id,
        f.nom as formation,
        f.code as formation_code,
        d.nom as department,
        s.statut as current_status,
        s.annee_universitaire,
        s.semester,
        
        -- Statistics
        COUNT(DISTINCT se.id) as total_exams,
        COUNT(DISTINCT ses.lieu_id) as total_rooms,
        COUNT(DISTINCT surv.enseignant_id) as total_supervisors,
        
        -- Timestamps
        s.created_at as schedule_created_at
        
    FROM schedules s
    JOIN formations f ON f.id = s.formation_id
    JOIN departements d ON d.id = f.department_id
    LEFT JOIN schedule_examens se ON se.schedule_id = s.id
    LEFT JOIN schedule_exam_salles ses ON ses.schedule_exam_id = se.id
    LEFT JOIN surveillances surv ON surv.examen_id = se.examen_id
    WHERE s.id = p_schedule_id
    GROUP BY s.id, f.nom, f.code, d.nom, s.statut,
             s.annee_universitaire, s.semester, s.created_at;
    
    -- Approval history
    SELECT 
        sa.id,
        sa.approval_level,
        sa.action,
        sa.comment,
        sa.approved_at,
        u.email as approver_email,
        CASE sa.approval_level
            WHEN 'CHEF_DEPARTEMENT' THEN CONCAT(cd.nom, ' ', cd.prenom)
            WHEN 'DOYEN' THEN CONCAT(d.nom, ' ', d.prenom)
        END as approver_name
        
    FROM schedule_approvals sa
    JOIN utilisateurs u ON u.id = sa.approver_id
    LEFT JOIN chefs_departement cd ON cd.id = sa.approver_id
    LEFT JOIN doyens d ON d.id = sa.approver_id
    WHERE sa.schedule_id = p_schedule_id
    ORDER BY sa.approved_at ASC;
END$$

DELIMITER ;

-- ============================================
-- 6. GET APPROVAL STATISTICS
-- ============================================

DELIMITER $$

CREATE PROCEDURE sp_get_approval_statistics(
    IN p_annee VARCHAR(20),
    IN p_semester ENUM('S1', 'S2')
)
BEGIN
    SELECT 
        COUNT(*) as total_schedules,
        
        -- By status
        SUM(CASE WHEN statut = 'BROUILLON' THEN 1 ELSE 0 END) as draft,
        SUM(CASE WHEN statut = 'GENERE' THEN 1 ELSE 0 END) as pending_chef,
        SUM(CASE WHEN statut = 'VALIDE_DEPARTEMENT' THEN 1 ELSE 0 END) as pending_doyen,
        SUM(CASE WHEN statut = 'PUBLIE' THEN 1 ELSE 0 END) as published,
        
        -- By department
        d.nom as department,
        COUNT(*) as dept_schedules,
        SUM(CASE WHEN statut = 'GENERE' THEN 1 ELSE 0 END) as dept_pending_chef,
        SUM(CASE WHEN statut = 'VALIDE_DEPARTEMENT' THEN 1 ELSE 0 END) as dept_pending_doyen,
        SUM(CASE WHEN statut = 'PUBLIE' THEN 1 ELSE 0 END) as dept_published
        
    FROM schedules s
    JOIN formations f ON f.id = s.formation_id
    JOIN departements d ON d.id = f.department_id
    WHERE s.annee_universitaire = p_annee
    AND s.semester = p_semester
    GROUP BY d.id, d.nom WITH ROLLUP;
END$$

DELIMITER ;

-- ============================================
-- VERIFICATION
-- ============================================

-- Test if procedures exist
SELECT ROUTINE_NAME 
FROM INFORMATION_SCHEMA.ROUTINES 
WHERE ROUTINE_SCHEMA = 'exam_scheduler_db' 
AND ROUTINE_TYPE = 'PROCEDURE'
AND ROUTINE_NAME LIKE '%approval%'
ORDER BY ROUTINE_NAME;
-- ============================================
-- END OF SCRIPT
-- ============================================
