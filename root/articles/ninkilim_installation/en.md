# Ninkilim: Installation

## Get the Code
```sh
    git clone https://github.com/RealBorg/Ninkilim.git
    gh repo clone RealBorg/Ninkilim
```

## Install Requirements
```sh
    apt-get install libcatalyst-perl \
        libcatalyst-devel-perl \
        libcatalyst-model-dbic-schema-perl \
        libcatalyst-plugin-configloader-perl \
        libcatalyst-plugin-session-perl \
        libcatalyst-plugin-session-state-cookie-perl \
        libcatalyst-plugin-session-store-dbic-perl \
        libcatalyst-plugin-static-simple-perl \
        libcatalyst-view-json-perl \
        libcatalyst-view-tt-perl \
        libdatetime-format-pg-perl \
        libdbd-pg-perl \
        libdbix-class-schema-loader-perl \
        liblingua-identify-perl \
        libnet-ntp-perl \
        libtext-multimarkdown-perl \
        postgresql \
        starman
```

## System Configuration
For security / privilege separation it is recommend to create a new user
```sh
    useradd ninkilim
```

## Database Configuration
```sh
    sudo -u postgres createuser ninkilim
    sudo -u postgres createdb -O ninkilim ninkilim
    sudo -u ninkilim psql -f ninkilim.sql ninkilim
```

## Start the Server
```sh
    sudo -u ninkilim Ninkilim/scripts/ninkilim\_server.pl -f
```
You can now open http://$server:3000/ in your web browser

## Apache Integration
```sh
    a2enmod headers proxy proxy\_http ssl
```
```apache
    <VirtualHost *:80>
        ProxyPreserveHost On
        RequestHeader set X-Forwarded-HTTPS "%{HTTPS}s"
        RequestHeader set X-Forwarded-Proto "%{REQUEST_SCHEME}e"
        RequestHeader set X-Forwarded-Port "%{SERVER_PORT}e"
        RequestHeader set X-Forwarded-For "%{REMOTE_ADDR}e"
        RequestHeader set X-Forwarded-Server "%{HTTP_HOST}e"
        ProxyPass / http://localhost:3000/
        ProxyPassReverse / http://localhost:3000/
    </VirtualHost>
    <VirtualHost *:443>
        ProxyPreserveHost On
        RequestHeader set X-Forwarded-HTTPS "%{HTTPS}s"
        RequestHeader set X-Forwarded-Proto "%{REQUEST_SCHEME}e"
        RequestHeader set X-Forwarded-Port "%{SERVER_PORT}e"
        RequestHeader set X-Forwarded-For "%{REMOTE_ADDR}e"
        RequestHeader set X-Forwarded-Server "%{HTTP_HOST}e"
        ProxyPass / http://localhost:3000/
        ProxyPassReverse / http://localhost:3000/
    </VirtualHost>
```
