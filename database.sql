-- phpMyAdmin SQL Dump
-- version 5.1.1deb5ubuntu1
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost
-- Tiempo de generación: 14-07-2025 a las 18:48:18
-- Versión del servidor: 8.0.42-0ubuntu0.22.04.1
-- Versión de PHP: 8.4.10

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `url_shortener`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `BanUser` (IN `p_user_id` INT, IN `p_reason` TEXT, IN `p_banned_by` INT)  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Actualizar estado del usuario
    UPDATE users 
    SET status = 'banned', 
        banned_reason = p_reason, 
        banned_at = NOW(), 
        banned_by = p_banned_by
    WHERE id = p_user_id AND status != 'banned';
    
    -- Desactivar todas las sesiones
    UPDATE user_sessions 
    SET is_active = 0 
    WHERE user_id = p_user_id;
    
    -- Desactivar todas las URLs del usuario
    UPDATE urls 
    SET active = 0 
    WHERE user_id = p_user_id;
    
    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `cleanup_old_data` ()  BEGIN
    
    DELETE FROM rate_limit WHERE created_at < DATE_SUB(NOW(), INTERVAL 24 HOUR);
    
    
    DELETE FROM sessions WHERE last_activity < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 7 DAY));
    
    
    
    
    
    
    UPDATE urls SET active = 0 WHERE expires_at IS NOT NULL AND expires_at < NOW();
    
    
    UPDATE urls SET active = 0 WHERE max_clicks IS NOT NULL AND clicks >= max_clicks;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UnbanUser` (IN `p_user_id` INT)  BEGIN
    UPDATE users 
    SET status = 'active', 
        banned_reason = NULL, 
        banned_at = NULL, 
        banned_by = NULL,
        failed_login_attempts = 0,
        locked_until = NULL
    WHERE id = p_user_id;
    
    -- Reactivar URLs del usuario
    UPDATE urls 
    SET active = 1 
    WHERE user_id = p_user_id;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `admin_sessions`
--

CREATE TABLE `admin_sessions` (
  `id` int NOT NULL,
  `session_id` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` timestamp NOT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `api_keys`
--

