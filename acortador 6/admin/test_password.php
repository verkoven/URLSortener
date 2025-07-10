<?php
// Test de contraseña
$password = 'admin123';
$hash = '$2y$10$YtQ6BN9JLQkGQPHJvPcCCu/FprtFNJ5I9yJrgeNPDVxFtmkBbBCXS';

echo "Probando contraseña 'admin123':<br>";
echo "Hash: $hash<br>";
echo "Verificación: " . (password_verify($password, $hash) ? '✅ CORRECTA' : '❌ INCORRECTA') . "<br><br>";

// Generar un nuevo hash para admin123
$new_hash = password_hash('admin123', PASSWORD_DEFAULT);
echo "Nuevo hash generado para 'admin123':<br>";
echo "<code>$new_hash</code><br><br>";

echo "Puedes usar este SQL para actualizar:<br>";
echo "<textarea style='width:100%; height:100px'>";
echo "UPDATE users SET password = '$new_hash' WHERE username = 'admin';";
echo "</textarea>";
?>
