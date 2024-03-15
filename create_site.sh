#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Ce script doit être lancé avec les privilèges sudo"
    exit 1
fi

if [ "$#" -gt 0 ]; then
    echo "Veuillez ne pas passer de paramètres !"
    exit 1
fi

read -p "Entrez l'adresse mail du webmaster : " serverAdmin
read -p "Entrez l'URL du site : " serverName
read -p "Entrez le répertoire racine du dossier (excluez /var/www/) : " directory
read -p "Entrez un nom pour le fichier de configuration (excluez .conf) : " configFile

documentRoot="/var/www/$directory/"
configFile="/etc/apache2/sites-available/$configFile.conf"
# echo $configFile
# echo $serverAdmin
# echo $serverName
# echo $documentRoot


if [ ! -d "/etc/apache2/sites-available" ]; then
    echo "Le répertoire des fichiers de configuration des sites d'Apache n'a pas été trouvé"
    exit 1
fi

if ! command -v apache2 >/dev/null 2>&1; then
    echo "Apache n'est pas intallé"
    exit 1
fi

if [ -e "$configFile" ]; then
    echo "Une configuration Virtual Host existe déjà pour $directory."
    exit 1
fi

cat <<EOL > "$configFile"
<VirtualHost *:80>
    ServerAdmin $serverAdmin
    ServerName $serverName
    DocumentRoot $documentRoot

    ErrorLog \${APACHE_LOG_DIR}/$directory/$directory-error.log
    CustomLog \${APACHE_LOG_DIR}/$directory/$directory-access.log combined

    <Directory $documentRoot>
        Options -Indexes          
        AllowOverride All
        Require all granted
    </Directory>

</VirtualHost>
EOL

mkdir $documentRoot

cat <<EOL > "$documentRoot/index.html"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$directory</title>
</head>
<body>
   <h1>Site $serverName en ligne !</h1>
</body>
</html>
EOL

sudo chown -R $(logname) $documentRoot
sudo chmod -R 770 $documentRoot

mkdir /var/log/apache2/$directory/

a2ensite $directory

systemctl restart apache2
echo "Service Apache2 redémarré"

echo "Fichier de configuration Virtual Host créé pour $serverName"

read -p "Voulez vous demander un certificat et activer le https ? (nécessite certbot installé) (o/n) : " cerbotChoix
if [ $certbotChoix = "o" ]; then
    sudo certbot --domains $serverName
fi