CREATE TABLE `api_keys` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `name` varchar(100) NOT NULL,
  `key_hash` varchar(255) NOT NULL,
  `last_four` char(4) NOT NULL,
  `permissions` json DEFAULT NULL,
  `rate_limit` int DEFAULT '1000',
  `expires_at` datetime DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `revoked_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `click_stats`
--

CREATE TABLE `click_stats` (
  `id` int NOT NULL,
  `url_id` int DEFAULT NULL,
  `user_id` int DEFAULT NULL,
  `session_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `clicked_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci,
  `referer` text COLLATE utf8mb4_unicode_ci,
  `country_code` varchar(2) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `region` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `timezone` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `country` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `accessed_domain` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `click_stats`
--

INSERT INTO `click_stats` (`id`, `url_id`, `user_id`, `session_id`, `clicked_at`, `ip_address`, `user_agent`, `referer`, `country_code`, `region`, `latitude`, `longitude`, `timezone`, `country`, `city`, `accessed_domain`) VALUES
(17, 20, NULL, NULL, '2025-07-09 13:23:51', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:128.0) Gecko/20100101 Firefox/128.0', '', 'ES', 'PV', '43.26540000', '-2.92650000', 'Europe/Madrid', 'Spain', 'Bilbao', NULL),
(18, 13, NULL, NULL, '2025-07-06 13:36:24', '247.127.215.26', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Las Palmas', '28.12350000', '-15.43630000', NULL, 'España', 'Las Palmas', NULL),
(19, 20, NULL, NULL, '2025-07-01 13:36:24', '225.31.223.215', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Zaragoza', '41.64880000', '-0.88910000', NULL, 'España', 'Zaragoza', NULL),
(20, 21, NULL, NULL, '2025-07-08 13:36:24', '190.177.57.36', 'Mozilla/5.0 Test Browser', NULL, 'Po', 'Lisboa', '38.72230000', '-9.13930000', NULL, 'Portugal', 'Lisboa', NULL),
(21, 20, NULL, NULL, '2025-06-29 13:36:42', '131.18.165.71', 'Mozilla/5.0 Test Browser', NULL, 'It', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma', NULL),
(22, 13, NULL, NULL, '2025-06-23 13:36:42', '255.249.89.197', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao', NULL),
(23, 20, NULL, NULL, '2025-06-20 13:36:42', '131.98.28.133', 'Mozilla/5.0 Test Browser', NULL, 'Re', 'Londres', '51.50740000', '-0.12780000', NULL, 'Reino Unido', 'Londres', NULL),
(24, 13, NULL, NULL, '2025-06-20 13:36:42', '146.7.124.59', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Las Palmas', '28.12350000', '-15.43630000', NULL, 'España', 'Las Palmas', NULL),
(25, 20, NULL, NULL, '2025-07-04 13:36:42', '151.1.37.148', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia', NULL),
(26, 21, NULL, NULL, '2025-07-08 13:36:42', '221.10.17.233', 'Mozilla/5.0 Test Browser', NULL, 'Fr', 'París', '48.85660000', '2.35220000', NULL, 'Francia', 'París', NULL),
(27, 20, NULL, NULL, '2025-06-20 13:36:42', '208.40.90.186', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia', NULL),
(28, 13, NULL, NULL, '2025-07-07 13:36:42', '191.3.0.148', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona', NULL),
(29, 20, NULL, NULL, '2025-06-25 13:36:42', '21.49.87.92', 'Mozilla/5.0 Test Browser', NULL, 'Al', 'Berlín', '52.52000000', '13.40500000', NULL, 'Alemania', 'Berlín', NULL),
(30, 13, NULL, NULL, '2025-07-06 13:36:42', '39.113.69.106', 'Mozilla/5.0 Test Browser', NULL, 'Po', 'Lisboa', '38.72230000', '-9.13930000', NULL, 'Portugal', 'Lisboa', NULL),
(31, 21, NULL, NULL, '2025-07-06 13:36:42', '158.202.148.229', 'Mozilla/5.0 Test Browser', NULL, 'Po', 'Lisboa', '38.72230000', '-9.13930000', NULL, 'Portugal', 'Lisboa', NULL),
(32, 21, NULL, NULL, '2025-07-03 13:36:42', '237.228.23.24', 'Mozilla/5.0 Test Browser', NULL, 'Po', 'Lisboa', '38.72230000', '-9.13930000', NULL, 'Portugal', 'Lisboa', NULL),
(33, 13, NULL, NULL, '2025-06-18 13:36:42', '250.43.85.19', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Madrid', '40.41680000', '-3.70380000', NULL, 'España', 'Madrid', NULL),
(34, 21, NULL, NULL, '2025-06-11 13:36:42', '253.61.63.146', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Málaga', '36.72130000', '-4.42140000', NULL, 'España', 'Málaga', NULL),
(35, 13, NULL, NULL, '2025-06-21 13:36:42', '29.197.18.140', 'Mozilla/5.0 Test Browser', NULL, 'It', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma', NULL),
(36, 21, NULL, NULL, '2025-07-05 13:36:42', '107.161.117.9', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Zaragoza', '41.64880000', '-0.88910000', NULL, 'España', 'Zaragoza', NULL),
(37, 20, NULL, NULL, '2025-06-12 13:36:42', '209.154.57.46', 'Mozilla/5.0 Test Browser', NULL, 'Pe', 'Lima', '-12.04640000', '-77.04280000', NULL, 'Perú', 'Lima', NULL),
(38, 21, NULL, NULL, '2025-07-08 13:36:42', '186.169.136.186', 'Mozilla/5.0 Test Browser', NULL, 'It', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma', NULL),
(39, 13, NULL, NULL, '2025-06-22 13:36:42', '9.183.10.71', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia', NULL),
(40, 13, NULL, NULL, '2025-06-19 13:36:42', '216.94.59.71', 'Mozilla/5.0 Test Browser', NULL, 'Br', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo', NULL),
(41, 13, NULL, NULL, '2025-06-20 13:36:42', '244.55.155.39', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao', NULL),
(42, 21, NULL, NULL, '2025-07-05 13:36:42', '27.27.66.57', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao', NULL),
(43, 20, NULL, NULL, '2025-06-14 13:36:42', '153.170.91.63', 'Mozilla/5.0 Test Browser', NULL, 'Br', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo', NULL),
(44, 20, NULL, NULL, '2025-06-17 13:36:42', '89.110.87.126', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma', NULL),
(45, 21, NULL, NULL, '2025-07-05 13:36:42', '229.20.187.150', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona', NULL),
(46, 20, NULL, NULL, '2025-06-24 13:36:42', '157.112.165.238', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Málaga', '36.72130000', '-4.42140000', NULL, 'España', 'Málaga', NULL),
(47, 21, NULL, NULL, '2025-07-04 13:36:42', '11.8.189.149', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Málaga', '36.72130000', '-4.42140000', NULL, 'España', 'Málaga', NULL),
(48, 13, NULL, NULL, '2025-07-02 13:36:42', '246.97.28.100', 'Mozilla/5.0 Test Browser', NULL, 'Re', 'Londres', '51.50740000', '-0.12780000', NULL, 'Reino Unido', 'Londres', NULL),
(49, 13, NULL, NULL, '2025-06-18 13:36:42', '139.94.168.246', 'Mozilla/5.0 Test Browser', NULL, 'Ar', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires', NULL),
(50, 13, NULL, NULL, '2025-06-14 13:36:42', '145.130.44.161', 'Mozilla/5.0 Test Browser', NULL, 'Ar', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires', NULL),
(51, 13, NULL, NULL, '2025-07-09 13:36:42', '96.96.98.20', 'Mozilla/5.0 Test Browser', NULL, 'Al', 'Berlín', '52.52000000', '13.40500000', NULL, 'Alemania', 'Berlín', NULL),
(52, 13, NULL, NULL, '2025-06-22 13:36:42', '154.18.17.150', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Zaragoza', '41.64880000', '-0.88910000', NULL, 'España', 'Zaragoza', NULL),
(53, 21, NULL, NULL, '2025-06-14 13:36:42', '146.191.211.166', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Nueva York', '40.71280000', '-74.00600000', NULL, 'Estados Unidos', 'Nueva York', NULL),
(54, 20, NULL, NULL, '2025-06-25 13:36:42', '60.97.176.78', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Málaga', '36.72130000', '-4.42140000', NULL, 'España', 'Málaga', NULL),
(55, 21, NULL, NULL, '2025-06-12 13:36:42', '228.132.7.47', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Zaragoza', '41.64880000', '-0.88910000', NULL, 'España', 'Zaragoza', NULL),
(56, 21, NULL, NULL, '2025-06-09 13:36:42', '84.120.125.179', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao', NULL),
(57, 13, NULL, NULL, '2025-06-29 13:36:42', '33.239.164.72', 'Mozilla/5.0 Test Browser', NULL, 'Ar', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires', NULL),
(58, 21, NULL, NULL, '2025-06-20 13:36:42', '86.206.186.189', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia', NULL),
(59, 13, NULL, NULL, '2025-07-05 13:36:42', '170.191.118.66', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Nueva York', '40.71280000', '-74.00600000', NULL, 'Estados Unidos', 'Nueva York', NULL),
(60, 13, NULL, NULL, '2025-06-17 13:36:42', '4.222.47.115', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma', NULL),
(61, 13, NULL, NULL, '2025-06-28 13:36:42', '224.10.114.91', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Las Palmas', '28.12350000', '-15.43630000', NULL, 'España', 'Las Palmas', NULL),
(62, 21, NULL, NULL, '2025-06-23 13:36:42', '92.191.58.122', 'Mozilla/5.0 Test Browser', NULL, 'Br', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo', NULL),
(63, 20, NULL, NULL, '2025-06-19 13:36:42', '221.238.148.229', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma', NULL),
(64, 13, NULL, NULL, '2025-06-17 13:36:42', '202.147.142.101', 'Mozilla/5.0 Test Browser', NULL, 'Al', 'Berlín', '52.52000000', '13.40500000', NULL, 'Alemania', 'Berlín', NULL),
(65, 21, NULL, NULL, '2025-06-28 13:51:22', '192.66.93.203', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo', NULL),
(66, 21, NULL, NULL, '2025-06-11 13:51:22', '244.52.42.200', 'Mozilla/5.0 Test Browser', NULL, 'GB', 'Londres', '51.50740000', '-0.12780000', NULL, 'Reino Unido', 'Londres', NULL),
(67, 21, NULL, NULL, '2025-06-22 13:51:22', '234.55.23.78', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Madrid', '40.41680000', '-3.70380000', NULL, 'España', 'Madrid', NULL),
(68, 20, NULL, NULL, '2025-07-05 13:51:22', '172.232.234.164', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Murcia', '37.99220000', '-1.13070000', NULL, 'España', 'Murcia', NULL),
(69, 13, NULL, NULL, '2025-06-14 13:51:22', '36.230.92.182', 'Mozilla/5.0 Test Browser', NULL, 'FR', 'París', '48.85660000', '2.35220000', NULL, 'Francia', 'París', NULL),
(70, 20, NULL, NULL, '2025-06-13 13:51:22', '16.60.5.75', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao', NULL),
(71, 20, NULL, NULL, '2025-06-15 13:51:22', '84.144.33.79', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo', NULL),
(72, 13, NULL, NULL, '2025-06-29 13:51:22', '14.85.66.37', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona', NULL),
(73, 20, NULL, NULL, '2025-06-28 13:51:22', '23.83.127.97', 'Mozilla/5.0 Test Browser', NULL, 'GB', 'Londres', '51.50740000', '-0.12780000', NULL, 'Reino Unido', 'Londres', NULL),
(74, 20, NULL, NULL, '2025-06-17 13:51:22', '32.8.168.198', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Málaga', '36.72130000', '-4.42140000', NULL, 'España', 'Málaga', NULL),
(75, 13, NULL, NULL, '2025-06-19 13:51:22', '18.150.163.98', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma', NULL),
(76, 20, NULL, NULL, '2025-07-08 13:51:22', '45.102.172.109', 'Mozilla/5.0 Test Browser', NULL, 'IT', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma', NULL),
(77, 20, NULL, NULL, '2025-07-02 13:51:22', '239.24.131.133', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Las Palmas', '28.12350000', '-15.43630000', NULL, 'España', 'Las Palmas', NULL),
(78, 21, NULL, NULL, '2025-07-07 13:51:23', '190.232.54.127', 'Mozilla/5.0 Test Browser', NULL, 'FR', 'París', '48.85660000', '2.35220000', NULL, 'Francia', 'París', NULL),
(79, 21, NULL, NULL, '2025-06-20 13:51:23', '95.164.183.134', 'Mozilla/5.0 Test Browser', NULL, 'FR', 'París', '48.85660000', '2.35220000', NULL, 'Francia', 'París', NULL),
(80, 13, NULL, NULL, '2025-06-10 13:51:23', '232.40.250.218', 'Mozilla/5.0 Test Browser', NULL, 'DE', 'Berlín', '52.52000000', '13.40500000', NULL, 'Alemania', 'Berlín', NULL),
(81, 13, NULL, NULL, '2025-06-10 13:51:23', '115.21.119.168', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Sevilla', '37.38910000', '-5.98450000', NULL, 'España', 'Sevilla', NULL),
(82, 21, NULL, NULL, '2025-06-13 13:51:23', '130.244.228.188', 'Mozilla/5.0 Test Browser', NULL, 'MX', 'México DF', '19.43260000', '-99.13320000', NULL, 'México', 'México DF', NULL),
(83, 20, NULL, NULL, '2025-06-26 13:51:23', '222.119.3.120', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona', NULL),
(84, 13, NULL, NULL, '2025-06-22 13:51:23', '143.109.74.193', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo', NULL),
(85, 21, NULL, NULL, '2025-06-21 13:51:23', '85.202.29.224', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Las Palmas', '28.12350000', '-15.43630000', NULL, 'España', 'Las Palmas', NULL),
(86, 20, NULL, NULL, '2025-07-02 13:51:23', '224.120.183.222', 'Mozilla/5.0 Test Browser', NULL, 'US', 'Nueva York', '40.71280000', '-74.00600000', NULL, 'Estados Unidos', 'Nueva York', NULL),
(87, 13, NULL, NULL, '2025-06-26 13:51:23', '128.48.126.44', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao', NULL),
(88, 21, NULL, NULL, '2025-06-24 13:51:23', '175.85.204.81', 'Mozilla/5.0 Test Browser', NULL, 'PT', 'Lisboa', '38.72230000', '-9.13930000', NULL, 'Portugal', 'Lisboa', NULL),
(89, 20, NULL, NULL, '2025-07-05 13:51:23', '133.244.145.206', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Murcia', '37.99220000', '-1.13070000', NULL, 'España', 'Murcia', NULL),
(90, 13, NULL, NULL, '2025-07-03 13:51:23', '127.2.172.36', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo', NULL),
(91, 20, NULL, NULL, '2025-06-22 13:51:23', '204.49.80.10', 'Mozilla/5.0 Test Browser', NULL, 'US', 'Nueva York', '40.71280000', '-74.00600000', NULL, 'Estados Unidos', 'Nueva York', NULL),
(92, 20, NULL, NULL, '2025-07-03 13:51:23', '82.193.221.112', 'Mozilla/5.0 Test Browser', NULL, 'MX', 'México DF', '19.43260000', '-99.13320000', NULL, 'México', 'México DF', NULL),
(93, 21, NULL, NULL, '2025-06-29 13:51:23', '3.198.70.128', 'Mozilla/5.0 Test Browser', NULL, 'PE', 'Lima', '-12.04640000', '-77.04280000', NULL, 'Perú', 'Lima', NULL),
(94, 21, NULL, NULL, '2025-07-07 13:51:23', '186.79.184.172', 'Mozilla/5.0 Test Browser', NULL, 'AR', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires', NULL),
(95, 13, NULL, NULL, '2025-06-28 13:51:23', '86.114.66.52', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Murcia', '37.99220000', '-1.13070000', NULL, 'España', 'Murcia', NULL),
(96, 13, NULL, NULL, '2025-06-19 13:51:23', '83.54.196.0', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Murcia', '37.99220000', '-1.13070000', NULL, 'España', 'Murcia', NULL),
(97, 20, NULL, NULL, '2025-07-04 13:51:23', '228.171.113.252', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao', NULL),
(98, 13, NULL, NULL, '2025-06-14 13:51:23', '198.241.84.207', 'Mozilla/5.0 Test Browser', NULL, 'IT', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma', NULL),
(99, 13, NULL, NULL, '2025-06-19 13:51:23', '153.173.38.18', 'Mozilla/5.0 Test Browser', NULL, 'IT', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma', NULL),
(100, 13, NULL, NULL, '2025-06-13 13:51:23', '133.150.86.182', 'Mozilla/5.0 Test Browser', NULL, 'MX', 'México DF', '19.43260000', '-99.13320000', NULL, 'México', 'México DF', NULL),
(101, 20, NULL, NULL, '2025-06-28 13:51:23', '36.100.152.72', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia', NULL),
(102, 21, NULL, NULL, '2025-07-04 13:51:23', '238.254.165.164', 'Mozilla/5.0 Test Browser', NULL, 'FR', 'París', '48.85660000', '2.35220000', NULL, 'Francia', 'París', NULL),
(103, 21, NULL, NULL, '2025-06-16 13:51:23', '132.54.151.205', 'Mozilla/5.0 Test Browser', NULL, 'MX', 'México DF', '19.43260000', '-99.13320000', NULL, 'México', 'México DF', NULL),
(104, 13, NULL, NULL, '2025-06-28 13:51:23', '9.177.22.198', 'Mozilla/5.0 Test Browser', NULL, 'PE', 'Lima', '-12.04640000', '-77.04280000', NULL, 'Perú', 'Lima', NULL),
(105, 13, NULL, NULL, '2025-06-24 13:51:23', '79.225.93.158', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao', NULL),
(106, 21, NULL, NULL, '2025-06-28 13:51:23', '115.30.201.126', 'Mozilla/5.0 Test Browser', NULL, 'MX', 'México DF', '19.43260000', '-99.13320000', NULL, 'México', 'México DF', NULL),
(107, 20, NULL, NULL, '2025-06-27 13:51:23', '48.234.119.143', 'Mozilla/5.0 Test Browser', NULL, 'PE', 'Lima', '-12.04640000', '-77.04280000', NULL, 'Perú', 'Lima', NULL),
(108, 21, NULL, NULL, '2025-06-13 13:51:23', '49.63.116.120', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia', NULL),
(109, 20, NULL, NULL, '2025-07-04 13:51:23', '157.90.4.16', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia', NULL),
(110, 13, NULL, NULL, '2025-07-01 13:51:23', '72.7.83.155', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo', NULL),
(111, 21, NULL, NULL, '2025-06-13 13:51:23', '82.161.113.97', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Zaragoza', '41.64880000', '-0.88910000', NULL, 'España', 'Zaragoza', NULL),
(112, 21, NULL, NULL, '2025-06-26 13:51:23', '82.4.108.172', 'Mozilla/5.0 Test Browser', NULL, 'IT', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma', NULL),
(113, 13, NULL, NULL, '2025-06-20 13:51:23', '14.115.104.240', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Madrid', '40.41680000', '-3.70380000', NULL, 'España', 'Madrid', NULL),
(114, 13, NULL, NULL, '2025-06-15 13:51:23', '86.151.82.240', 'Mozilla/5.0 Test Browser', NULL, 'PT', 'Lisboa', '38.72230000', '-9.13930000', NULL, 'Portugal', 'Lisboa', NULL),
(115, 21, NULL, NULL, '2025-06-21 13:58:11', '250.195.113.213', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona', NULL),
(116, 20, NULL, NULL, '2025-06-11 13:58:11', '21.146.11.153', 'Mozilla/5.0 Test Browser', NULL, 'FR', 'París', '48.85660000', '2.35220000', NULL, 'Francia', 'París', NULL),
(117, 20, NULL, NULL, '2025-06-13 13:58:11', '6.43.245.7', 'Mozilla/5.0 Test Browser', NULL, 'IT', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma', NULL),
(118, 13, NULL, NULL, '2025-06-25 13:58:11', '205.166.105.78', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Madrid', '40.41680000', '-3.70380000', NULL, 'España', 'Madrid', NULL),
(119, 20, NULL, NULL, '2025-06-17 13:58:11', '178.169.249.132', 'Mozilla/5.0 Test Browser', NULL, 'PT', 'Lisboa', '38.72230000', '-9.13930000', NULL, 'Portugal', 'Lisboa', NULL),
(120, 21, NULL, NULL, '2025-06-28 13:58:11', '224.216.215.201', 'Mozilla/5.0 Test Browser', NULL, 'PT', 'Lisboa', '38.72230000', '-9.13930000', NULL, 'Portugal', 'Lisboa', NULL),
(121, 21, NULL, NULL, '2025-06-23 13:58:11', '249.142.39.218', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona', NULL),
(122, 20, NULL, NULL, '2025-06-20 13:58:11', '121.93.174.161', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia', NULL),
(123, 20, NULL, NULL, '2025-06-23 13:58:11', '67.3.121.67', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Las Palmas', '28.12350000', '-15.43630000', NULL, 'España', 'Las Palmas', NULL),
(124, 21, NULL, NULL, '2025-06-18 13:58:11', '176.142.24.217', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Las Palmas', '28.12350000', '-15.43630000', NULL, 'España', 'Las Palmas', NULL),
(125, 13, NULL, NULL, '2025-06-10 13:58:11', '239.189.175.6', 'Mozilla/5.0 Test Browser', NULL, 'DE', 'Berlín', '52.52000000', '13.40500000', NULL, 'Alemania', 'Berlín', NULL),
(126, 13, NULL, NULL, '2025-06-17 13:58:11', '93.237.43.76', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Madrid', '40.41680000', '-3.70380000', NULL, 'España', 'Madrid', NULL),
(127, 21, NULL, NULL, '2025-06-15 13:58:11', '208.166.180.198', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Zaragoza', '41.64880000', '-0.88910000', NULL, 'España', 'Zaragoza', NULL),
(128, 20, NULL, NULL, '2025-06-16 13:58:11', '69.216.25.126', 'Mozilla/5.0 Test Browser', NULL, 'PE', 'Lima', '-12.04640000', '-77.04280000', NULL, 'Perú', 'Lima', NULL),
(129, 13, NULL, NULL, '2025-06-27 13:58:11', '31.228.161.234', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo', NULL),
(130, 21, NULL, NULL, '2025-06-17 13:58:11', '12.211.101.94', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Sevilla', '37.38910000', '-5.98450000', NULL, 'España', 'Sevilla', NULL),
(131, 20, NULL, NULL, '2025-06-27 13:58:11', '173.116.229.188', 'Mozilla/5.0 Test Browser', NULL, 'AR', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires', NULL),
(132, 21, NULL, NULL, '2025-06-12 13:58:11', '137.236.50.61', 'Mozilla/5.0 Test Browser', NULL, 'AR', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires', NULL),
(133, 21, NULL, NULL, '2025-07-03 13:58:11', '251.202.121.211', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma', NULL),
(134, 13, NULL, NULL, '2025-06-28 13:58:11', '118.118.111.241', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Sevilla', '37.38910000', '-5.98450000', NULL, 'España', 'Sevilla', NULL),
(135, 20, NULL, NULL, '2025-07-05 13:58:11', '55.225.34.253', 'Mozilla/5.0 Test Browser', NULL, 'FR', 'París', '48.85660000', '2.35220000', NULL, 'Francia', 'París', NULL),
(136, 13, NULL, NULL, '2025-06-18 13:58:11', '210.193.175.118', 'Mozilla/5.0 Test Browser', NULL, 'GB', 'Londres', '51.50740000', '-0.12780000', NULL, 'Reino Unido', 'Londres', NULL),
(137, 13, NULL, NULL, '2025-06-09 13:58:11', '87.101.94.59', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia', NULL),
(138, 21, NULL, NULL, '2025-06-13 13:58:11', '37.161.123.11', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Sevilla', '37.38910000', '-5.98450000', NULL, 'España', 'Sevilla', NULL),
(139, 13, NULL, NULL, '2025-06-26 13:58:11', '19.9.42.247', 'Mozilla/5.0 Test Browser', NULL, 'AR', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires', NULL),
(140, 20, NULL, NULL, '2025-06-22 13:58:11', '105.167.57.117', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Madrid', '40.41680000', '-3.70380000', NULL, 'España', 'Madrid', NULL),
(141, 13, NULL, NULL, '2025-06-25 13:58:11', '5.29.144.111', 'Mozilla/5.0 Test Browser', NULL, 'PT', 'Lisboa', '38.72230000', '-9.13930000', NULL, 'Portugal', 'Lisboa', NULL),
(142, 20, NULL, NULL, '2025-06-20 13:58:11', '126.23.88.180', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Madrid', '40.41680000', '-3.70380000', NULL, 'España', 'Madrid', NULL),
(143, 13, NULL, NULL, '2025-06-15 13:58:11', '92.166.74.12', 'Mozilla/5.0 Test Browser', NULL, 'GB', 'Londres', '51.50740000', '-0.12780000', NULL, 'Reino Unido', 'Londres', NULL),
(144, 21, NULL, NULL, '2025-07-05 13:58:11', '66.95.101.185', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia', NULL),
(145, 21, NULL, NULL, '2025-07-04 13:58:11', '115.38.8.31', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma', NULL),
(146, 20, NULL, NULL, '2025-06-23 13:58:11', '29.39.58.163', 'Mozilla/5.0 Test Browser', NULL, 'FR', 'París', '48.85660000', '2.35220000', NULL, 'Francia', 'París', NULL),
(147, 20, NULL, NULL, '2025-07-04 13:58:11', '125.136.99.65', 'Mozilla/5.0 Test Browser', NULL, 'IT', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma', NULL),
(148, 20, NULL, NULL, '2025-07-04 13:58:12', '48.96.44.158', 'Mozilla/5.0 Test Browser', NULL, 'AR', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires', NULL),
(149, 21, NULL, NULL, '2025-06-27 13:58:12', '49.186.129.121', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona', NULL),
(150, 21, NULL, NULL, '2025-06-27 13:58:12', '91.191.229.107', 'Mozilla/5.0 Test Browser', NULL, 'IT', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma', NULL),
(151, 20, NULL, NULL, '2025-06-12 13:58:12', '228.29.239.73', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia', NULL),
(152, 20, NULL, NULL, '2025-07-02 13:58:12', '65.85.49.161', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Sevilla', '37.38910000', '-5.98450000', NULL, 'España', 'Sevilla', NULL),
(153, 13, NULL, NULL, '2025-06-25 13:58:12', '122.126.237.95', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona', NULL),
(154, 21, NULL, NULL, '2025-06-21 13:58:12', '132.178.197.176', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Málaga', '36.72130000', '-4.42140000', NULL, 'España', 'Málaga', NULL),
(155, 13, NULL, NULL, '2025-06-21 13:58:12', '160.106.22.175', 'Mozilla/5.0 Test Browser', NULL, 'US', 'Nueva York', '40.71280000', '-74.00600000', NULL, 'Estados Unidos', 'Nueva York', NULL),
(156, 13, NULL, NULL, '2025-06-30 13:58:12', '152.126.66.208', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona', NULL),
(157, 21, NULL, NULL, '2025-06-20 13:58:12', '149.40.115.159', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Zaragoza', '41.64880000', '-0.88910000', NULL, 'España', 'Zaragoza', NULL),
(158, 13, NULL, NULL, '2025-07-02 13:58:12', '133.81.236.146', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona', NULL),
(159, 20, NULL, NULL, '2025-07-02 13:58:12', '120.132.110.178', 'Mozilla/5.0 Test Browser', NULL, 'AR', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires', NULL),
(160, 20, NULL, NULL, '2025-06-23 13:58:12', '105.43.144.248', 'Mozilla/5.0 Test Browser', NULL, 'US', 'Nueva York', '40.71280000', '-74.00600000', NULL, 'Estados Unidos', 'Nueva York', NULL),
(161, 13, NULL, NULL, '2025-06-09 13:58:12', '212.144.1.243', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Málaga', '36.72130000', '-4.42140000', NULL, 'España', 'Málaga', NULL),
(162, 20, NULL, NULL, '2025-06-29 13:58:12', '239.64.172.8', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Madrid', '40.41680000', '-3.70380000', NULL, 'España', 'Madrid', NULL),
(163, 13, NULL, NULL, '2025-06-18 13:58:12', '125.201.182.149', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Las Palmas', '28.12350000', '-15.43630000', NULL, 'España', 'Las Palmas', NULL),
(164, 21, NULL, NULL, '2025-06-25 13:58:12', '2.190.239.221', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Sevilla', '37.38910000', '-5.98450000', NULL, 'España', 'Sevilla', NULL),
(165, 21, NULL, NULL, '2025-07-09 15:15:32', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', '', 'ES', 'PV', '43.26540000', '-2.92650000', 'Europe/Madrid', 'Spain', 'Bilbao', NULL),
(166, 21, NULL, NULL, '2025-06-27 15:50:52', '241.115.190.243', 'Mozilla/5.0 Test Browser', NULL, 'AR', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires', NULL),
(167, 21, NULL, NULL, '2025-07-01 15:50:52', '255.61.209.120', 'Mozilla/5.0 Test Browser', NULL, 'IT', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma', NULL),
(168, 20, NULL, NULL, '2025-07-07 15:50:52', '233.19.232.197', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao', NULL),
(169, 21, NULL, NULL, '2025-06-20 15:50:52', '125.197.139.118', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Zaragoza', '41.64880000', '-0.88910000', NULL, 'España', 'Zaragoza', NULL),
(170, 21, NULL, NULL, '2025-06-12 15:50:52', '46.61.211.16', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma', NULL),
(171, 20, NULL, NULL, '2025-06-22 15:50:52', '147.199.5.187', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma', NULL),
(172, 21, NULL, NULL, '2025-07-05 15:50:52', '24.112.123.91', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao', NULL),
(173, 13, NULL, NULL, '2025-06-11 15:50:52', '111.203.29.114', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Las Palmas', '28.12350000', '-15.43630000', NULL, 'España', 'Las Palmas', NULL),
(174, 20, NULL, NULL, '2025-06-30 15:50:52', '44.82.46.203', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo', NULL),
(175, 21, NULL, NULL, '2025-06-18 15:50:52', '152.235.0.35', 'Mozilla/5.0 Test Browser', NULL, 'MX', 'México DF', '19.43260000', '-99.13320000', NULL, 'México', 'México DF', NULL),
(176, 13, NULL, NULL, '2025-06-22 15:50:52', '175.235.184.230', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Madrid', '40.41680000', '-3.70380000', NULL, 'España', 'Madrid', NULL),
(177, 21, NULL, NULL, '2025-06-15 15:50:52', '40.56.230.249', 'Mozilla/5.0 Test Browser', NULL, 'GB', 'Londres', '51.50740000', '-0.12780000', NULL, 'Reino Unido', 'Londres', NULL),
(178, 13, NULL, NULL, '2025-07-02 15:50:52', '71.41.244.92', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia', NULL),
(179, 20, NULL, NULL, '2025-06-17 15:50:52', '10.10.88.238', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia', NULL),
(180, 20, NULL, NULL, '2025-06-09 15:50:52', '58.52.1.254', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma', NULL),
(181, 21, NULL, NULL, '2025-06-16 15:50:52', '253.184.223.134', 'Mozilla/5.0 Test Browser', NULL, 'US', 'Nueva York', '40.71280000', '-74.00600000', NULL, 'Estados Unidos', 'Nueva York', NULL),
(182, 13, NULL, NULL, '2025-06-15 15:50:52', '25.20.247.179', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo', NULL),
(183, 21, NULL, NULL, '2025-06-16 15:50:52', '143.116.37.162', 'Mozilla/5.0 Test Browser', NULL, 'GB', 'Londres', '51.50740000', '-0.12780000', NULL, 'Reino Unido', 'Londres', NULL),
(184, 13, NULL, NULL, '2025-06-29 15:50:52', '138.88.101.205', 'Mozilla/5.0 Test Browser', NULL, 'GB', 'Londres', '51.50740000', '-0.12780000', NULL, 'Reino Unido', 'Londres', NULL),
(185, 20, NULL, NULL, '2025-06-24 15:50:52', '59.190.37.151', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Málaga', '36.72130000', '-4.42140000', NULL, 'España', 'Málaga', NULL),
(186, 13, NULL, NULL, '2025-06-26 15:50:52', '111.197.46.108', 'Mozilla/5.0 Test Browser', NULL, 'FR', 'París', '48.85660000', '2.35220000', NULL, 'Francia', 'París', NULL),
(187, 20, NULL, NULL, '2025-06-20 15:50:52', '235.203.201.35', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Murcia', '37.99220000', '-1.13070000', NULL, 'España', 'Murcia', NULL),
(188, 21, NULL, NULL, '2025-06-10 15:50:52', '174.153.62.49', 'Mozilla/5.0 Test Browser', NULL, 'MX', 'México DF', '19.43260000', '-99.13320000', NULL, 'México', 'México DF', NULL),
(189, 13, NULL, NULL, '2025-06-12 15:50:52', '181.235.82.15', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Sevilla', '37.38910000', '-5.98450000', NULL, 'España', 'Sevilla', NULL),
(190, 21, NULL, NULL, '2025-06-23 15:50:52', '121.20.156.73', 'Mozilla/5.0 Test Browser', NULL, 'IT', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma', NULL),
(191, 21, NULL, NULL, '2025-07-07 15:50:52', '174.173.14.162', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona', NULL),
(192, 13, NULL, NULL, '2025-06-18 15:50:52', '95.4.247.147', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Málaga', '36.72130000', '-4.42140000', NULL, 'España', 'Málaga', NULL),
(193, 20, NULL, NULL, '2025-07-01 15:50:53', '11.214.167.145', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Sevilla', '37.38910000', '-5.98450000', NULL, 'España', 'Sevilla', NULL),
(194, 21, NULL, NULL, '2025-07-01 15:50:53', '59.230.38.167', 'Mozilla/5.0 Test Browser', NULL, 'PE', 'Lima', '-12.04640000', '-77.04280000', NULL, 'Perú', 'Lima', NULL),
(195, 21, NULL, NULL, '2025-06-22 15:50:53', '223.204.61.43', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Murcia', '37.99220000', '-1.13070000', NULL, 'España', 'Murcia', NULL),
(196, 13, NULL, NULL, '2025-07-09 15:50:53', '179.203.94.16', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo', NULL),
(197, 21, NULL, NULL, '2025-06-30 15:50:53', '140.204.8.221', 'Mozilla/5.0 Test Browser', NULL, 'US', 'Nueva York', '40.71280000', '-74.00600000', NULL, 'Estados Unidos', 'Nueva York', NULL),
(198, 20, NULL, NULL, '2025-06-22 15:50:53', '109.56.28.33', 'Mozilla/5.0 Test Browser', NULL, 'AR', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires', NULL),
(199, 20, NULL, NULL, '2025-06-14 15:50:53', '132.154.183.221', 'Mozilla/5.0 Test Browser', NULL, 'MX', 'México DF', '19.43260000', '-99.13320000', NULL, 'México', 'México DF', NULL),
(200, 13, NULL, NULL, '2025-06-24 15:50:53', '97.217.9.91', 'Mozilla/5.0 Test Browser', NULL, 'FR', 'París', '48.85660000', '2.35220000', NULL, 'Francia', 'París', NULL),
(201, 13, NULL, NULL, '2025-06-09 15:50:53', '188.37.173.139', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo', NULL),
(202, 13, NULL, NULL, '2025-06-24 15:50:53', '255.191.218.77', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Sevilla', '37.38910000', '-5.98450000', NULL, 'España', 'Sevilla', NULL),
(203, 13, NULL, NULL, '2025-06-25 15:50:53', '247.217.152.214', 'Mozilla/5.0 Test Browser', NULL, 'AR', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires', NULL),
(204, 20, NULL, NULL, '2025-06-11 15:50:53', '63.113.27.74', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona', NULL),
(205, 20, NULL, NULL, '2025-07-04 15:50:53', '49.175.193.205', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao', NULL),
(206, 20, NULL, NULL, '2025-07-06 15:50:53', '133.91.40.64', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona', NULL),
(207, 21, NULL, NULL, '2025-07-09 15:50:53', '171.188.129.166', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Las Palmas', '28.12350000', '-15.43630000', NULL, 'España', 'Las Palmas', NULL),
(208, 21, NULL, NULL, '2025-06-17 15:50:53', '215.192.78.242', 'Mozilla/5.0 Test Browser', NULL, 'DE', 'Berlín', '52.52000000', '13.40500000', NULL, 'Alemania', 'Berlín', NULL),
(209, 20, NULL, NULL, '2025-06-19 15:50:53', '179.223.221.174', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo', NULL),
(210, 13, NULL, NULL, '2025-07-05 15:50:53', '202.243.77.16', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma', NULL),
(211, 20, NULL, NULL, '2025-06-20 15:50:53', '16.218.250.115', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma', NULL),
(212, 20, NULL, NULL, '2025-06-15 15:50:53', '134.124.52.231', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao', NULL),
(213, 20, NULL, NULL, '2025-07-08 15:50:53', '98.84.166.65', 'Mozilla/5.0 Test Browser', NULL, 'MX', 'México DF', '19.43260000', '-99.13320000', NULL, 'México', 'México DF', NULL),
(214, 13, NULL, NULL, '2025-06-14 15:50:53', '40.28.9.54', 'Mozilla/5.0 Test Browser', NULL, 'PT', 'Lisboa', '38.72230000', '-9.13930000', NULL, 'Portugal', 'Lisboa', NULL),
(215, 13, NULL, NULL, '2025-07-08 15:50:53', '113.208.22.190', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao', NULL),
(221, 22, NULL, NULL, '2025-06-27 08:36:30', '81.201.96.252', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao', NULL),
(222, 21, NULL, NULL, '2025-06-23 08:36:30', '85.218.71.61', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Madrid', '40.41680000', '-3.70380000', NULL, 'España', 'Madrid', NULL),
(223, 23, NULL, NULL, '2025-06-22 08:36:30', '67.106.57.142', 'Mozilla/5.0 Test Browser', NULL, 'FR', 'París', '48.85660000', '2.35220000', NULL, 'Francia', 'París', NULL),
(224, 13, NULL, NULL, '2025-06-30 08:36:30', '87.48.186.233', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Sevilla', '37.38910000', '-5.98450000', NULL, 'España', 'Sevilla', NULL),
(225, 21, NULL, NULL, '2025-06-15 08:36:30', '185.251.114.7', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Las Palmas', '28.12350000', '-15.43630000', NULL, 'España', 'Las Palmas', NULL),
(226, 22, NULL, NULL, '2025-07-03 08:36:30', '112.211.173.137', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Sevilla', '37.38910000', '-5.98450000', NULL, 'España', 'Sevilla', NULL),
(227, 21, NULL, NULL, '2025-06-19 08:36:30', '223.169.174.53', 'Mozilla/5.0 Test Browser', NULL, 'AR', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires', NULL),
(228, 24, NULL, NULL, '2025-06-15 08:36:30', '179.38.30.28', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo', NULL),
(229, 22, NULL, NULL, '2025-07-05 08:36:30', '157.6.105.199', 'Mozilla/5.0 Test Browser', NULL, 'AR', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires', NULL),
(230, 22, NULL, NULL, '2025-07-01 08:36:30', '133.177.105.173', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Sevilla', '37.38910000', '-5.98450000', NULL, 'España', 'Sevilla', NULL),
(231, 21, NULL, NULL, '2025-07-10 08:36:30', '32.87.152.138', 'Mozilla/5.0 Test Browser', NULL, 'US', 'Nueva York', '40.71280000', '-74.00600000', NULL, 'Estados Unidos', 'Nueva York', NULL),
(232, 23, NULL, NULL, '2025-07-05 08:36:30', '98.244.185.122', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma', NULL),
(233, 22, NULL, NULL, '2025-06-12 08:36:30', '14.151.205.21', 'Mozilla/5.0 Test Browser', NULL, 'IT', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma', NULL),
(234, 13, NULL, NULL, '2025-07-05 08:36:30', '112.176.63.209', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Las Palmas', '28.12350000', '-15.43630000', NULL, 'España', 'Las Palmas', NULL),
(235, 20, NULL, NULL, '2025-07-10 08:36:31', '51.156.21.115', 'Mozilla/5.0 Test Browser', NULL, 'GB', 'Londres', '51.50740000', '-0.12780000', NULL, 'Reino Unido', 'Londres', NULL),
(236, 23, NULL, NULL, '2025-06-21 08:36:31', '58.29.164.4', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Málaga', '36.72130000', '-4.42140000', NULL, 'España', 'Málaga', NULL),
(237, 13, NULL, NULL, '2025-07-06 08:36:31', '71.249.39.193', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao', NULL),
(238, 13, NULL, NULL, '2025-06-14 08:36:31', '213.232.191.136', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Las Palmas', '28.12350000', '-15.43630000', NULL, 'España', 'Las Palmas', NULL),
(239, 24, NULL, NULL, '2025-07-10 08:36:31', '176.72.170.181', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona', NULL),
(240, 20, NULL, NULL, '2025-06-29 08:36:31', '182.147.160.241', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia', NULL),
(241, 13, NULL, NULL, '2025-06-14 08:36:31', '32.111.202.21', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Madrid', '40.41680000', '-3.70380000', NULL, 'España', 'Madrid', NULL),
(242, 13, NULL, NULL, '2025-06-30 08:36:31', '241.14.128.47', 'Mozilla/5.0 Test Browser', NULL, 'AR', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires', NULL),
(243, 13, NULL, NULL, '2025-07-09 08:36:31', '107.180.177.213', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Sevilla', '37.38910000', '-5.98450000', NULL, 'España', 'Sevilla', NULL),
(244, 25, NULL, NULL, '2025-07-03 08:36:31', '254.76.112.68', 'Mozilla/5.0 Test Browser', NULL, 'DE', 'Berlín', '52.52000000', '13.40500000', NULL, 'Alemania', 'Berlín', NULL),
(245, 24, NULL, NULL, '2025-07-08 08:36:31', '42.187.33.248', 'Mozilla/5.0 Test Browser', NULL, 'FR', 'París', '48.85660000', '2.35220000', NULL, 'Francia', 'París', NULL),
(246, 22, NULL, NULL, '2025-06-19 08:36:31', '218.115.179.51', 'Mozilla/5.0 Test Browser', NULL, 'PE', 'Lima', '-12.04640000', '-77.04280000', NULL, 'Perú', 'Lima', NULL),
(247, 22, NULL, NULL, '2025-07-02 08:36:31', '25.113.11.117', 'Mozilla/5.0 Test Browser', NULL, 'PT', 'Lisboa', '38.72230000', '-9.13930000', NULL, 'Portugal', 'Lisboa', NULL),
(248, 20, NULL, NULL, '2025-06-29 08:36:31', '167.153.244.2', 'Mozilla/5.0 Test Browser', NULL, 'MX', 'México DF', '19.43260000', '-99.13320000', NULL, 'México', 'México DF', NULL),
(249, 20, NULL, NULL, '2025-06-11 08:36:31', '159.119.212.57', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia', NULL),
(250, 23, NULL, NULL, '2025-06-17 08:36:31', '19.225.138.86', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Zaragoza', '41.64880000', '-0.88910000', NULL, 'España', 'Zaragoza', NULL),
(251, 25, NULL, NULL, '2025-07-09 08:36:31', '47.28.38.24', 'Mozilla/5.0 Test Browser', NULL, 'MX', 'México DF', '19.43260000', '-99.13320000', NULL, 'México', 'México DF', NULL),
(252, 24, NULL, NULL, '2025-06-16 08:36:31', '233.58.95.243', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo', NULL),
(253, 21, NULL, NULL, '2025-07-09 08:36:31', '80.229.163.227', 'Mozilla/5.0 Test Browser', NULL, 'PE', 'Lima', '-12.04640000', '-77.04280000', NULL, 'Perú', 'Lima', NULL),
(254, 22, NULL, NULL, '2025-06-15 08:36:31', '72.210.37.99', 'Mozilla/5.0 Test Browser', NULL, 'AR', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires', NULL),
(255, 25, NULL, NULL, '2025-07-08 08:36:31', '154.244.74.227', 'Mozilla/5.0 Test Browser', NULL, 'IT', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma', NULL),
(256, 24, NULL, NULL, '2025-06-16 08:36:31', '206.44.76.245', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona', NULL),
(257, 20, NULL, NULL, '2025-06-14 08:36:31', '10.148.27.69', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao', NULL),
(258, 21, NULL, NULL, '2025-06-12 08:36:31', '139.7.234.19', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma', NULL),
(259, 20, NULL, NULL, '2025-07-08 08:36:31', '153.100.61.183', 'Mozilla/5.0 Test Browser', NULL, 'AR', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires', NULL),
(260, 20, NULL, NULL, '2025-06-23 08:36:31', '45.198.20.235', 'Mozilla/5.0 Test Browser', NULL, 'US', 'Nueva York', '40.71280000', '-74.00600000', NULL, 'Estados Unidos', 'Nueva York', NULL),
(261, 23, NULL, NULL, '2025-06-18 08:36:31', '67.61.185.186', 'Mozilla/5.0 Test Browser', NULL, 'DE', 'Berlín', '52.52000000', '13.40500000', NULL, 'Alemania', 'Berlín', NULL),
(262, 13, NULL, NULL, '2025-07-09 08:36:31', '14.38.110.223', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia', NULL),
(263, 21, NULL, NULL, '2025-06-12 08:36:31', '96.237.186.138', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao', NULL),
(264, 25, NULL, NULL, '2025-06-22 08:36:31', '212.20.98.159', 'Mozilla/5.0 Test Browser', NULL, 'FR', 'París', '48.85660000', '2.35220000', NULL, 'Francia', 'París', NULL),
(265, 23, NULL, NULL, '2025-07-02 08:36:31', '229.100.101.51', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia', NULL),
(266, 13, NULL, NULL, '2025-06-25 08:36:31', '68.139.155.189', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma', NULL),
(267, 20, NULL, NULL, '2025-06-15 08:36:31', '19.251.73.72', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Murcia', '37.99220000', '-1.13070000', NULL, 'España', 'Murcia', NULL),
(268, 24, NULL, NULL, '2025-06-20 08:36:31', '139.62.117.252', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Sevilla', '37.38910000', '-5.98450000', NULL, 'España', 'Sevilla', NULL),
(269, 25, NULL, NULL, '2025-06-14 08:36:31', '122.5.193.63', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Málaga', '36.72130000', '-4.42140000', NULL, 'España', 'Málaga', NULL),
(270, 21, NULL, NULL, '2025-07-01 08:36:31', '186.146.166.100', 'Mozilla/5.0 Test Browser', NULL, 'PE', 'Lima', '-12.04640000', '-77.04280000', NULL, 'Perú', 'Lima', NULL),
(271, 20, NULL, NULL, '2025-07-11 08:39:23', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(272, 25, NULL, NULL, '2025-07-11 08:58:44', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(273, 24, NULL, NULL, '2025-07-11 09:03:41', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(274, 21, NULL, NULL, '2025-07-11 12:03:05', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(277, 13, NULL, NULL, '2025-07-11 14:13:04', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(278, 29, NULL, NULL, '2025-07-11 15:18:46', '62.99.100.233', 'WhatsApp/2.23.20.0', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(279, 29, NULL, NULL, '2025-07-11 15:19:28', '92.191.45.226', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/28.0 Chrome/130.0.0.0 Mobile Safari/537.36', NULL, NULL, NULL, '43.26300000', '-2.93510000', NULL, 'Spain', 'Bilbao', NULL),
(280, 29, NULL, NULL, '2025-07-11 15:19:32', '92.191.45.226', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/28.0 Chrome/130.0.0.0 Mobile Safari/537.36', NULL, NULL, NULL, '43.26300000', '-2.93510000', NULL, 'Spain', 'Bilbao', NULL),
(281, 29, NULL, NULL, '2025-07-11 15:19:48', '92.191.45.226', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36', NULL, NULL, NULL, '43.26300000', '-2.93510000', NULL, 'Spain', 'Bilbao', NULL),
(282, 29, NULL, NULL, '2025-07-11 15:20:09', '92.191.45.226', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36', NULL, NULL, NULL, '43.26300000', '-2.93510000', NULL, 'Spain', 'Bilbao', NULL),
(283, 29, NULL, NULL, '2025-07-11 15:20:38', '92.191.45.226', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/28.0 Chrome/130.0.0.0 Mobile Safari/537.36', NULL, NULL, NULL, '43.26300000', '-2.93510000', NULL, 'Spain', 'Bilbao', NULL),
(284, 29, NULL, NULL, '2025-07-11 15:21:30', '92.191.45.226', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/28.0 Chrome/130.0.0.0 Mobile Safari/537.36', NULL, NULL, NULL, '43.26300000', '-2.93510000', NULL, 'Spain', 'Bilbao', NULL),
(285, 30, NULL, NULL, '2025-07-11 18:58:59', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(286, 34, NULL, NULL, '2025-07-11 19:20:01', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(287, 35, NULL, NULL, '2025-07-11 19:32:21', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(288, 35, NULL, NULL, '2025-07-11 19:59:25', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(289, 30, NULL, NULL, '2025-07-11 20:12:39', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(290, 30, NULL, NULL, '2025-07-11 20:12:50', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(291, 13, NULL, NULL, '2025-07-11 20:56:58', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(292, 36, NULL, NULL, '2025-07-11 21:08:35', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(293, 36, NULL, NULL, '2025-07-11 23:16:17', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(294, 35, NULL, NULL, '2025-07-11 23:16:24', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(295, 34, NULL, NULL, '2025-07-11 23:16:34', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO `click_stats` (`id`, `url_id`, `user_id`, `session_id`, `clicked_at`, `ip_address`, `user_agent`, `referer`, `country_code`, `region`, `latitude`, `longitude`, `timezone`, `country`, `city`, `accessed_domain`) VALUES
(296, 30, NULL, NULL, '2025-07-11 23:16:43', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(297, 29, NULL, NULL, '2025-07-11 23:16:54', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(298, 35, NULL, NULL, '2025-07-11 23:26:32', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(299, 29, NULL, NULL, '2025-07-12 09:26:46', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(300, 36, NULL, NULL, '2025-07-12 09:57:01', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(301, 35, NULL, NULL, '2025-07-12 09:57:08', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(302, 34, NULL, NULL, '2025-07-12 09:57:16', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(303, 30, NULL, NULL, '2025-07-12 09:57:23', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(304, 29, NULL, NULL, '2025-07-12 09:57:30', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(305, 29, NULL, NULL, '2025-07-12 09:58:45', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(306, 36, NULL, NULL, '2025-07-12 10:25:52', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(307, 29, NULL, NULL, '2025-07-12 10:33:28', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(308, 29, NULL, NULL, '2025-07-12 10:35:14', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(309, 29, NULL, NULL, '2025-07-12 10:35:58', '199.16.157.181', 'Twitterbot/1.0', NULL, NULL, NULL, '33.76970000', '-84.37540000', NULL, 'United States', 'Atlanta', NULL),
(310, 29, NULL, NULL, '2025-07-12 10:35:59', '199.16.157.182', 'Twitterbot/1.0', NULL, NULL, NULL, '33.76970000', '-84.37540000', NULL, 'United States', 'Atlanta', NULL),
(311, 29, NULL, NULL, '2025-07-12 10:35:59', '199.16.157.181', 'Twitterbot/1.0', NULL, NULL, NULL, '33.76970000', '-84.37540000', NULL, 'United States', 'Atlanta', NULL),
(312, 29, NULL, NULL, '2025-07-12 10:36:05', '54.85.32.163', 'help@dataminr.com', NULL, NULL, NULL, '39.04380000', '-77.48740000', NULL, 'United States', 'Ashburn', NULL),
(313, 29, NULL, NULL, '2025-07-12 10:36:43', '144.76.22.168', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; trendictionbot0.5.0; trendiction search; http://www.trendiction.de/bot; please let us know of any problems; web at trendiction.com) Gecko/20100101 Firefox/125.0', NULL, NULL, NULL, '50.47770000', '12.36490000', NULL, 'Germany', 'Falkenstein', NULL),
(314, 37, NULL, NULL, '2025-07-12 12:34:27', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(315, 37, NULL, NULL, '2025-07-12 12:35:55', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(316, 37, NULL, NULL, '2025-07-12 12:37:46', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(317, 37, NULL, NULL, '2025-07-12 12:43:20', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(320, 37, NULL, NULL, '2025-07-12 13:06:38', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(321, 36, NULL, NULL, '2025-07-12 14:15:50', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(322, 23, NULL, NULL, '2025-07-12 14:25:01', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(323, 37, NULL, NULL, '2025-07-12 16:21:20', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(324, 40, NULL, NULL, '2025-07-12 17:01:16', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(325, 37, NULL, NULL, '2025-07-12 17:55:33', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(326, 41, NULL, NULL, '2025-07-12 18:29:41', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(327, 30, NULL, NULL, '2025-07-13 00:45:07', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(328, 30, NULL, NULL, '2025-07-13 02:22:43', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(329, 30, NULL, NULL, '2025-07-13 03:37:13', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(330, 44, NULL, NULL, '2025-07-13 04:45:05', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(331, 30, NULL, NULL, '2025-07-13 05:32:47', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(332, 45, NULL, NULL, '2025-07-13 07:04:36', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(350, 47, NULL, NULL, '2025-07-13 08:34:42', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(351, 47, NULL, NULL, '2025-07-13 08:35:00', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(352, 47, NULL, NULL, '2025-07-13 08:37:46', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(353, 47, NULL, NULL, '2025-07-13 08:38:23', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(354, 48, NULL, NULL, '2025-07-13 08:50:39', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(355, 48, NULL, NULL, '2025-07-13 08:59:01', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(356, 50, NULL, NULL, '2025-07-13 08:59:48', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(357, 51, NULL, NULL, '2025-07-13 09:10:36', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(358, 52, NULL, NULL, '2025-07-13 09:11:23', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(359, 13, NULL, NULL, '2025-07-13 09:21:51', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', 'https://0ln.org/test_domain.php', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(360, 13, NULL, NULL, '2025-07-13 09:22:02', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', 'https://0ln.org/test_domain.php', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(361, 13, NULL, NULL, '2025-07-13 09:30:19', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(362, 53, NULL, NULL, '2025-07-13 09:56:02', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(363, 55, NULL, NULL, '2025-07-13 09:57:21', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(364, 55, NULL, NULL, '2025-07-13 10:00:19', '20.171.207.124', 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; GPTBot/1.2; +https://openai.com/gptbot)', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(365, 54, NULL, NULL, '2025-07-13 10:00:19', '20.171.207.30', 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; GPTBot/1.2; +https://openai.com/gptbot)', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(366, 53, NULL, NULL, '2025-07-13 10:00:21', '20.171.207.30', 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; GPTBot/1.2; +https://openai.com/gptbot)', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(367, 52, NULL, NULL, '2025-07-13 10:00:23', '20.171.207.124', 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; GPTBot/1.2; +https://openai.com/gptbot)', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(368, 51, NULL, NULL, '2025-07-13 10:00:25', '20.171.207.124', 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; GPTBot/1.2; +https://openai.com/gptbot)', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(369, 53, NULL, NULL, '2025-07-13 10:36:56', '43.153.113.127', 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(370, 52, NULL, NULL, '2025-07-13 10:37:38', '43.166.247.155', 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(371, 54, NULL, NULL, '2025-07-13 10:46:15', '150.109.230.210', 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(372, 55, NULL, NULL, '2025-07-13 10:48:35', '43.166.246.180', 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(373, 51, NULL, NULL, '2025-07-13 10:56:07', '43.156.202.34', 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(374, 56, NULL, NULL, '2025-07-13 11:39:21', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', 'https://0ln.eu/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(375, 57, NULL, NULL, '2025-07-13 11:39:46', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', 'https://0ln.eu/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(376, 57, NULL, NULL, '2025-07-13 11:40:39', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(377, 56, NULL, NULL, '2025-07-13 12:15:10', '43.157.156.190', 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(378, 57, NULL, NULL, '2025-07-13 12:26:22', '43.131.36.84', 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(379, 34, NULL, NULL, '2025-07-13 12:27:05', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(380, 47, NULL, NULL, '2025-07-13 12:28:36', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(381, 58, NULL, NULL, '2025-07-13 12:32:04', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', 'https://0ln.org/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(382, 59, NULL, NULL, '2025-07-13 13:20:36', '43.153.192.98', 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(383, 60, NULL, NULL, '2025-07-13 13:26:50', '43.157.170.126', 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(384, 58, NULL, NULL, '2025-07-13 13:46:16', '129.226.93.214', 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(385, 61, NULL, NULL, '2025-07-13 14:13:27', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(387, 61, NULL, NULL, '2025-07-13 16:23:59', '199.16.157.180', 'Twitterbot/1.0', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(388, 61, NULL, NULL, '2025-07-13 16:37:30', '145.239.83.37', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0 Safari/537.36', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(389, 66, NULL, NULL, '2025-07-13 16:47:08', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(390, 66, NULL, NULL, '2025-07-13 17:09:44', '43.130.16.212', 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(391, 65, NULL, NULL, '2025-07-13 17:09:46', '43.153.96.79', 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(392, 61, NULL, NULL, '2025-07-13 17:28:44', '43.133.220.37', 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(393, 66, NULL, NULL, '2025-07-13 19:35:31', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(394, 68, NULL, NULL, '2025-07-13 20:46:04', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(395, 68, NULL, NULL, '2025-07-13 20:46:16', '199.16.157.180', 'Twitterbot/1.0', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(396, 68, NULL, NULL, '2025-07-13 20:46:18', '199.16.157.180', 'Twitterbot/1.0', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(397, 68, NULL, NULL, '2025-07-13 20:46:19', '199.16.157.183', 'Twitterbot/1.0', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(398, 68, NULL, NULL, '2025-07-13 20:46:19', '199.16.157.182', 'Twitterbot/1.0', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(399, 68, NULL, NULL, '2025-07-13 20:46:32', '192.133.77.15', 'Twitterbot/1.0', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(400, 68, NULL, NULL, '2025-07-13 20:46:40', '192.99.232.216', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36', 'https://t.co/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(401, 61, NULL, NULL, '2025-07-13 20:46:50', '34.127.44.40', '', 'https://t.co/1G5fl6OCfz', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(402, 68, NULL, NULL, '2025-07-13 20:46:50', '34.127.44.40', '', 'https://t.co/fhDm1r0En0', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(403, 68, NULL, NULL, '2025-07-13 20:46:56', '144.76.23.228', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; trendictionbot0.5.0; trendiction search; http://www.trendiction.de/bot; please let us know of any problems; web at trendiction.com) Gecko/20100101 Firefox/125.0', 'http://0ln.eu/3CdrZH', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(404, 68, NULL, NULL, '2025-07-13 21:27:51', '85.61.127.142', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/28.0 Chrome/130.0.0.0 Mobile Safari/537.36', 'https://t.co/fhDm1r0En0', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(405, 68, NULL, NULL, '2025-07-14 00:15:13', '43.166.129.247', 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1', 'http://0ln.eu/3CdrZH', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(406, 65, NULL, NULL, '2025-07-14 00:23:08', '43.159.128.247', 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1', 'http://0ln.eu/u6hcLr', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(407, 66, NULL, NULL, '2025-07-14 10:34:56', '5.196.160.191', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Vivaldi/5.3.2679.68', 'http://0ln.org', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(408, 68, NULL, NULL, '2025-07-14 11:03:50', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', 'https://t.co/fhDm1r0En0', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(409, 66, NULL, NULL, '2025-07-14 12:37:14', '171.236.47.163', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Vivaldi/5.3.2679.68', 'http://0ln.org', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(410, 66, NULL, NULL, '2025-07-14 12:46:12', '5.196.160.191', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Vivaldi/5.3.2679.68', 'http://0ln.org', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(418, 78, NULL, NULL, '2025-07-14 18:44:20', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', 'https://0ln.eu/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(419, 78, NULL, NULL, '2025-07-14 18:45:36', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', 'https://0ln.eu/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `config`
--

CREATE TABLE `config` (
  `id` int NOT NULL,
  `config_key` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `config_value` text COLLATE utf8mb4_unicode_ci,
  `description` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `config`
--

INSERT INTO `config` (`id`, `config_key`, `config_value`, `description`, `created_at`, `updated_at`) VALUES
(1, 'site_name', 'Acortador de URLs', 'Nombre del sitio', '2025-07-08 16:49:59', '2025-07-08 16:49:59'),
(2, 'site_description', 'Acorta URLs de forma rápida y segura', 'Descripción', '2025-07-08 16:49:59', '2025-07-08 16:49:59'),
(3, 'max_urls_per_ip', '100', 'URLs máximas por IP', '2025-07-08 16:49:59', '2025-07-08 16:49:59'),
(4, 'enable_custom_codes', '1', 'Códigos personalizados', '2025-07-08 16:49:59', '2025-07-08 16:49:59'),
(5, 'enable_stats', '1', 'Estadísticas públicas', '2025-07-08 16:49:59', '2025-07-08 16:49:59'),
(6, 'version', '1.0', 'Versión del sistema', '2025-07-08 16:49:59', '2025-07-08 16:49:59');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `custom_domains`
--

CREATE TABLE `custom_domains` (
  `id` int NOT NULL,
  `user_id` int DEFAULT NULL,
  `domain` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('pending','active','inactive') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `verification_token` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `verified_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `ssl_enabled` tinyint(1) DEFAULT '0',
  `verification_method` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `custom_domains`
