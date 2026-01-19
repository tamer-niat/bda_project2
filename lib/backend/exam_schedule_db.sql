-- ============================================================================
-- Plateforme d'Optimisation des Emplois du Temps d'Examens Universitaires
-- Version améliorée selon les spécifications du projet
-- ============================================================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

-- ============================================================================
-- TABLES PRINCIPALES
-- ============================================================================

-- Table: departements
-- Gestion des 7 départements de la faculté
CREATE TABLE `departements` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `nom` VARCHAR(100) NOT NULL,
  `code` VARCHAR(10) NOT NULL UNIQUE,
  `responsable` VARCHAR(100) DEFAULT NULL,
  `email` VARCHAR(100) DEFAULT NULL,
  `date_creation` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_dept_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: formations
-- Plus de 200 offres de formation (6-9 modules par formation)
CREATE TABLE `formations` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `nom` VARCHAR(150) NOT NULL,
  `code` VARCHAR(20) NOT NULL UNIQUE,
  `dept_id` INT NOT NULL,
  `niveau` ENUM('L1', 'L2', 'L3', 'M1', 'M2', 'Doctorat') NOT NULL,
  `nb_modules` INT DEFAULT NULL CHECK (`nb_modules` BETWEEN 6 AND 10),
  `capacite_max` INT DEFAULT 500,
  `date_creation` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_form_dept` (`dept_id`),
  INDEX `idx_form_niveau` (`niveau`),
  FOREIGN KEY (`dept_id`) REFERENCES `departements` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: etudiants
-- Plus de 13,000 étudiants
CREATE TABLE `etudiants` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `matricule` VARCHAR(20) NOT NULL UNIQUE,
  `nom` VARCHAR(100) NOT NULL,
  `prenom` VARCHAR(100) NOT NULL,
  `formation_id` INT NOT NULL,
  `promo` VARCHAR(20) DEFAULT NULL,
  `email` VARCHAR(100) DEFAULT NULL,
  `telephone` VARCHAR(20) DEFAULT NULL,
  `date_naissance` DATE DEFAULT NULL,
  `date_inscription` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_etud_matricule` (`matricule`),
  INDEX `idx_etud_formation` (`formation_id`),
  INDEX `idx_etud_nom` (`nom`, `prenom`),
  FOREIGN KEY (`formation_id`) REFERENCES `formations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: modules
-- Modules avec prérequis possibles
CREATE TABLE `modules` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `nom` VARCHAR(150) NOT NULL,
  `code` VARCHAR(20) NOT NULL UNIQUE,
  `credits` INT DEFAULT NULL CHECK (`credits` > 0),
  `formation_id` INT NOT NULL,
  `semestre` ENUM('S1', 'S2') NOT NULL,
  `coef` DECIMAL(3,2) DEFAULT 1.00,
  `pre_requis_id` INT DEFAULT NULL,
  `duree_examen_minutes` INT DEFAULT 120 CHECK (`duree_examen_minutes` > 0),
  PRIMARY KEY (`id`),
  INDEX `idx_module_formation` (`formation_id`),
  INDEX `idx_module_code` (`code`),
  FOREIGN KEY (`formation_id`) REFERENCES `formations` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`pre_requis_id`) REFERENCES `modules` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: professeurs
-- Enseignants avec contrainte de surveillance équitable
CREATE TABLE `professeurs` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `nom` VARCHAR(100) NOT NULL,
  `prenom` VARCHAR(100) DEFAULT NULL,
  `dept_id` INT NOT NULL,
  `specialite` VARCHAR(100) DEFAULT NULL,
  `email` VARCHAR(100) DEFAULT NULL,
  `grade` ENUM('Professeur', 'Maitre de conferences A', 'Maitre de conferences B', 'Maitre assistant A', 'Maitre assistant B') DEFAULT NULL,
  `nb_max_surveillances_jour` INT DEFAULT 3,
  `date_recrutement` DATE DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_prof_dept` (`dept_id`),
  INDEX `idx_prof_nom` (`nom`, `prenom`),
  FOREIGN KEY (`dept_id`) REFERENCES `departements` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: lieux_examen
