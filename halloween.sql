-- ========================================
-- HALLOWEEN VRP - SQL INSTALLATION
-- ========================================

-- Tabla para el sistema de Caza de Fantasmas
CREATE TABLE IF NOT EXISTS `halloween_ghosthunt` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `found` int DEFAULT 0,
  `foundGhosts` json DEFAULT '[]',
  `date` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier` (`identifier`),
  KEY `idx_found` (`found`),
  KEY `idx_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla para el sistema de Caza de Calabazas
CREATE TABLE IF NOT EXISTS `halloween_pumpkinhunt` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `pumpkins_opened` int DEFAULT 0,
  `last_completion` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier` (`identifier`),
  KEY `idx_pumpkins` (`pumpkins_opened`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla para control de vehículos recogidos
CREATE TABLE IF NOT EXISTS `halloween_vehicle_claims` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `identifier` varchar(50) NOT NULL,
    `name` varchar(100) DEFAULT NULL,
    `mission_type` varchar(50) NOT NULL,
    `vehicle` varchar(50) NOT NULL,
    `claimed_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_claim` (`identifier`, `mission_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================
-- INFORMACIÓN
-- ========================================
-- 
-- Compatible con:
--    - VRP (user_id)
--    - VRPEX (user_id)
--    - ESX (identifier)
--    - QBCore (citizenid)
-- 
-- Las tablas se crean automáticamente al iniciar el recurso
-- 
-- ========================================