--

INSERT INTO `custom_domains` (`id`, `user_id`, `domain`, `status`, `verification_token`, `verified_at`, `created_at`, `updated_at`, `ssl_enabled`, `verification_method`) VALUES
(14, NULL, '0ln.org', 'active', '72eb9bcb1a1d37844fb550e6bde11c4b16fbcc4ce9dcbda504a6ae678404218c', '2025-07-12 23:21:37', '2025-07-12 23:20:01', '2025-07-14 16:10:57', 0, 'dns_txt'),
(15, NULL, 'short.tudominio.com', 'active', NULL, NULL, '2025-07-13 08:56:59', '2025-07-13 08:56:59', 0, NULL),
(16, NULL, 'link.tudominio.com', 'active', NULL, NULL, '2025-07-13 08:56:59', '2025-07-13 08:56:59', 0, NULL),
(25, 14, 'clancy.es', 'active', NULL, NULL, '2025-07-14 16:11:20', '2025-07-14 16:11:20', 0, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rate_limit`
--

CREATE TABLE `rate_limit` (
  `id` int NOT NULL,
  `identifier` varchar(100) NOT NULL,
  `action` varchar(50) DEFAULT 'general',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `security_logs`
--

CREATE TABLE `security_logs` (
  `id` bigint NOT NULL,
  `event_type` varchar(50) NOT NULL,
  `severity` enum('info','warning','error','critical') DEFAULT 'info',
  `details` json DEFAULT NULL,
  `user_id` int DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sessions`
--

CREATE TABLE `sessions` (
  `id` varchar(128) NOT NULL,
  `user_id` int DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text,
  `payload` text NOT NULL,
  `last_activity` int NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `settings`
--

CREATE TABLE `settings` (
  `key` varchar(100) NOT NULL,
  `value` text,
  `type` enum('string','integer','boolean','json') DEFAULT 'string',
  `description` text,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `settings`
--

INSERT INTO `settings` (`key`, `value`, `type`, `description`, `updated_at`) VALUES
('allow_registration', '1', 'boolean', 'Permitir registro de nuevos usuarios', '2025-07-13 18:00:22'),
('analytics_retention_days', '365', 'integer', 'Días de retención de estadísticas', '2025-07-13 18:00:22'),
('blocked_domains', '[]', 'json', 'Lista de dominios bloqueados', '2025-07-13 18:00:22'),
('default_url_expiry_days', '0', 'integer', 'Días de expiración por defecto (0 = sin expiración)', '2025-07-13 18:00:22'),
('enable_2fa', '1', 'boolean', 'Habilitar autenticación de dos factores', '2025-07-13 18:00:22'),
('maintenance_mode', '0', 'boolean', 'Modo de mantenimiento', '2025-07-13 18:00:22'),
('max_urls_per_user', '0', 'integer', 'Máximo de URLs por usuario (0 = ilimitado)', '2025-07-13 18:00:22'),
('require_email_verification', '1', 'boolean', 'Requerir verificación de email', '2025-07-13 18:00:22'),
('reserved_codes', '[\"admin\",\"api\",\"login\",\"register\",\"dashboard\",\"stats\",\"qr\"]', 'json', 'Códigos reservados', '2025-07-13 18:00:22');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `system_settings`
--

CREATE TABLE `system_settings` (
  `id` int NOT NULL,
  `setting_key` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `setting_value` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `setting_type` enum('string','integer','boolean','json') COLLATE utf8mb4_unicode_ci DEFAULT 'string',
  `description` text COLLATE utf8mb4_unicode_ci,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `updated_by` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `system_settings`
--

INSERT INTO `system_settings` (`id`, `setting_key`, `setting_value`, `setting_type`, `description`, `updated_at`, `updated_by`) VALUES
(1, 'max_urls_per_user', '100', 'integer', 'Máximo número de URLs por usuario', '2025-07-09 20:22:44', NULL),
(2, 'allow_registration', 'true', 'boolean', 'Permitir registro de nuevos usuarios', '2025-07-09 20:22:44', NULL),
(3, 'require_email_verification', 'false', 'boolean', 'Requerir verificación de email', '2025-07-09 20:22:44', NULL),
(4, 'max_failed_login_attempts', '5', 'integer', 'Máximo intentos de login fallidos', '2025-07-09 20:22:44', NULL),
(5, 'account_lockout_duration', '1800', 'integer', 'Duración de bloqueo de cuenta en segundos', '2025-07-09 20:22:44', NULL),
(6, 'session_lifetime', '86400', 'integer', 'Duración de sesión en segundos (24 horas)', '2025-07-09 20:22:44', NULL),
(7, 'password_min_length', '8', 'integer', 'Longitud mínima de contraseña', '2025-07-09 20:22:44', NULL),
(8, 'site_name', 'URL Shortener', 'string', 'Nombre del sitio', '2025-07-09 20:22:44', NULL),
(9, 'admin_email', 'admin@localhost', 'string', 'Email del administrador', '2025-07-09 20:22:44', NULL),
(10, 'enable_geolocation', 'true', 'boolean', 'Habilitar geolocalización', '2025-07-09 20:22:44', NULL),
(11, 'allow_custom_codes', 'true', 'boolean', 'Permitir códigos personalizados', '2025-07-09 20:22:44', NULL),
(12, 'max_custom_code_length', '20', 'integer', 'Longitud máxima de códigos personalizados', '2025-07-09 20:22:44', NULL),
(13, 'enable_url_expiration', 'true', 'boolean', 'Permitir URLs con expiración', '2025-07-09 20:22:44', NULL),
(14, 'default_url_expiration_days', '365', 'integer', 'Días por defecto para expiración de URLs', '2025-07-09 20:22:44', NULL),
(15, 'enable_url_analytics', 'true', 'boolean', 'Habilitar analíticas detalladas', '2025-07-09 20:22:44', NULL),
(16, 'maintenance_mode', 'false', 'boolean', 'Modo mantenimiento', '2025-07-09 20:22:44', NULL),
(17, 'maintenance_message', 'Sitio en mantenimiento', 'string', 'Mensaje de mantenimiento', '2025-07-09 20:22:44', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `urls`
--

CREATE TABLE `urls` (
  `id` int NOT NULL,
  `user_id` int DEFAULT NULL,
  `domain_id` int DEFAULT NULL,
  `short_code` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `original_url` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `clicks` int DEFAULT '0',
  `last_click` timestamp NULL DEFAULT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci,
  `active` tinyint(1) DEFAULT '1',
  `is_public` tinyint(1) DEFAULT '1',
  `title` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `urls`
--

INSERT INTO `urls` (`id`, `user_id`, `domain_id`, `short_code`, `original_url`, `created_at`, `clicks`, `last_click`, `ip_address`, `user_agent`, `active`, `is_public`, `title`, `description`) VALUES
(13, NULL, NULL, 'test123', 'https://www.google.com', '2025-07-09 06:44:52', 81, NULL, '127.0.0.1', NULL, 1, 1, NULL, NULL),
(20, NULL, NULL, '160orw', 'https://abc.es', '2025-07-09 13:23:29', 73, '2025-07-09 13:23:51', '62.99.100.233', NULL, 1, 1, NULL, NULL),
(21, NULL, NULL, 'nGpCr0', 'https://youtube.com', '2025-07-09 13:31:19', 74, '2025-07-09 15:15:32', '62.99.100.233', NULL, 1, 1, NULL, NULL),
(22, NULL, NULL, 'vop545', 'https://google.es', '2025-07-10 16:00:28', 8, NULL, NULL, NULL, 1, 1, NULL, NULL),
(23, NULL, NULL, 'X9k7IN', 'https://adunti.net', '2025-07-10 20:41:22', 7, NULL, NULL, NULL, 1, 1, NULL, NULL),
(24, NULL, NULL, 'uHwUTE', 'https://proton.me', '2025-07-10 20:43:34', 7, NULL, NULL, NULL, 1, 1, NULL, NULL),
(25, NULL, NULL, 'hoQdJs', 'https://biblioteca.store', '2025-07-10 20:54:54', 6, NULL, NULL, NULL, 1, 1, NULL, NULL),
(29, 1, NULL, 'guZSnU', 'https://www.elespanol.com/espana/politica/20250711/feijoo-no-critica-cronica-sanchez-admita-prostitucion-vino-bien-patrimonial/1003743843638_0.html', '2025-07-11 15:18:14', 18, NULL, NULL, NULL, 1, 1, NULL, NULL),
(30, 1, NULL, 'A3wBd6', 'https://adunti.net', '2025-07-11 15:35:36', 9, NULL, NULL, NULL, 1, 1, NULL, NULL),
(34, 1, NULL, '1yVssT', 'https://adunti.org/biblioteca', '2025-07-11 19:03:20', 4, NULL, NULL, NULL, 1, 1, NULL, NULL),
(35, 1, NULL, '5iY9DD', 'https://adunti.net/biblioteca', '2025-07-11 19:28:02', 5, NULL, NULL, NULL, 1, 1, NULL, NULL),
(36, 1, NULL, 'aGCvU7', 'https://amazon.com', '2025-07-11 20:56:14', 5, NULL, NULL, NULL, 1, 1, NULL, NULL),
(37, 1, NULL, 'yCvdMr', 'https://www.elespanol.com/espana/politica/20250712/pp-reprocha-sanchez-pacte-vertedero-moral-bildu-lleva-asesinos-listas-dirige-secuestrador/1003743845104_0.html', '2025-07-12 12:34:22', 7, NULL, NULL, NULL, 1, 1, NULL, NULL),
(40, 13, NULL, 'yhfdTJ', 'https://amzn.to/3R2pzir', '2025-07-12 17:00:46', 1, NULL, NULL, NULL, 1, 1, NULL, NULL),
(41, 13, NULL, 'kvB1gX', 'https://adunti.net', '2025-07-12 18:29:26', 1, NULL, NULL, NULL, 1, 1, NULL, NULL),
(42, 13, NULL, '6dhxRG', 'https://adunti.org/biblioteca', '2025-07-12 21:19:12', 0, NULL, NULL, NULL, 1, 1, NULL, NULL),
(43, 1, NULL, 'gxSn1V', 'https://www.google.fr', '2025-07-12 22:05:46', 0, NULL, NULL, NULL, 1, 1, NULL, NULL),
(44, 1, 14, 'rE2JMu', 'https://hola.es', '2025-07-13 03:39:37', 1, NULL, NULL, NULL, 1, 1, NULL, NULL),
(45, 1, NULL, '7Mmc3X', 'https://hola.es', '2025-07-13 07:03:52', 1, NULL, NULL, NULL, 1, 1, NULL, NULL),
(46, 1, 14, 'ool8LN', 'https://adunti.net', '2025-07-13 08:21:39', 0, NULL, NULL, NULL, 1, 1, NULL, NULL),
(47, 1, 14, 'g7AHKg', 'https://adunti.org/biblioteca', '2025-07-13 08:34:25', 1, NULL, NULL, NULL, 1, 1, NULL, NULL),
(48, 1, 14, 'zRkhFR', 'https://amzn.to/3R2pzir', '2025-07-13 08:50:27', 0, NULL, NULL, NULL, 1, 1, NULL, NULL),
(49, 1, 14, 'ZZUj2G', 'https://amzn.to/3R2pzir', '2025-07-13 08:58:45', 0, NULL, NULL, NULL, 1, 1, NULL, NULL),
(50, 1, 14, 'md4CYW', 'https://amzn.to/3R2pzir', '2025-07-13 08:59:22', 0, NULL, NULL, NULL, 1, 1, NULL, NULL),
(51, 1, 14, 'IezPkI', 'https://amzn.to/3R2pzir', '2025-07-13 09:10:01', 2, NULL, NULL, NULL, 1, 1, NULL, NULL),
(52, 1, 14, 'CgsEuL', 'https://adunti.net/biblioteca', '2025-07-13 09:11:06', 2, NULL, NULL, NULL, 1, 1, NULL, NULL),
(53, 1, 0, '2Dtjhy', 'https://adunti.net', '2025-07-13 09:36:36', 3, NULL, NULL, NULL, 1, 1, NULL, NULL),
(54, 1, 0, 'lpBDcU', 'https://adunti.net', '2025-07-13 09:56:47', 2, NULL, NULL, NULL, 1, 1, NULL, NULL),
(55, 1, 14, 'fdeSit', 'https://adunti.net', '2025-07-13 09:57:09', 3, NULL, NULL, NULL, 1, 1, NULL, NULL),
(56, 1, 14, '8zaHZF', 'https://adunti.net', '2025-07-13 11:39:16', 2, NULL, NULL, NULL, 1, 1, NULL, NULL),
(57, 1, 14, 'vosNy7', 'https://adunti.net', '2025-07-13 11:39:43', 3, NULL, NULL, NULL, 1, 1, NULL, NULL),
(58, 1, 0, 'EVYDFU', 'https://adunti.net', '2025-07-13 12:32:02', 2, NULL, NULL, NULL, 1, 1, NULL, NULL),
(59, 1, 14, 'KnIyVp', 'https://adunti.net', '2025-07-13 12:42:57', 1, NULL, NULL, NULL, 1, 1, NULL, NULL),
(60, 1, 14, 'liL38N', 'https://adunti.org/biblioteca', '2025-07-13 12:47:55', 1, NULL, NULL, NULL, 1, 1, NULL, NULL),
(61, 1, 0, 'WOTLK', 'https://mega.nz/file/xqcxybJB#VLjNK5cSqfD0j-PmCeSha6YYay86tXJuO4HtEaqdJ84', '2025-07-13 14:13:12', 5, NULL, NULL, NULL, 1, 1, NULL, NULL),
(64, 1, 0, 'nextcloud', 'http://0ln.eu/nextcloud', '2025-07-13 15:31:29', 0, NULL, NULL, NULL, 1, 1, NULL, NULL),
(65, 1, 0, 'u6hcLr', 'https://adunti.net', '2025-07-13 16:43:57', 2, NULL, NULL, NULL, 1, 1, NULL, NULL),
(66, 1, 14, 'Va6G9N', 'https://adunti.net', '2025-07-13 16:46:54', 6, NULL, NULL, NULL, 1, 1, NULL, NULL),
(67, 1, 16, 'b82sAz', 'https://hola.es', '2025-07-13 20:10:00', 0, NULL, NULL, NULL, 1, 1, NULL, NULL),
(68, 1, 0, '3CdrZH', 'https://x.com/ROSAMARI_5/status/1944496601868943834', '2025-07-13 20:45:32', 12, NULL, NULL, NULL, 1, 1, NULL, NULL),
(78, 14, 25, 'jQ9HXL', 'https://hola.es', '2025-07-14 18:44:12', 2, NULL, NULL, NULL, 1, 1, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `users`
--

CREATE TABLE `users` (
  `id` int NOT NULL,
  `username` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `full_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('active','banned','pending') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `role` enum('user','admin') COLLATE utf8mb4_unicode_ci DEFAULT 'user',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `last_login` timestamp NULL DEFAULT NULL,
  `email_verified` tinyint(1) DEFAULT '0',
  `verification_token` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `password_reset_token` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `password_reset_expires` timestamp NULL DEFAULT NULL,
  `banned_reason` text COLLATE utf8mb4_unicode_ci,
  `banned_at` timestamp NULL DEFAULT NULL,
  `banned_by` int DEFAULT NULL,
  `failed_login_attempts` int DEFAULT '0',
  `locked_until` timestamp NULL DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `users`
--

INSERT INTO `users` (`id`, `username`, `email`, `password`, `full_name`, `status`, `role`, `created_at`, `updated_at`, `last_login`, `email_verified`, `verification_token`, `password_reset_token`, `password_reset_expires`, `banned_reason`, `banned_at`, `banned_by`, `failed_login_attempts`, `locked_until`, `is_active`) VALUES
(1, 'admin', 'admin@localhost', '$2y$12$N4bcRGiENYKgWCNgs993LuFV8RCEiuUsMfe.hXq1upgqwxLRUSrmm', 'Administrador', 'active', 'admin', '2025-07-09 20:22:44', '2025-07-14 18:17:54', '2025-07-14 18:17:54', 1, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, 1),
(11, 'capitan', 'b@a.net', '$2y$12$pdzYpwYF/L8z7dSXiPvRQu6akfe4cmCfyVqNacFZGJiDl14496Hj6', '', 'active', 'user', '2025-07-12 12:45:21', '2025-07-14 16:50:25', '2025-07-14 16:50:25', 0, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, 1),
(12, 'Chino', 'chino@china.org', '$2y$12$oOLzbxiw22kZJ8hkVJxS9.lrEA1mLcQq7DyvN3dqZ0/Qa5FedgHUG', '', 'active', 'user', '2025-07-12 13:22:13', '2025-07-14 16:49:22', '2025-07-14 16:49:22', 0, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, 1),
(13, 'Antonio', 'budino@antonio.org', '$2y$12$JhsrPDK3gAIzt0kDV9523esjTotHnay7sPBmhQRnRUybR.oBrjcg6', '', 'active', 'admin', '2025-07-12 16:55:32', '2025-07-14 18:23:40', '2025-07-14 18:23:40', 0, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, 1),
(14, 'ana', 'anuska@0ln.org', '$2y$12$Nd1./mZl4ppKv75WPMIRbeGq33hMu75lgbuBYd9wan9H9RDf3cLCe', '', 'active', 'user', '2025-07-14 14:45:16', '2025-07-14 18:29:00', '2025-07-14 18:29:00', 0, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `user_activity`
--

CREATE TABLE `user_activity` (
  `id` int NOT NULL,
  `user_id` int DEFAULT NULL,
  `action_type` enum('login','logout','register','url_create','url_click','password_change','profile_update','ban','unban') COLLATE utf8mb4_unicode_ci NOT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci,
  `details` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `user_audit_log`
--

CREATE TABLE `user_audit_log` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `action` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `old_value` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `new_value` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `changed_by` int NOT NULL,
  `changed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `user_audit_log`
--

INSERT INTO `user_audit_log` (`id`, `user_id`, `action`, `old_value`, `new_value`, `changed_by`, `changed_at`, `ip_address`, `user_agent`) VALUES
(1, 13, 'role_change', 'admin', 'user', 1, '2025-07-12 17:36:40', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36'),
(2, 13, 'role_change', 'user', 'admin', 1, '2025-07-12 17:36:52', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36'),
(3, 13, 'role_change', 'admin', 'admin', 1, '2025-07-12 17:49:29', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36'),
(4, 13, 'status_change', 'active', 'banned', 13, '2025-07-12 17:52:51', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36'),
(5, 13, 'status_change', 'banned', 'active', 13, '2025-07-12 17:53:01', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36'),
(6, 13, 'status_change', 'active', 'banned', 13, '2025-07-12 17:53:29', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36'),
(7, 13, 'status_change', 'banned', 'active', 13, '2025-07-12 17:53:33', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36'),
(8, 12, 'status_change', 'active', 'banned', 1, '2025-07-13 14:29:31', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36'),
(9, 12, 'status_change', 'banned', 'active', 1, '2025-07-13 14:29:39', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36'),
(10, 1, 'password_changed', NULL, NULL, 13, '2025-07-13 20:28:25', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36'),
(11, 1, 'status_change', 'active', 'banned', 13, '2025-07-13 20:28:39', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36'),
(12, 1, 'status_change', 'banned', 'active', 13, '2025-07-13 20:28:42', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36'),
(13, 14, 'user_created', NULL, 'ana', 1, '2025-07-14 14:45:16', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `user_sessions`
--

CREATE TABLE `user_sessions` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `session_token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` timestamp NOT NULL,
  `is_active` tinyint(1) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `user_stats`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `user_stats` (
`active_users` bigint
,`admin_users` bigint
,`banned_users` bigint
,`logins_today` bigint
,`pending_users` bigint
,`registrations_today` bigint
,`total_users` bigint
);

-- --------------------------------------------------------

--
-- Estructura para la vista `user_stats`
--
DROP TABLE IF EXISTS `user_stats`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `user_stats`  AS SELECT count(0) AS `total_users`, count((case when (`users`.`status` = 'active') then 1 end)) AS `active_users`, count((case when (`users`.`status` = 'banned') then 1 end)) AS `banned_users`, count((case when (`users`.`status` = 'pending') then 1 end)) AS `pending_users`, count((case when (`users`.`role` = 'admin') then 1 end)) AS `admin_users`, count((case when (cast(`users`.`created_at` as date) = curdate()) then 1 end)) AS `registrations_today`, count((case when (cast(`users`.`last_login` as date) = curdate()) then 1 end)) AS `logins_today` FROM `users` ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `admin_sessions`
--
ALTER TABLE `admin_sessions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `session_id` (`session_id`),
  ADD KEY `idx_session_id` (`session_id`);

--
-- Indices de la tabla `api_keys`
--
ALTER TABLE `api_keys`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `key_hash` (`key_hash`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `expires_at` (`expires_at`);

--
-- Indices de la tabla `click_stats`
--
ALTER TABLE `click_stats`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_url_id` (`url_id`),
  ADD KEY `idx_country_code` (`country_code`),
  ADD KEY `idx_country` (`country`),
  ADD KEY `idx_city` (`city`),
  ADD KEY `idx_click_stats_user_id` (`user_id`),
  ADD KEY `idx_click_stats_url_date` (`url_id`,`clicked_at`);

--
-- Indices de la tabla `config`
--
ALTER TABLE `config`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `config_key` (`config_key`),
  ADD KEY `idx_config_key` (`config_key`);

--
-- Indices de la tabla `custom_domains`
--
ALTER TABLE `custom_domains`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `domain` (`domain`),
  ADD KEY `idx_domain` (`domain`),
  ADD KEY `idx_user_id` (`user_id`);

--
-- Indices de la tabla `rate_limit`
--
ALTER TABLE `rate_limit`
  ADD PRIMARY KEY (`id`),
  ADD KEY `identifier_action_created` (`identifier`,`action`,`created_at`),
  ADD KEY `idx_rate_limit_cleanup` (`created_at`);

--
-- Indices de la tabla `security_logs`
--
ALTER TABLE `security_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `event_type` (`event_type`),
  ADD KEY `severity` (`severity`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `created_at` (`created_at`),
  ADD KEY `ip_address` (`ip_address`),
  ADD KEY `idx_security_logs_cleanup` (`created_at`);

--
-- Indices de la tabla `sessions`
--
ALTER TABLE `sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `last_activity` (`last_activity`);

--
-- Indices de la tabla `settings`
--
ALTER TABLE `settings`
  ADD PRIMARY KEY (`key`);

--
-- Indices de la tabla `system_settings`
--
ALTER TABLE `system_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `setting_key` (`setting_key`),
  ADD KEY `idx_setting_key` (`setting_key`);

--
-- Indices de la tabla `urls`
--
ALTER TABLE `urls`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `short_code` (`short_code`),
  ADD KEY `idx_short_code` (`short_code`),
  ADD KEY `idx_urls_user_status` (`user_id`,`active`),
  ADD KEY `idx_domain_id` (`domain_id`),
  ADD KEY `idx_urls_short_code_active` (`short_code`,`active`);

--
-- Indices de la tabla `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `idx_username` (`username`),
  ADD KEY `idx_email` (`email`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_created_at` (`created_at`),
  ADD KEY `idx_verification_token` (`verification_token`),
  ADD KEY `idx_password_reset_token` (`password_reset_token`),
  ADD KEY `idx_users_status_role` (`status`,`role`);

--
-- Indices de la tabla `user_activity`
--
ALTER TABLE `user_activity`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_action_type` (`action_type`),
  ADD KEY `idx_created_at` (`created_at`),
  ADD KEY `idx_ip_address` (`ip_address`),
  ADD KEY `idx_user_activity_user_date` (`user_id`,`created_at`);

--
-- Indices de la tabla `user_audit_log`
--
ALTER TABLE `user_audit_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_changed_by` (`changed_by`),
  ADD KEY `idx_changed_at` (`changed_at`);

--
-- Indices de la tabla `user_sessions`
--
ALTER TABLE `user_sessions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `session_token` (`session_token`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_session_token` (`session_token`),
  ADD KEY `idx_expires_at` (`expires_at`),
  ADD KEY `idx_is_active` (`is_active`),
  ADD KEY `idx_user_sessions_user_active` (`user_id`,`is_active`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `admin_sessions`
--
ALTER TABLE `admin_sessions`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `api_keys`
--
ALTER TABLE `api_keys`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `click_stats`
--
ALTER TABLE `click_stats`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=420;

--
-- AUTO_INCREMENT de la tabla `config`
--
ALTER TABLE `config`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `custom_domains`
--
ALTER TABLE `custom_domains`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT de la tabla `rate_limit`
--
ALTER TABLE `rate_limit`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `security_logs`
--
ALTER TABLE `security_logs`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `system_settings`
--
ALTER TABLE `system_settings`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=239;

--
-- AUTO_INCREMENT de la tabla `urls`
--
ALTER TABLE `urls`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=79;

--
-- AUTO_INCREMENT de la tabla `users`
--
ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT de la tabla `user_activity`
--
ALTER TABLE `user_activity`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `user_audit_log`
--
ALTER TABLE `user_audit_log`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT de la tabla `user_sessions`
--
ALTER TABLE `user_sessions`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `api_keys`
--
ALTER TABLE `api_keys`
  ADD CONSTRAINT `api_keys_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `click_stats`
--
ALTER TABLE `click_stats`
  ADD CONSTRAINT `click_stats_ibfk_1` FOREIGN KEY (`url_id`) REFERENCES `urls` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_click_stats_url_id` FOREIGN KEY (`url_id`) REFERENCES `urls` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_click_stats_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Filtros para la tabla `custom_domains`
--
ALTER TABLE `custom_domains`
  ADD CONSTRAINT `custom_domains_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `urls`
--
ALTER TABLE `urls`
  ADD CONSTRAINT `fk_urls_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_urls_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Filtros para la tabla `user_activity`
--
ALTER TABLE `user_activity`
  ADD CONSTRAINT `fk_user_activity_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Filtros para la tabla `user_audit_log`
--
ALTER TABLE `user_audit_log`
  ADD CONSTRAINT `user_audit_log_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_audit_log_ibfk_2` FOREIGN KEY (`changed_by`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `user_sessions`
--
ALTER TABLE `user_sessions`
  ADD CONSTRAINT `fk_user_sessions_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

DELIMITER $$
--
-- Eventos
--
CREATE DEFINER=`root`@`localhost` EVENT `cleanup_expired_sessions` ON SCHEDULE EVERY 1 HOUR STARTS '2025-07-09 20:20:17' ON COMPLETION NOT PRESERVE ENABLE DO DELETE FROM user_sessions WHERE expires_at < NOW() OR is_active = 0$$

CREATE DEFINER=`root`@`localhost` EVENT `cleanup_old_activity` ON SCHEDULE EVERY 1 DAY STARTS '2025-07-09 20:20:17' ON COMPLETION NOT PRESERVE ENABLE DO DELETE FROM user_activity WHERE created_at < DATE_SUB(NOW(), INTERVAL 90 DAY)$$

CREATE DEFINER=`root`@`localhost` EVENT `daily_cleanup` ON SCHEDULE EVERY 1 DAY STARTS '2025-07-14 03:00:00' ON COMPLETION NOT PRESERVE ENABLE DO CALL cleanup_old_data()$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