-- Salles et amphithéâtres avec capacités variables
CREATE TABLE `lieux_examen` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `nom` VARCHAR(50) NOT NULL,
  `code` VARCHAR(20) NOT NULL UNIQUE,
  `capacite` INT NOT NULL CHECK (`capacite` > 0),
  `capacite_examen` INT NOT NULL CHECK (`capacite_examen` > 0 AND `capacite_examen` <= `capacite`),
  `type` ENUM('Amphitheatre', 'Salle', 'Labo') NOT NULL,
  `batiment` VARCHAR(50) DEFAULT NULL,
  `etage` VARCHAR(10) DEFAULT NULL,
  `equipements` TEXT DEFAULT NULL,
  `disponible` BOOLEAN DEFAULT TRUE,
  PRIMARY KEY (`id`),
  INDEX `idx_lieu_type` (`type`),
  INDEX `idx_lieu_capacite` (`capacite_examen`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: inscriptions
-- Environ 130k inscriptions estimées
CREATE TABLE `inscriptions` (
  `etudiant_id` INT NOT NULL,
  `module_id` INT NOT NULL,
  `annee_universitaire` VARCHAR(10) NOT NULL DEFAULT '2024-2025',
  `note` DECIMAL(5,2) DEFAULT NULL CHECK (`note` BETWEEN 0 AND 20),
  `date_inscription` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`etudiant_id`, `module_id`),
  INDEX `idx_insc_module` (`module_id`),
  INDEX `idx_insc_annee` (`annee_universitaire`),
  FOREIGN KEY (`etudiant_id`) REFERENCES `etudiants` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`module_id`) REFERENCES `modules` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table: examens
