-- phpMyAdmin SQL Dump
-- version 5.1.1deb5ubuntu1
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost
-- Tiempo de generación: 10-07-2025 a las 19:57:05
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
  `city` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `click_stats`
--

INSERT INTO `click_stats` (`id`, `url_id`, `user_id`, `session_id`, `clicked_at`, `ip_address`, `user_agent`, `referer`, `country_code`, `region`, `latitude`, `longitude`, `timezone`, `country`, `city`) VALUES
(17, 20, NULL, NULL, '2025-07-09 13:23:51', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:128.0) Gecko/20100101 Firefox/128.0', '', 'ES', 'PV', '43.26540000', '-2.92650000', 'Europe/Madrid', 'Spain', 'Bilbao'),
(18, 13, NULL, NULL, '2025-07-06 13:36:24', '247.127.215.26', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Las Palmas', '28.12350000', '-15.43630000', NULL, 'España', 'Las Palmas'),
(19, 20, NULL, NULL, '2025-07-01 13:36:24', '225.31.223.215', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Zaragoza', '41.64880000', '-0.88910000', NULL, 'España', 'Zaragoza'),
(20, 21, NULL, NULL, '2025-07-08 13:36:24', '190.177.57.36', 'Mozilla/5.0 Test Browser', NULL, 'Po', 'Lisboa', '38.72230000', '-9.13930000', NULL, 'Portugal', 'Lisboa'),
(21, 20, NULL, NULL, '2025-06-29 13:36:42', '131.18.165.71', 'Mozilla/5.0 Test Browser', NULL, 'It', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma'),
(22, 13, NULL, NULL, '2025-06-23 13:36:42', '255.249.89.197', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao'),
(23, 20, NULL, NULL, '2025-06-20 13:36:42', '131.98.28.133', 'Mozilla/5.0 Test Browser', NULL, 'Re', 'Londres', '51.50740000', '-0.12780000', NULL, 'Reino Unido', 'Londres'),
(24, 13, NULL, NULL, '2025-06-20 13:36:42', '146.7.124.59', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Las Palmas', '28.12350000', '-15.43630000', NULL, 'España', 'Las Palmas'),
(25, 20, NULL, NULL, '2025-07-04 13:36:42', '151.1.37.148', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia'),
(26, 21, NULL, NULL, '2025-07-08 13:36:42', '221.10.17.233', 'Mozilla/5.0 Test Browser', NULL, 'Fr', 'París', '48.85660000', '2.35220000', NULL, 'Francia', 'París'),
(27, 20, NULL, NULL, '2025-06-20 13:36:42', '208.40.90.186', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia'),
(28, 13, NULL, NULL, '2025-07-07 13:36:42', '191.3.0.148', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona'),
(29, 20, NULL, NULL, '2025-06-25 13:36:42', '21.49.87.92', 'Mozilla/5.0 Test Browser', NULL, 'Al', 'Berlín', '52.52000000', '13.40500000', NULL, 'Alemania', 'Berlín'),
(30, 13, NULL, NULL, '2025-07-06 13:36:42', '39.113.69.106', 'Mozilla/5.0 Test Browser', NULL, 'Po', 'Lisboa', '38.72230000', '-9.13930000', NULL, 'Portugal', 'Lisboa'),
(31, 21, NULL, NULL, '2025-07-06 13:36:42', '158.202.148.229', 'Mozilla/5.0 Test Browser', NULL, 'Po', 'Lisboa', '38.72230000', '-9.13930000', NULL, 'Portugal', 'Lisboa'),
(32, 21, NULL, NULL, '2025-07-03 13:36:42', '237.228.23.24', 'Mozilla/5.0 Test Browser', NULL, 'Po', 'Lisboa', '38.72230000', '-9.13930000', NULL, 'Portugal', 'Lisboa'),
(33, 13, NULL, NULL, '2025-06-18 13:36:42', '250.43.85.19', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Madrid', '40.41680000', '-3.70380000', NULL, 'España', 'Madrid'),
(34, 21, NULL, NULL, '2025-06-11 13:36:42', '253.61.63.146', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Málaga', '36.72130000', '-4.42140000', NULL, 'España', 'Málaga'),
(35, 13, NULL, NULL, '2025-06-21 13:36:42', '29.197.18.140', 'Mozilla/5.0 Test Browser', NULL, 'It', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma'),
(36, 21, NULL, NULL, '2025-07-05 13:36:42', '107.161.117.9', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Zaragoza', '41.64880000', '-0.88910000', NULL, 'España', 'Zaragoza'),
(37, 20, NULL, NULL, '2025-06-12 13:36:42', '209.154.57.46', 'Mozilla/5.0 Test Browser', NULL, 'Pe', 'Lima', '-12.04640000', '-77.04280000', NULL, 'Perú', 'Lima'),
(38, 21, NULL, NULL, '2025-07-08 13:36:42', '186.169.136.186', 'Mozilla/5.0 Test Browser', NULL, 'It', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma'),
(39, 13, NULL, NULL, '2025-06-22 13:36:42', '9.183.10.71', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia'),
(40, 13, NULL, NULL, '2025-06-19 13:36:42', '216.94.59.71', 'Mozilla/5.0 Test Browser', NULL, 'Br', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo'),
(41, 13, NULL, NULL, '2025-06-20 13:36:42', '244.55.155.39', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao'),
(42, 21, NULL, NULL, '2025-07-05 13:36:42', '27.27.66.57', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao'),
(43, 20, NULL, NULL, '2025-06-14 13:36:42', '153.170.91.63', 'Mozilla/5.0 Test Browser', NULL, 'Br', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo'),
(44, 20, NULL, NULL, '2025-06-17 13:36:42', '89.110.87.126', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma'),
(45, 21, NULL, NULL, '2025-07-05 13:36:42', '229.20.187.150', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona'),
(46, 20, NULL, NULL, '2025-06-24 13:36:42', '157.112.165.238', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Málaga', '36.72130000', '-4.42140000', NULL, 'España', 'Málaga'),
(47, 21, NULL, NULL, '2025-07-04 13:36:42', '11.8.189.149', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Málaga', '36.72130000', '-4.42140000', NULL, 'España', 'Málaga'),
(48, 13, NULL, NULL, '2025-07-02 13:36:42', '246.97.28.100', 'Mozilla/5.0 Test Browser', NULL, 'Re', 'Londres', '51.50740000', '-0.12780000', NULL, 'Reino Unido', 'Londres'),
(49, 13, NULL, NULL, '2025-06-18 13:36:42', '139.94.168.246', 'Mozilla/5.0 Test Browser', NULL, 'Ar', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires'),
(50, 13, NULL, NULL, '2025-06-14 13:36:42', '145.130.44.161', 'Mozilla/5.0 Test Browser', NULL, 'Ar', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires'),
(51, 13, NULL, NULL, '2025-07-09 13:36:42', '96.96.98.20', 'Mozilla/5.0 Test Browser', NULL, 'Al', 'Berlín', '52.52000000', '13.40500000', NULL, 'Alemania', 'Berlín'),
(52, 13, NULL, NULL, '2025-06-22 13:36:42', '154.18.17.150', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Zaragoza', '41.64880000', '-0.88910000', NULL, 'España', 'Zaragoza'),
(53, 21, NULL, NULL, '2025-06-14 13:36:42', '146.191.211.166', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Nueva York', '40.71280000', '-74.00600000', NULL, 'Estados Unidos', 'Nueva York'),
(54, 20, NULL, NULL, '2025-06-25 13:36:42', '60.97.176.78', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Málaga', '36.72130000', '-4.42140000', NULL, 'España', 'Málaga'),
(55, 21, NULL, NULL, '2025-06-12 13:36:42', '228.132.7.47', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Zaragoza', '41.64880000', '-0.88910000', NULL, 'España', 'Zaragoza'),
(56, 21, NULL, NULL, '2025-06-09 13:36:42', '84.120.125.179', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao'),
(57, 13, NULL, NULL, '2025-06-29 13:36:42', '33.239.164.72', 'Mozilla/5.0 Test Browser', NULL, 'Ar', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires'),
(58, 21, NULL, NULL, '2025-06-20 13:36:42', '86.206.186.189', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia'),
(59, 13, NULL, NULL, '2025-07-05 13:36:42', '170.191.118.66', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Nueva York', '40.71280000', '-74.00600000', NULL, 'Estados Unidos', 'Nueva York'),
(60, 13, NULL, NULL, '2025-06-17 13:36:42', '4.222.47.115', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma'),
(61, 13, NULL, NULL, '2025-06-28 13:36:42', '224.10.114.91', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Las Palmas', '28.12350000', '-15.43630000', NULL, 'España', 'Las Palmas'),
(62, 21, NULL, NULL, '2025-06-23 13:36:42', '92.191.58.122', 'Mozilla/5.0 Test Browser', NULL, 'Br', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo'),
(63, 20, NULL, NULL, '2025-06-19 13:36:42', '221.238.148.229', 'Mozilla/5.0 Test Browser', NULL, 'Es', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma'),
(64, 13, NULL, NULL, '2025-06-17 13:36:42', '202.147.142.101', 'Mozilla/5.0 Test Browser', NULL, 'Al', 'Berlín', '52.52000000', '13.40500000', NULL, 'Alemania', 'Berlín'),
(65, 21, NULL, NULL, '2025-06-28 13:51:22', '192.66.93.203', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo'),
(66, 21, NULL, NULL, '2025-06-11 13:51:22', '244.52.42.200', 'Mozilla/5.0 Test Browser', NULL, 'GB', 'Londres', '51.50740000', '-0.12780000', NULL, 'Reino Unido', 'Londres'),
(67, 21, NULL, NULL, '2025-06-22 13:51:22', '234.55.23.78', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Madrid', '40.41680000', '-3.70380000', NULL, 'España', 'Madrid'),
(68, 20, NULL, NULL, '2025-07-05 13:51:22', '172.232.234.164', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Murcia', '37.99220000', '-1.13070000', NULL, 'España', 'Murcia'),
(69, 13, NULL, NULL, '2025-06-14 13:51:22', '36.230.92.182', 'Mozilla/5.0 Test Browser', NULL, 'FR', 'París', '48.85660000', '2.35220000', NULL, 'Francia', 'París'),
(70, 20, NULL, NULL, '2025-06-13 13:51:22', '16.60.5.75', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao'),
(71, 20, NULL, NULL, '2025-06-15 13:51:22', '84.144.33.79', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo'),
(72, 13, NULL, NULL, '2025-06-29 13:51:22', '14.85.66.37', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona'),
(73, 20, NULL, NULL, '2025-06-28 13:51:22', '23.83.127.97', 'Mozilla/5.0 Test Browser', NULL, 'GB', 'Londres', '51.50740000', '-0.12780000', NULL, 'Reino Unido', 'Londres'),
(74, 20, NULL, NULL, '2025-06-17 13:51:22', '32.8.168.198', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Málaga', '36.72130000', '-4.42140000', NULL, 'España', 'Málaga'),
(75, 13, NULL, NULL, '2025-06-19 13:51:22', '18.150.163.98', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma'),
(76, 20, NULL, NULL, '2025-07-08 13:51:22', '45.102.172.109', 'Mozilla/5.0 Test Browser', NULL, 'IT', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma'),
(77, 20, NULL, NULL, '2025-07-02 13:51:22', '239.24.131.133', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Las Palmas', '28.12350000', '-15.43630000', NULL, 'España', 'Las Palmas'),
(78, 21, NULL, NULL, '2025-07-07 13:51:23', '190.232.54.127', 'Mozilla/5.0 Test Browser', NULL, 'FR', 'París', '48.85660000', '2.35220000', NULL, 'Francia', 'París'),
(79, 21, NULL, NULL, '2025-06-20 13:51:23', '95.164.183.134', 'Mozilla/5.0 Test Browser', NULL, 'FR', 'París', '48.85660000', '2.35220000', NULL, 'Francia', 'París'),
(80, 13, NULL, NULL, '2025-06-10 13:51:23', '232.40.250.218', 'Mozilla/5.0 Test Browser', NULL, 'DE', 'Berlín', '52.52000000', '13.40500000', NULL, 'Alemania', 'Berlín'),
(81, 13, NULL, NULL, '2025-06-10 13:51:23', '115.21.119.168', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Sevilla', '37.38910000', '-5.98450000', NULL, 'España', 'Sevilla'),
(82, 21, NULL, NULL, '2025-06-13 13:51:23', '130.244.228.188', 'Mozilla/5.0 Test Browser', NULL, 'MX', 'México DF', '19.43260000', '-99.13320000', NULL, 'México', 'México DF'),
(83, 20, NULL, NULL, '2025-06-26 13:51:23', '222.119.3.120', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona'),
(84, 13, NULL, NULL, '2025-06-22 13:51:23', '143.109.74.193', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo'),
(85, 21, NULL, NULL, '2025-06-21 13:51:23', '85.202.29.224', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Las Palmas', '28.12350000', '-15.43630000', NULL, 'España', 'Las Palmas'),
(86, 20, NULL, NULL, '2025-07-02 13:51:23', '224.120.183.222', 'Mozilla/5.0 Test Browser', NULL, 'US', 'Nueva York', '40.71280000', '-74.00600000', NULL, 'Estados Unidos', 'Nueva York'),
(87, 13, NULL, NULL, '2025-06-26 13:51:23', '128.48.126.44', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao'),
(88, 21, NULL, NULL, '2025-06-24 13:51:23', '175.85.204.81', 'Mozilla/5.0 Test Browser', NULL, 'PT', 'Lisboa', '38.72230000', '-9.13930000', NULL, 'Portugal', 'Lisboa'),
(89, 20, NULL, NULL, '2025-07-05 13:51:23', '133.244.145.206', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Murcia', '37.99220000', '-1.13070000', NULL, 'España', 'Murcia'),
(90, 13, NULL, NULL, '2025-07-03 13:51:23', '127.2.172.36', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo'),
(91, 20, NULL, NULL, '2025-06-22 13:51:23', '204.49.80.10', 'Mozilla/5.0 Test Browser', NULL, 'US', 'Nueva York', '40.71280000', '-74.00600000', NULL, 'Estados Unidos', 'Nueva York'),
(92, 20, NULL, NULL, '2025-07-03 13:51:23', '82.193.221.112', 'Mozilla/5.0 Test Browser', NULL, 'MX', 'México DF', '19.43260000', '-99.13320000', NULL, 'México', 'México DF'),
(93, 21, NULL, NULL, '2025-06-29 13:51:23', '3.198.70.128', 'Mozilla/5.0 Test Browser', NULL, 'PE', 'Lima', '-12.04640000', '-77.04280000', NULL, 'Perú', 'Lima'),
(94, 21, NULL, NULL, '2025-07-07 13:51:23', '186.79.184.172', 'Mozilla/5.0 Test Browser', NULL, 'AR', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires'),
(95, 13, NULL, NULL, '2025-06-28 13:51:23', '86.114.66.52', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Murcia', '37.99220000', '-1.13070000', NULL, 'España', 'Murcia'),
(96, 13, NULL, NULL, '2025-06-19 13:51:23', '83.54.196.0', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Murcia', '37.99220000', '-1.13070000', NULL, 'España', 'Murcia'),
(97, 20, NULL, NULL, '2025-07-04 13:51:23', '228.171.113.252', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao'),
(98, 13, NULL, NULL, '2025-06-14 13:51:23', '198.241.84.207', 'Mozilla/5.0 Test Browser', NULL, 'IT', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma'),
(99, 13, NULL, NULL, '2025-06-19 13:51:23', '153.173.38.18', 'Mozilla/5.0 Test Browser', NULL, 'IT', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma'),
(100, 13, NULL, NULL, '2025-06-13 13:51:23', '133.150.86.182', 'Mozilla/5.0 Test Browser', NULL, 'MX', 'México DF', '19.43260000', '-99.13320000', NULL, 'México', 'México DF'),
(101, 20, NULL, NULL, '2025-06-28 13:51:23', '36.100.152.72', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia'),
(102, 21, NULL, NULL, '2025-07-04 13:51:23', '238.254.165.164', 'Mozilla/5.0 Test Browser', NULL, 'FR', 'París', '48.85660000', '2.35220000', NULL, 'Francia', 'París'),
(103, 21, NULL, NULL, '2025-06-16 13:51:23', '132.54.151.205', 'Mozilla/5.0 Test Browser', NULL, 'MX', 'México DF', '19.43260000', '-99.13320000', NULL, 'México', 'México DF'),
(104, 13, NULL, NULL, '2025-06-28 13:51:23', '9.177.22.198', 'Mozilla/5.0 Test Browser', NULL, 'PE', 'Lima', '-12.04640000', '-77.04280000', NULL, 'Perú', 'Lima'),
(105, 13, NULL, NULL, '2025-06-24 13:51:23', '79.225.93.158', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao'),
(106, 21, NULL, NULL, '2025-06-28 13:51:23', '115.30.201.126', 'Mozilla/5.0 Test Browser', NULL, 'MX', 'México DF', '19.43260000', '-99.13320000', NULL, 'México', 'México DF'),
(107, 20, NULL, NULL, '2025-06-27 13:51:23', '48.234.119.143', 'Mozilla/5.0 Test Browser', NULL, 'PE', 'Lima', '-12.04640000', '-77.04280000', NULL, 'Perú', 'Lima'),
(108, 21, NULL, NULL, '2025-06-13 13:51:23', '49.63.116.120', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia'),
(109, 20, NULL, NULL, '2025-07-04 13:51:23', '157.90.4.16', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia'),
(110, 13, NULL, NULL, '2025-07-01 13:51:23', '72.7.83.155', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo'),
(111, 21, NULL, NULL, '2025-06-13 13:51:23', '82.161.113.97', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Zaragoza', '41.64880000', '-0.88910000', NULL, 'España', 'Zaragoza'),
(112, 21, NULL, NULL, '2025-06-26 13:51:23', '82.4.108.172', 'Mozilla/5.0 Test Browser', NULL, 'IT', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma'),
(113, 13, NULL, NULL, '2025-06-20 13:51:23', '14.115.104.240', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Madrid', '40.41680000', '-3.70380000', NULL, 'España', 'Madrid'),
(114, 13, NULL, NULL, '2025-06-15 13:51:23', '86.151.82.240', 'Mozilla/5.0 Test Browser', NULL, 'PT', 'Lisboa', '38.72230000', '-9.13930000', NULL, 'Portugal', 'Lisboa'),
(115, 21, NULL, NULL, '2025-06-21 13:58:11', '250.195.113.213', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona'),
(116, 20, NULL, NULL, '2025-06-11 13:58:11', '21.146.11.153', 'Mozilla/5.0 Test Browser', NULL, 'FR', 'París', '48.85660000', '2.35220000', NULL, 'Francia', 'París'),
(117, 20, NULL, NULL, '2025-06-13 13:58:11', '6.43.245.7', 'Mozilla/5.0 Test Browser', NULL, 'IT', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma'),
(118, 13, NULL, NULL, '2025-06-25 13:58:11', '205.166.105.78', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Madrid', '40.41680000', '-3.70380000', NULL, 'España', 'Madrid'),
(119, 20, NULL, NULL, '2025-06-17 13:58:11', '178.169.249.132', 'Mozilla/5.0 Test Browser', NULL, 'PT', 'Lisboa', '38.72230000', '-9.13930000', NULL, 'Portugal', 'Lisboa'),
(120, 21, NULL, NULL, '2025-06-28 13:58:11', '224.216.215.201', 'Mozilla/5.0 Test Browser', NULL, 'PT', 'Lisboa', '38.72230000', '-9.13930000', NULL, 'Portugal', 'Lisboa'),
(121, 21, NULL, NULL, '2025-06-23 13:58:11', '249.142.39.218', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona'),
(122, 20, NULL, NULL, '2025-06-20 13:58:11', '121.93.174.161', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia'),
(123, 20, NULL, NULL, '2025-06-23 13:58:11', '67.3.121.67', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Las Palmas', '28.12350000', '-15.43630000', NULL, 'España', 'Las Palmas'),
(124, 21, NULL, NULL, '2025-06-18 13:58:11', '176.142.24.217', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Las Palmas', '28.12350000', '-15.43630000', NULL, 'España', 'Las Palmas'),
(125, 13, NULL, NULL, '2025-06-10 13:58:11', '239.189.175.6', 'Mozilla/5.0 Test Browser', NULL, 'DE', 'Berlín', '52.52000000', '13.40500000', NULL, 'Alemania', 'Berlín'),
(126, 13, NULL, NULL, '2025-06-17 13:58:11', '93.237.43.76', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Madrid', '40.41680000', '-3.70380000', NULL, 'España', 'Madrid'),
(127, 21, NULL, NULL, '2025-06-15 13:58:11', '208.166.180.198', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Zaragoza', '41.64880000', '-0.88910000', NULL, 'España', 'Zaragoza'),
(128, 20, NULL, NULL, '2025-06-16 13:58:11', '69.216.25.126', 'Mozilla/5.0 Test Browser', NULL, 'PE', 'Lima', '-12.04640000', '-77.04280000', NULL, 'Perú', 'Lima'),
(129, 13, NULL, NULL, '2025-06-27 13:58:11', '31.228.161.234', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo'),
(130, 21, NULL, NULL, '2025-06-17 13:58:11', '12.211.101.94', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Sevilla', '37.38910000', '-5.98450000', NULL, 'España', 'Sevilla'),
(131, 20, NULL, NULL, '2025-06-27 13:58:11', '173.116.229.188', 'Mozilla/5.0 Test Browser', NULL, 'AR', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires'),
(132, 21, NULL, NULL, '2025-06-12 13:58:11', '137.236.50.61', 'Mozilla/5.0 Test Browser', NULL, 'AR', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires'),
(133, 21, NULL, NULL, '2025-07-03 13:58:11', '251.202.121.211', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma'),
(134, 13, NULL, NULL, '2025-06-28 13:58:11', '118.118.111.241', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Sevilla', '37.38910000', '-5.98450000', NULL, 'España', 'Sevilla'),
(135, 20, NULL, NULL, '2025-07-05 13:58:11', '55.225.34.253', 'Mozilla/5.0 Test Browser', NULL, 'FR', 'París', '48.85660000', '2.35220000', NULL, 'Francia', 'París'),
(136, 13, NULL, NULL, '2025-06-18 13:58:11', '210.193.175.118', 'Mozilla/5.0 Test Browser', NULL, 'GB', 'Londres', '51.50740000', '-0.12780000', NULL, 'Reino Unido', 'Londres'),
(137, 13, NULL, NULL, '2025-06-09 13:58:11', '87.101.94.59', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia'),
(138, 21, NULL, NULL, '2025-06-13 13:58:11', '37.161.123.11', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Sevilla', '37.38910000', '-5.98450000', NULL, 'España', 'Sevilla'),
(139, 13, NULL, NULL, '2025-06-26 13:58:11', '19.9.42.247', 'Mozilla/5.0 Test Browser', NULL, 'AR', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires'),
(140, 20, NULL, NULL, '2025-06-22 13:58:11', '105.167.57.117', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Madrid', '40.41680000', '-3.70380000', NULL, 'España', 'Madrid'),
(141, 13, NULL, NULL, '2025-06-25 13:58:11', '5.29.144.111', 'Mozilla/5.0 Test Browser', NULL, 'PT', 'Lisboa', '38.72230000', '-9.13930000', NULL, 'Portugal', 'Lisboa'),
(142, 20, NULL, NULL, '2025-06-20 13:58:11', '126.23.88.180', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Madrid', '40.41680000', '-3.70380000', NULL, 'España', 'Madrid'),
(143, 13, NULL, NULL, '2025-06-15 13:58:11', '92.166.74.12', 'Mozilla/5.0 Test Browser', NULL, 'GB', 'Londres', '51.50740000', '-0.12780000', NULL, 'Reino Unido', 'Londres'),
(144, 21, NULL, NULL, '2025-07-05 13:58:11', '66.95.101.185', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia'),
(145, 21, NULL, NULL, '2025-07-04 13:58:11', '115.38.8.31', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma'),
(146, 20, NULL, NULL, '2025-06-23 13:58:11', '29.39.58.163', 'Mozilla/5.0 Test Browser', NULL, 'FR', 'París', '48.85660000', '2.35220000', NULL, 'Francia', 'París'),
(147, 20, NULL, NULL, '2025-07-04 13:58:11', '125.136.99.65', 'Mozilla/5.0 Test Browser', NULL, 'IT', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma'),
(148, 20, NULL, NULL, '2025-07-04 13:58:12', '48.96.44.158', 'Mozilla/5.0 Test Browser', NULL, 'AR', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires'),
(149, 21, NULL, NULL, '2025-06-27 13:58:12', '49.186.129.121', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona'),
(150, 21, NULL, NULL, '2025-06-27 13:58:12', '91.191.229.107', 'Mozilla/5.0 Test Browser', NULL, 'IT', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma'),
(151, 20, NULL, NULL, '2025-06-12 13:58:12', '228.29.239.73', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia'),
(152, 20, NULL, NULL, '2025-07-02 13:58:12', '65.85.49.161', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Sevilla', '37.38910000', '-5.98450000', NULL, 'España', 'Sevilla'),
(153, 13, NULL, NULL, '2025-06-25 13:58:12', '122.126.237.95', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona'),
(154, 21, NULL, NULL, '2025-06-21 13:58:12', '132.178.197.176', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Málaga', '36.72130000', '-4.42140000', NULL, 'España', 'Málaga'),
(155, 13, NULL, NULL, '2025-06-21 13:58:12', '160.106.22.175', 'Mozilla/5.0 Test Browser', NULL, 'US', 'Nueva York', '40.71280000', '-74.00600000', NULL, 'Estados Unidos', 'Nueva York'),
(156, 13, NULL, NULL, '2025-06-30 13:58:12', '152.126.66.208', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona'),
(157, 21, NULL, NULL, '2025-06-20 13:58:12', '149.40.115.159', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Zaragoza', '41.64880000', '-0.88910000', NULL, 'España', 'Zaragoza'),
(158, 13, NULL, NULL, '2025-07-02 13:58:12', '133.81.236.146', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona'),
(159, 20, NULL, NULL, '2025-07-02 13:58:12', '120.132.110.178', 'Mozilla/5.0 Test Browser', NULL, 'AR', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires'),
(160, 20, NULL, NULL, '2025-06-23 13:58:12', '105.43.144.248', 'Mozilla/5.0 Test Browser', NULL, 'US', 'Nueva York', '40.71280000', '-74.00600000', NULL, 'Estados Unidos', 'Nueva York'),
(161, 13, NULL, NULL, '2025-06-09 13:58:12', '212.144.1.243', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Málaga', '36.72130000', '-4.42140000', NULL, 'España', 'Málaga'),
(162, 20, NULL, NULL, '2025-06-29 13:58:12', '239.64.172.8', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Madrid', '40.41680000', '-3.70380000', NULL, 'España', 'Madrid'),
(163, 13, NULL, NULL, '2025-06-18 13:58:12', '125.201.182.149', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Las Palmas', '28.12350000', '-15.43630000', NULL, 'España', 'Las Palmas'),
(164, 21, NULL, NULL, '2025-06-25 13:58:12', '2.190.239.221', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Sevilla', '37.38910000', '-5.98450000', NULL, 'España', 'Sevilla'),
(165, 21, NULL, NULL, '2025-07-09 15:15:32', '62.99.100.233', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36', '', 'ES', 'PV', '43.26540000', '-2.92650000', 'Europe/Madrid', 'Spain', 'Bilbao'),
(166, 21, NULL, NULL, '2025-06-27 15:50:52', '241.115.190.243', 'Mozilla/5.0 Test Browser', NULL, 'AR', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires'),
(167, 21, NULL, NULL, '2025-07-01 15:50:52', '255.61.209.120', 'Mozilla/5.0 Test Browser', NULL, 'IT', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma'),
(168, 20, NULL, NULL, '2025-07-07 15:50:52', '233.19.232.197', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao'),
(169, 21, NULL, NULL, '2025-06-20 15:50:52', '125.197.139.118', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Zaragoza', '41.64880000', '-0.88910000', NULL, 'España', 'Zaragoza'),
(170, 21, NULL, NULL, '2025-06-12 15:50:52', '46.61.211.16', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma'),
(171, 20, NULL, NULL, '2025-06-22 15:50:52', '147.199.5.187', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma'),
(172, 21, NULL, NULL, '2025-07-05 15:50:52', '24.112.123.91', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao'),
(173, 13, NULL, NULL, '2025-06-11 15:50:52', '111.203.29.114', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Las Palmas', '28.12350000', '-15.43630000', NULL, 'España', 'Las Palmas'),
(174, 20, NULL, NULL, '2025-06-30 15:50:52', '44.82.46.203', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo'),
(175, 21, NULL, NULL, '2025-06-18 15:50:52', '152.235.0.35', 'Mozilla/5.0 Test Browser', NULL, 'MX', 'México DF', '19.43260000', '-99.13320000', NULL, 'México', 'México DF'),
(176, 13, NULL, NULL, '2025-06-22 15:50:52', '175.235.184.230', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Madrid', '40.41680000', '-3.70380000', NULL, 'España', 'Madrid'),
(177, 21, NULL, NULL, '2025-06-15 15:50:52', '40.56.230.249', 'Mozilla/5.0 Test Browser', NULL, 'GB', 'Londres', '51.50740000', '-0.12780000', NULL, 'Reino Unido', 'Londres'),
(178, 13, NULL, NULL, '2025-07-02 15:50:52', '71.41.244.92', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia'),
(179, 20, NULL, NULL, '2025-06-17 15:50:52', '10.10.88.238', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Valencia', '39.46990000', '-0.37630000', NULL, 'España', 'Valencia'),
(180, 20, NULL, NULL, '2025-06-09 15:50:52', '58.52.1.254', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma'),
(181, 21, NULL, NULL, '2025-06-16 15:50:52', '253.184.223.134', 'Mozilla/5.0 Test Browser', NULL, 'US', 'Nueva York', '40.71280000', '-74.00600000', NULL, 'Estados Unidos', 'Nueva York'),
(182, 13, NULL, NULL, '2025-06-15 15:50:52', '25.20.247.179', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo'),
(183, 21, NULL, NULL, '2025-06-16 15:50:52', '143.116.37.162', 'Mozilla/5.0 Test Browser', NULL, 'GB', 'Londres', '51.50740000', '-0.12780000', NULL, 'Reino Unido', 'Londres'),
(184, 13, NULL, NULL, '2025-06-29 15:50:52', '138.88.101.205', 'Mozilla/5.0 Test Browser', NULL, 'GB', 'Londres', '51.50740000', '-0.12780000', NULL, 'Reino Unido', 'Londres'),
(185, 20, NULL, NULL, '2025-06-24 15:50:52', '59.190.37.151', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Málaga', '36.72130000', '-4.42140000', NULL, 'España', 'Málaga'),
(186, 13, NULL, NULL, '2025-06-26 15:50:52', '111.197.46.108', 'Mozilla/5.0 Test Browser', NULL, 'FR', 'París', '48.85660000', '2.35220000', NULL, 'Francia', 'París'),
(187, 20, NULL, NULL, '2025-06-20 15:50:52', '235.203.201.35', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Murcia', '37.99220000', '-1.13070000', NULL, 'España', 'Murcia'),
(188, 21, NULL, NULL, '2025-06-10 15:50:52', '174.153.62.49', 'Mozilla/5.0 Test Browser', NULL, 'MX', 'México DF', '19.43260000', '-99.13320000', NULL, 'México', 'México DF'),
(189, 13, NULL, NULL, '2025-06-12 15:50:52', '181.235.82.15', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Sevilla', '37.38910000', '-5.98450000', NULL, 'España', 'Sevilla'),
(190, 21, NULL, NULL, '2025-06-23 15:50:52', '121.20.156.73', 'Mozilla/5.0 Test Browser', NULL, 'IT', 'Roma', '41.90280000', '12.49640000', NULL, 'Italia', 'Roma'),
(191, 21, NULL, NULL, '2025-07-07 15:50:52', '174.173.14.162', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona'),
(192, 13, NULL, NULL, '2025-06-18 15:50:52', '95.4.247.147', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Málaga', '36.72130000', '-4.42140000', NULL, 'España', 'Málaga'),
(193, 20, NULL, NULL, '2025-07-01 15:50:53', '11.214.167.145', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Sevilla', '37.38910000', '-5.98450000', NULL, 'España', 'Sevilla'),
(194, 21, NULL, NULL, '2025-07-01 15:50:53', '59.230.38.167', 'Mozilla/5.0 Test Browser', NULL, 'PE', 'Lima', '-12.04640000', '-77.04280000', NULL, 'Perú', 'Lima'),
(195, 21, NULL, NULL, '2025-06-22 15:50:53', '223.204.61.43', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Murcia', '37.99220000', '-1.13070000', NULL, 'España', 'Murcia'),
(196, 13, NULL, NULL, '2025-07-09 15:50:53', '179.203.94.16', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo'),
(197, 21, NULL, NULL, '2025-06-30 15:50:53', '140.204.8.221', 'Mozilla/5.0 Test Browser', NULL, 'US', 'Nueva York', '40.71280000', '-74.00600000', NULL, 'Estados Unidos', 'Nueva York'),
(198, 20, NULL, NULL, '2025-06-22 15:50:53', '109.56.28.33', 'Mozilla/5.0 Test Browser', NULL, 'AR', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires'),
(199, 20, NULL, NULL, '2025-06-14 15:50:53', '132.154.183.221', 'Mozilla/5.0 Test Browser', NULL, 'MX', 'México DF', '19.43260000', '-99.13320000', NULL, 'México', 'México DF'),
(200, 13, NULL, NULL, '2025-06-24 15:50:53', '97.217.9.91', 'Mozilla/5.0 Test Browser', NULL, 'FR', 'París', '48.85660000', '2.35220000', NULL, 'Francia', 'París'),
(201, 13, NULL, NULL, '2025-06-09 15:50:53', '188.37.173.139', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo'),
(202, 13, NULL, NULL, '2025-06-24 15:50:53', '255.191.218.77', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Sevilla', '37.38910000', '-5.98450000', NULL, 'España', 'Sevilla'),
(203, 13, NULL, NULL, '2025-06-25 15:50:53', '247.217.152.214', 'Mozilla/5.0 Test Browser', NULL, 'AR', 'Buenos Aires', '-34.60370000', '-58.38160000', NULL, 'Argentina', 'Buenos Aires'),
(204, 20, NULL, NULL, '2025-06-11 15:50:53', '63.113.27.74', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona'),
(205, 20, NULL, NULL, '2025-07-04 15:50:53', '49.175.193.205', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao'),
(206, 20, NULL, NULL, '2025-07-06 15:50:53', '133.91.40.64', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Barcelona', '41.38510000', '2.17340000', NULL, 'España', 'Barcelona'),
(207, 21, NULL, NULL, '2025-07-09 15:50:53', '171.188.129.166', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Las Palmas', '28.12350000', '-15.43630000', NULL, 'España', 'Las Palmas'),
(208, 21, NULL, NULL, '2025-06-17 15:50:53', '215.192.78.242', 'Mozilla/5.0 Test Browser', NULL, 'DE', 'Berlín', '52.52000000', '13.40500000', NULL, 'Alemania', 'Berlín'),
(209, 20, NULL, NULL, '2025-06-19 15:50:53', '179.223.221.174', 'Mozilla/5.0 Test Browser', NULL, 'BR', 'São Paulo', '-23.55050000', '-46.63330000', NULL, 'Brasil', 'São Paulo'),
(210, 13, NULL, NULL, '2025-07-05 15:50:53', '202.243.77.16', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma'),
(211, 20, NULL, NULL, '2025-06-20 15:50:53', '16.218.250.115', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Palma', '39.56960000', '2.65020000', NULL, 'España', 'Palma'),
(212, 20, NULL, NULL, '2025-06-15 15:50:53', '134.124.52.231', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao'),
(213, 20, NULL, NULL, '2025-07-08 15:50:53', '98.84.166.65', 'Mozilla/5.0 Test Browser', NULL, 'MX', 'México DF', '19.43260000', '-99.13320000', NULL, 'México', 'México DF'),
(214, 13, NULL, NULL, '2025-06-14 15:50:53', '40.28.9.54', 'Mozilla/5.0 Test Browser', NULL, 'PT', 'Lisboa', '38.72230000', '-9.13930000', NULL, 'Portugal', 'Lisboa'),
(215, 13, NULL, NULL, '2025-07-08 15:50:53', '113.208.22.190', 'Mozilla/5.0 Test Browser', NULL, 'ES', 'Bilbao', '43.26300000', '-2.93500000', NULL, 'España', 'Bilbao');

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

INSERT INTO `urls` (`id`, `user_id`, `short_code`, `original_url`, `created_at`, `clicks`, `last_click`, `ip_address`, `user_agent`, `active`, `is_public`, `title`, `description`) VALUES
(13, NULL, 'test123', 'https://www.google.com', '2025-07-09 06:44:52', 70, NULL, '127.0.0.1', NULL, 1, 1, NULL, NULL),
(20, NULL, '160orw', 'https://abc.es', '2025-07-09 13:23:29', 64, '2025-07-09 13:23:51', '62.99.100.233', NULL, 1, 1, NULL, NULL),
(21, NULL, 'nGpCr0', 'https://youtube.com', '2025-07-09 13:31:19', 65, '2025-07-09 15:15:32', '62.99.100.233', NULL, 1, 1, NULL, NULL),
(22, NULL, 'vop545', 'https://google.es', '2025-07-10 16:00:28', 0, NULL, NULL, NULL, 1, 1, NULL, NULL);

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
(1, 'admin', 'admin@localhost', '$2y$12$UCK6veUIC28shVZ2MbLnhOpl.ia6KlCFlJlZmwQ8R3ZgGQ1K9UtHK', 'Administrador', 'active', 'admin', '2025-07-09 20:22:44', '2025-07-10 19:48:50', '2025-07-10 19:48:50', 1, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, 1);

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
-- Indices de la tabla `click_stats`
--
ALTER TABLE `click_stats`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_url_id` (`url_id`),
  ADD KEY `idx_country_code` (`country_code`),
  ADD KEY `idx_country` (`country`),
  ADD KEY `idx_city` (`city`),
  ADD KEY `idx_click_stats_user_id` (`user_id`);

--
-- Indices de la tabla `config`
--
ALTER TABLE `config`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `config_key` (`config_key`),
  ADD KEY `idx_config_key` (`config_key`);

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
  ADD KEY `idx_urls_user_status` (`user_id`,`active`);

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
-- AUTO_INCREMENT de la tabla `click_stats`
--
ALTER TABLE `click_stats`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=216;

--
-- AUTO_INCREMENT de la tabla `config`
--
ALTER TABLE `config`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `system_settings`
--
ALTER TABLE `system_settings`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=239;

--
-- AUTO_INCREMENT de la tabla `urls`
--
ALTER TABLE `urls`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT de la tabla `users`
--
ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `user_activity`
--
ALTER TABLE `user_activity`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `user_sessions`
--
ALTER TABLE `user_sessions`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `click_stats`
--
ALTER TABLE `click_stats`
  ADD CONSTRAINT `click_stats_ibfk_1` FOREIGN KEY (`url_id`) REFERENCES `urls` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_click_stats_url_id` FOREIGN KEY (`url_id`) REFERENCES `urls` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_click_stats_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

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

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