-- Planning des examens avec toutes les contraintes
CREATE TABLE `examens` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `module_id` INT NOT NULL,
  `salle_id` INT NOT NULL,
  `date_examen` DATE NOT NULL,
  `heure_debut` TIME NOT NULL,
  `duree_minutes` INT NOT NULL CHECK (`duree_minutes` > 0),
  `session` ENUM('Normale', 'Rattrapage') DEFAULT 'Normale',
  `annee_universitaire` VARCHAR(10) NOT NULL DEFAULT '2024-2025',
  `statut` ENUM('Planifie', 'En cours', 'Termine', 'Annule') DEFAULT 'Planifie',
  `nb_inscrits` INT DEFAULT 0,
  `remarques` TEXT DEFAULT NULL,
  `date_creation` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `date_modification` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_exam_date` (`date_examen`, `heure_debut`),
  INDEX `idx_exam_module` (`module_id`),
  INDEX `idx_exam_salle` (`salle_id`),
  INDEX `idx_exam_statut` (`statut`),
  UNIQUE KEY `unique_salle_date_heure` (`salle_id`, `date_examen`, `heure_debut`),
  FOREIGN KEY (`module_id`) REFERENCES `modules` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`salle_id`) REFERENCES `lieux_examen` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table: surveillances
-- Gestion des surveillances avec équilibrage automatique
CREATE TABLE `surveillances` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `examen_id` INT NOT NULL,
  `prof_id` INT NOT NULL,
  `role` ENUM('Responsable', 'Surveillant') DEFAULT 'Surveillant',
  `priorite_dept` BOOLEAN DEFAULT FALSE,
  `date_attribution` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_surv_examen` (`examen_id`),
  INDEX `idx_surv_prof` (`prof_id`),
  INDEX `idx_surv_priorite` (`priorite_dept`),
  UNIQUE KEY `unique_prof_examen` (`examen_id`, `prof_id`),
  FOREIGN KEY (`examen_id`) REFERENCES `examens` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`prof_id`) REFERENCES `professeurs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table: contraintes_horaires
-- Contraintes spécifiques pour certains modules ou départements
CREATE TABLE `contraintes_horaires` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `type` ENUM('Module', 'Departement', 'Formation', 'Salle') NOT NULL,
  `reference_id` INT NOT NULL,
  `date_debut` DATE DEFAULT NULL,
  `date_fin` DATE DEFAULT NULL,
  `heure_debut` TIME DEFAULT NULL,
  `heure_fin` TIME DEFAULT NULL,
  `motif` TEXT DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_contrainte_type_ref` (`type`, `reference_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table: logs_generation
-- Historique et performances de génération d'emplois du temps
CREATE TABLE `logs_generation` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `utilisateur_id` INT DEFAULT NULL,
  `date_generation` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `duree_secondes` DECIMAL(6,2) DEFAULT NULL,
  `nb_examens_generes` INT DEFAULT 0,
  `nb_conflits_detectes` INT DEFAULT 0,
  `nb_conflits_resolus` INT DEFAULT 0,
  `statut` ENUM('Succes', 'Echec', 'Partiel') DEFAULT 'Succes',
  `parametres` JSON DEFAULT NULL,
  `erreurs` TEXT DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_log_date` (`date_generation`),
  INDEX `idx_log_statut` (`statut`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table: conflits_detectes
-- Suivi des conflits pour optimisation
CREATE TABLE `conflits_detectes` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `log_generation_id` INT DEFAULT NULL,
  `type_conflit` ENUM('Etudiant_double', 'Prof_surcharge', 'Salle_capacite', 'Salle_conflit', 'Contrainte_horaire') NOT NULL,
  `severite` ENUM('Critique', 'Majeure', 'Mineure') DEFAULT 'Majeure',
  `description` TEXT NOT NULL,
  `examen_id1` INT DEFAULT NULL,
  `examen_id2` INT DEFAULT NULL,
  `resolu` BOOLEAN DEFAULT FALSE,
  `date_detection` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_conflit_type` (`type_conflit`),
  INDEX `idx_conflit_resolu` (`resolu`),
  FOREIGN KEY (`log_generation_id`) REFERENCES `logs_generation` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`examen_id1`) REFERENCES `examens` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`examen_id2`) REFERENCES `examens` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Table: utilisateurs
-- Gestion des accès (Vice-doyen, Chef dept, Admin)
CREATE TABLE `utilisateurs` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(50) NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `nom` VARCHAR(100) NOT NULL,
  `prenom` VARCHAR(100) NOT NULL,
  `email` VARCHAR(100) NOT NULL UNIQUE,
  `role` ENUM('Vice-doyen', 'Doyen', 'Chef-departement', 'Admin-examens', 'Enseignant', 'Etudiant') NOT NULL,
  `dept_id` INT DEFAULT NULL,
  `actif` BOOLEAN DEFAULT TRUE,
  `derniere_connexion` TIMESTAMP NULL DEFAULT NULL,
  `date_creation` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_user_role` (`role`),
  INDEX `idx_user_dept` (`dept_id`),
  FOREIGN KEY (`dept_id`) REFERENCES `departements` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- VUES POUR FACILITER LES REQUÊTES
-- ============================================================================

-- Vue: v_examens_complets
-- Vue complète des examens avec toutes les informations
CREATE OR REPLACE VIEW v_examens_complets AS
SELECT 
    e.id AS examen_id,
    e.date_examen,
    e.heure_debut,
    e.duree_minutes,
    e.session,
    e.statut,
    m.nom AS module_nom,
    m.code AS module_code,
    f.nom AS formation_nom,
    f.niveau,
    d.nom AS departement_nom,
    l.nom AS salle_nom,
    l.capacite_examen,
    e.nb_inscrits,
    CASE 
        WHEN e.nb_inscrits > l.capacite_examen THEN 'Surcharge'
        WHEN e.nb_inscrits > l.capacite_examen * 0.9 THEN 'Presque plein'
        ELSE 'OK'
    END AS etat_capacite
FROM examens e
JOIN modules m ON e.module_id = m.id
JOIN formations f ON m.formation_id = f.id
JOIN departements d ON f.dept_id = d.id
JOIN lieux_examen l ON e.salle_id = l.id;

-- Vue: v_charge_professeurs
-- Charge de surveillance par professeur
CREATE OR REPLACE VIEW v_charge_professeurs AS
SELECT 
    p.id AS prof_id,
    p.nom,
    p.prenom,
    d.nom AS departement,
    COUNT(DISTINCT s.examen_id) AS nb_surveillances_total,
    COUNT(DISTINCT DATE(e.date_examen)) AS nb_jours_surveillance,
    AVG(nb_par_jour.nb_jour) AS moy_surveillances_par_jour
FROM professeurs p
JOIN departements d ON p.dept_id = d.id
LEFT JOIN surveillances s ON p.id = s.prof_id
LEFT JOIN examens e ON s.examen_id = e.id
LEFT JOIN (
    SELECT s2.prof_id, e2.date_examen, COUNT(*) as nb_jour
    FROM surveillances s2
    JOIN examens e2 ON s2.examen_id = e2.id
    GROUP BY s2.prof_id, e2.date_examen
) nb_par_jour ON p.id = nb_par_jour.prof_id
GROUP BY p.id, p.nom, p.prenom, d.nom;

-- Vue: v_occupation_salles
-- Taux d'occupation des salles
CREATE OR REPLACE VIEW v_occupation_salles AS
SELECT 
    l.id AS salle_id,
    l.nom AS salle_nom,
    l.type,
    l.capacite_examen,
    COUNT(e.id) AS nb_examens,
    AVG(e.nb_inscrits) AS moy_inscrits,
    SUM(e.duree_minutes) AS total_minutes_utilisation,
    SUM(e.duree_minutes) / 60.0 AS total_heures_utilisation
FROM lieux_examen l
LEFT JOIN examens e ON l.id = e.salle_id
GROUP BY l.id, l.nom, l.type, l.capacite_examen;

-- ============================================================================
-- INDEX ADDITIONNELS POUR OPTIMISATION
-- ============================================================================

-- Index composites pour requêtes de détection de conflits
CREATE INDEX idx_exam_date_heure_salle ON examens(date_examen, heure_debut, salle_id);
CREATE INDEX idx_exam_module_date ON examens(module_id, date_examen);

-- Index pour les recherches par étudiant
CREATE INDEX idx_insc_etud_module ON inscriptions(etudiant_id, module_id);

-- Index pour les statistiques
CREATE INDEX idx_exam_annee_session ON examens(annee_universitaire, session);

-- ============================================================================
-- DONNÉES DE BASE
-- ============================================================================

-- Départements (7 départements)
INSERT INTO `departements` (`id`, `nom`, `code`) VALUES
(1, 'Departement d''Informatique', 'INFO'),
(2, 'Departement de Chimie', 'CHIM'),
(3, 'Departement de Physique', 'PHYS'),
(4, 'Departement de Mathematiques', 'MATH'),
(5, 'Departement de Biologie', 'BIO'),
(6, 'Departement de Medecine', 'MED'),
(7, 'Departement d''Agronomie', 'AGRO');

-- Formations
INSERT INTO `formations` (`id`, `nom`, `code`, `dept_id`, `niveau`, `nb_modules`) VALUES
(1, 'Licence Informatique', 'L-INFO', 1, 'L3', 6),
(2, 'Master Informatique', 'M-INFO', 1, 'M1', 8),
(3, 'Licence Chimie', 'L-CHIM', 2, 'L3', 6),
(4, 'Licence Physique', 'L-PHYS', 3, 'L3', 6),
(5, 'Licence Mathematiques', 'L-MATH', 4, 'L3', 6),
(6, 'Licence Biologie', 'L-BIO', 5, 'L3', 6),
(7, 'Medecine', 'MED', 6, 'L3', 10),
(8, 'Licence Agronomie', 'L-AGRO', 7, 'L3', 6);

-- Étudiants (échantillon - vous devrez en générer plus pour atteindre 13000+)
INSERT INTO `etudiants` (`id`, `matricule`, `nom`, `prenom`, `formation_id`, `promo`) VALUES
(1, 'E001', 'Belaid', 'Amine', 1, 'L3'),
(2, 'E002', 'Kaci', 'Nour', 1, 'L3'),
(3, 'E003', 'Boudjemaa', 'Yasmine', 1, 'L3'),
(4, 'E004', 'Ali', 'Mohamed', 1, 'L3'),
(5, 'E005', 'Saidi', 'Rania', 1, 'L3'),
(6, 'E006', 'Cherif', 'Yacine', 1, 'L3'),
(7, 'E007', 'Benali', 'Sara', 2, 'M1'),
(8, 'E008', 'Hamdi', 'Omar', 2, 'M1'),
(9, 'E009', 'Zerrouki', 'Lina', 2, 'M1'),
(10, 'E010', 'Ait Salah', 'Imene', 2, 'M1'),
(11, 'E011', 'Mokhtar', 'Nadia', 3, 'L3'),
(12, 'E012', 'Haddad', 'Samir', 3, 'L3'),
(13, 'E013', 'Bouaziz', 'Ines', 3, 'L3'),
(14, 'E014', 'Amari', 'Walid', 3, 'L3'),
(15, 'E015', 'Rahmani', 'Yanis', 4, 'L3'),
(16, 'E016', 'Bensaid', 'Lamia', 4, 'L3'),
(17, 'E017', 'Khelifi', 'Hichem', 4, 'L3'),
(18, 'E018', 'Toumi', 'Amel', 4, 'L3'),
(19, 'E019', 'Mansouri', 'Amina', 5, 'L3'),
(20, 'E020', 'Belkacem', 'Nabil', 5, 'L3'),
(21, 'E021', 'Saad', 'Karim', 5, 'L3'),
(22, 'E022', 'Ziani', 'Fatima', 5, 'L3'),
(23, 'E023', 'Yefsah', 'Salima', 6, 'L3'),
(24, 'E024', 'Kaci', 'Sofiane', 6, 'L3'),
(25, 'E025', 'Dahmani', 'Meriem', 6, 'L3'),
(26, 'E026', 'Larbi', 'Anis', 6, 'L3'),
(27, 'E027', 'Hamidi', 'Imane', 7, 'M1'),
(28, 'E028', 'Zoubir', 'Youssef', 7, 'M1'),
(29, 'E029', 'Bouras', 'Nesrine', 7, 'M1'),
(30, 'E030', 'Touati', 'Ahmed', 7, 'M1'),
(31, 'E031', 'Meziani', 'Lilia', 7, 'M1'),
(32, 'E032', 'Ait Ali', 'Riad', 7, 'M1'),
(33, 'E033', 'Amrani', 'Sabrina', 8, 'L3'),
(34, 'E034', 'Boudia', 'Reda', 8, 'L3'),
(35, 'E035', 'Guerfi', 'Nour', 8, 'L3'),
(36, 'E036', 'Kherra', 'Sami', 8, 'L3');

-- Modules
INSERT INTO `modules` (`id`, `nom`, `code`, `credits`, `formation_id`, `semestre`, `duree_examen_minutes`) VALUES
(1, 'Bases de donnees', 'BD', 6, 1, 'S1', 120),
(2, 'Reseaux', 'RES', 5, 1, 'S1', 120),
(3, 'Systemes d''exploitation', 'SE', 5, 1, 'S1', 120),
(4, 'Programmation Java', 'JAVA', 6, 1, 'S2', 180),
(5, 'Genie logiciel', 'GL', 5, 1, 'S2', 120),
(6, 'Intelligence artificielle', 'IA', 5, 1, 'S2', 120),
(7, 'Big Data', 'BIGDATA', 6, 2, 'S1', 180),
(8, 'Machine Learning', 'ML', 6, 2, 'S1', 180),
(9, 'Securite informatique', 'SECU', 5, 2, 'S2', 120),
(10, 'Cloud Computing', 'CLOUD', 5, 2, 'S2', 120),
(11, 'Chimie organique', 'CHORG', 5, 3, 'S1', 120),
(12, 'Chimie minerale', 'CHMIN', 5, 3, 'S1', 120),
(13, 'Mecanique', 'MEC', 5, 4, 'S1', 120),
(14, 'Optique', 'OPT', 5, 4, 'S1', 120),
(15, 'Analyse', 'ANA', 5, 5, 'S1', 120),
(16, 'Algebre', 'ALG', 5, 5, 'S1', 120),
(17, 'Biologie cellulaire', 'BIOCELL', 5, 6, 'S1', 120),
(18, 'Genetique', 'GEN', 5, 6, 'S1', 120),
(19, 'Anatomie', 'ANAT', 6, 7, 'S1', 180),
(20, 'Physiologie', 'PHYSIO', 6, 7, 'S1', 180),
(21, 'Histologie', 'HISTO', 5, 7, 'S2', 120),
(22, 'Agronomie generale', 'AGROGEN', 5, 8, 'S1', 120),
(23, 'Production vegetale', 'PRODVEG', 5, 8, 'S1', 120);

-- Lieux d'examen (capacité examen réduite selon contraintes)
INSERT INTO `lieux_examen` (`id`, `nom`, `code`, `capacite`, `capacite_examen`, `type`, `batiment`) VALUES
(1, 'Amphi Central', 'AMP-CENT', 300, 300, 'Amphitheatre', 'Bloc Central'),
(2, 'Amphi A', 'AMP-A', 200, 200, 'Amphitheatre', 'Bloc A'),
(3, 'Amphi B', 'AMP-B', 150, 150, 'Amphitheatre', 'Bloc B'),
(4, 'Salle TP 1', 'TP1', 40, 20, 'Salle', 'Bloc C'),
(5, 'Salle TP 2', 'TP2', 35, 20, 'Salle', 'Bloc C'),
(6, 'Salle TD 1', 'TD1', 30, 20, 'Salle', 'Bloc D'),
(7, 'Salle TD 2', 'TD2', 30, 20, 'Salle', 'Bloc D');

-- Professeurs
INSERT INTO `professeurs` (`id`, `nom`, `prenom`, `dept_id`, `specialite`) VALUES
(1, 'Belkacemi', 'Ahmed', 1, 'Bases de donnees'),
(2, 'Hamadouche', 'Karima', 1, 'Reseaux'),
(3, 'Cherif', 'Farid', 2, 'Chimie organique'),
(4, 'Ait Ahmed', 'Naima', 2, 'Chimie minerale'),
(5, 'Bouzid', 'Rachid', 3, 'Physique generale'),
(6, 'Rahmani', 'Samia', 3, 'Mecanique'),
(7, 'Mansouri', 'Kamel', 4, 'Analyse mathematique'),
(8, 'Belkacem', 'Leila', 4, 'Algebre'),
(9, 'Yefsah', 'Mourad', 5, 'Biologie cellulaire'),
(10, 'Khelifi', 'Dalila', 5, 'Genetique'),
(11, 'Hamidi', 'Sofiane', 6, 'Anatomie'),
(12, 'Zoubir', 'Amina', 6, 'Physiologie'),
(13, 'Amrani', 'Youcef', 7, 'Agronomie generale'),
(14, 'Boudia', 'Melissa', 7, 'Production vegetale');

-- Inscriptions (échantillon)
INSERT INTO `inscriptions` (`etudiant_id`, `module_id`) VALUES
(1, 1), (1, 2), (1, 3),
(2, 1), (2, 4), (2, 5),
(3, 2), (3, 3), (3, 6),
(4, 1), (4, 5), (4, 6),
(5, 2), (5, 3), (5, 4),
(6, 1), (6, 2), (6, 6),
(7, 7), (7, 8),
(8, 8), (8, 9),
(9, 7), (9, 10),
(10, 8), (10, 9),
(11, 11), (11, 12),
(12, 11), (12, 12),
(13, 11), (13, 12),
(14, 11), (14, 12),
(15, 13), (15, 14),
(16, 13), (16, 14),
(17, 13), (17, 14),
(18, 13), (18, 14),
(19, 15), (19, 16),
(20, 15), (20, 16),
(21, 15), (21, 16),
(22, 15), (22, 16),
(23, 17), (23, 18),
(24, 17), (24, 18),
(25, 17), (25, 18),
(26, 17), (26, 18),
(27, 19), (27, 20), (27, 21),
(28, 19), (28, 20), (28, 21),
(29, 19), (29, 20), (29, 21),
(30, 19), (30, 20), (30, 21),
(31, 19), (31, 20), (31, 21),
(32, 19), (32, 20), (32, 21),
(33, 22), (33, 23),
(34, 22), (34, 23),
(35, 22), (35, 23),
(36, 22), (36, 23);

-- ============================================================================
-- PROCÉDURES STOCKÉES UTILES
-- ============================================================================

DELIMITER $$

-- Procédure: Calculer le nombre d'inscrits par examen
CREATE PROCEDURE sp_update_nb_inscrits()
BEGIN
    UPDATE examens e
    SET nb_inscrits = (
        SELECT COUNT(DISTINCT i.etudiant_id)
        FROM inscriptions i
        WHERE i.module_id = e.module_id
    );
END$$

-- Procédure: Détecter les conflits étudiants (max 1 examen/jour)
CREATE PROCEDURE sp_detect_conflits_etudiants()
BEGIN
    SELECT 
        e1.id AS examen1_id,
        e2.id AS examen2_id,
        et.id AS etudiant_id,
        et.nom,
        et.prenom,
        e1.date_examen,
        m1.nom AS module1,
        m2.nom AS module2
    FROM examens e1
    JOIN examens e2 ON e1.date_examen = e2.date_examen AND e1.id < e2.id
    JOIN inscriptions i1 ON e1.module_id = i1.module_id
    JOIN inscriptions i2 ON e2.module_id = i2.module_id AND i1.etudiant_id = i2.etudiant_id
    JOIN etudiants et ON i1.etudiant_id = et.id
    JOIN modules m1 ON e1.module_id = m1.id
    JOIN modules m2 ON e2.module_id = m2.id
    WHERE e1.statut = 'Planifie' AND e2.statut = 'Planifie'
    ORDER BY e1.date_examen, et.nom;
END$$

-- Procédure: Détecter les conflits de salles
CREATE PROCEDURE sp_detect_conflits_salles()
BEGIN
    SELECT 
        e1.id AS examen1_id,
        e2.id AS examen2_id,
        l.nom AS salle,
        e1.date_examen,
        e1.heure_debut AS heure1,
        e2.heure_debut AS heure2,
        m1.nom AS module1,
        m2.nom AS module2
    FROM examens e1
    JOIN examens e2 ON 
        e1.salle_id = e2.salle_id 
        AND e1.date_examen = e2.date_examen 
        AND e1.id < e2.id
        AND (
            (e1.heure_debut <= e2.heure_debut 
             AND ADDTIME(e1.heure_debut, SEC_TO_TIME(e1.duree_minutes * 60)) > e2.heure_debut)
            OR
            (e2.heure_debut <= e1.heure_debut 
             AND ADDTIME(e2.heure_debut, SEC_TO_TIME(e2.duree_minutes * 60)) > e1.heure_debut)
        )
    JOIN lieux_examen l ON e1.salle_id = l.id
    JOIN modules m1 ON e1.module_id = m1.id
    JOIN modules m2 ON e2.module_id = m2.id
    WHERE e1.statut = 'Planifie' AND e2.statut = 'Planifie';
END$$

-- Procédure: Vérifier la surcharge des professeurs (max 3/jour)
CREATE PROCEDURE sp_detect_surcharge_profs()
BEGIN
    SELECT 
        p.id AS prof_id,
        p.nom,
        p.prenom,
        e.date_examen,
        COUNT(*) AS nb_surveillances_jour
    FROM surveillances s
    JOIN professeurs p ON s.prof_id = p.id
    JOIN examens e ON s.examen_id = e.id
    WHERE e.statut = 'Planifie'
    GROUP BY p.id, p.nom, p.prenom, e.date_examen
    HAVING COUNT(*) > 3
    ORDER BY nb_surveillances_jour DESC, e.date_examen;
END$$

-- Procédure: Vérifier le déséquilibre des surveillances
CREATE PROCEDURE sp_detect_desequilibre_surveillances()
BEGIN
    SELECT 
        p.id,
        p.nom,
        p.prenom,
        d.nom AS departement,
        COUNT(s.id) AS nb_surveillances,
        (SELECT AVG(cnt) FROM (
            SELECT COUNT(*) as cnt
            FROM surveillances s2
            JOIN examens e2 ON s2.examen_id = e2.id
            WHERE e2.statut = 'Planifie'
            GROUP BY s2.prof_id
        ) AS subq) AS moy_surveillances,
        COUNT(s.id) - (SELECT AVG(cnt) FROM (
            SELECT COUNT(*) as cnt
            FROM surveillances s2
            JOIN examens e2 ON s2.examen_id = e2.id
            WHERE e2.statut = 'Planifie'
            GROUP BY s2.prof_id
        ) AS subq) AS ecart
    FROM professeurs p
    JOIN departements d ON p.dept_id = d.id
    LEFT JOIN surveillances s ON p.id = s.prof_id
    LEFT JOIN examens e ON s.examen_id = e.id AND e.statut = 'Planifie'
    GROUP BY p.id, p.nom, p.prenom, d.nom
    ORDER BY ABS(COUNT(s.id) - (SELECT AVG(cnt) FROM (
        SELECT COUNT(*) as cnt
        FROM surveillances s2
        JOIN examens e2 ON s2.examen_id = e2.id
        WHERE e2.statut = 'Planifie'
        GROUP BY s2.prof_id
    ) AS subq)) DESC;
END$$

-- Procédure: Statistiques globales
CREATE PROCEDURE sp_stats_globales()
BEGIN
    SELECT 
        'Total Departements' AS indicateur,
        COUNT(*) AS valeur
    FROM departements
    UNION ALL
    SELECT 'Total Formations', COUNT(*) FROM formations
    UNION ALL
    SELECT 'Total Etudiants', COUNT(*) FROM etudiants
    UNION ALL
    SELECT 'Total Modules', COUNT(*) FROM modules
    UNION ALL
    SELECT 'Total Inscriptions', COUNT(*) FROM inscriptions
    UNION ALL
    SELECT 'Total Professeurs', COUNT(*) FROM professeurs
    UNION ALL
    SELECT 'Total Salles', COUNT(*) FROM lieux_examen
    UNION ALL
    SELECT 'Examens Planifies', COUNT(*) FROM examens WHERE statut = 'Planifie'
    UNION ALL
    SELECT 'Surveillances Attribuees', COUNT(*) FROM surveillances;
END$$

DELIMITER ;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

DELIMITER $$

-- Trigger: Mettre à jour nb_inscrits lors d'insertion d'examen
CREATE TRIGGER trg_after_exam_insert
AFTER INSERT ON examens
FOR EACH ROW
BEGIN
    UPDATE examens
    SET nb_inscrits = (
        SELECT COUNT(DISTINCT i.etudiant_id)
        FROM inscriptions i
        WHERE i.module_id = NEW.module_id
    )
    WHERE id = NEW.id;
END$$

-- Trigger: Vérifier capacité salle lors de l'insertion d'examen
CREATE TRIGGER trg_check_capacite_before_insert
BEFORE INSERT ON examens
FOR EACH ROW
BEGIN
    DECLARE v_capacite INT;
    DECLARE v_nb_inscrits INT;
    
    SELECT capacite_examen INTO v_capacite
    FROM lieux_examen
    WHERE id = NEW.salle_id;
    
    SELECT COUNT(*) INTO v_nb_inscrits
    FROM inscriptions
    WHERE module_id = NEW.module_id;
    
    IF v_nb_inscrits > v_capacite THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Capacite de la salle insuffisante pour le nombre d''inscrits';
    END IF;
END$$

DELIMITER ;

-- ============================================================================
-- FIN DU SCRIPT
-- ============================================================================

COMMIT;