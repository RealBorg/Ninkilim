# Ninkilim: Display your Tweets on your Website

X (Twitter) offers to "Download an archive of your data" 
which includes a 'Your Archive.html" Viewer which is not
suitable for showing your Tweets on your own Website.

This project makes it possible to import the Tweets from 
the download into a PostgreSQL database and show them on
your own Domain / Server / Website.

## Features

- Import Tweets into PostgreSQL database
- Show in chronological order
- Search
- Thread-View
- Multilingual Articles in Markdown
- JSON-Interface
- Stand-Alone Webserver
- mod\_proxy, CGI or FCGI Interface for Integration with Apache

# INSTALLATION

## REQUIREMENTS
libcatalyst-perl
libcatalyst-devel-perl
libcatalyst-action-renderview-perl
libcatalyst-model-dbic-schema-perl
libcatalyst-plugin-static-simple-perl
libcatalyst-plugin-configloader-perl
libcatalyst-view-json-perl
libcatalyst-view-tt-perl
libdatetime-format-pg-perl
libdbix-class-schema-loader-perl
libtext-markdown-perl
postgresql
starman

## SYSTEM / DATABASE CONFIGURATION
adduser ninkilim
sudo -u postgres createuser -d ninkilim
sudo -u ninkilim createdb ninkilim
sudo -u ninkilim psql -f ninkilim.sql ninkilim

## DATA IMPORT
x.com: More -> Settings and privacy -> Download an archive of your data
unzip twitter-\*.zip
cp data/account.js data/profile.js data/tweets.js data/tweets.js data/tweets-part\*.js data/note-tweet.js Ninkilim/root
cp -r data/tweets\_media Ninkilim/root/static
sudo -u ninkilim Ninkilim/scripts/ninkilim\_test.pl /import
sudo -u ninkilim Ninkilim/scripts/ninkilim\_server.pl -f
http://localhost:3000/

## APACHE INTEGRATION
a2enmod proxy\_http
ProxyPreserveHost On
ProxyPass / http://localhost:3000/
ProxyPassReverse / http://localhost:3000/

# ARTICLES
mkdir root/articles
mkdir root/articles/title
vi root/articles/title/en.md
http://localhost:3000/articles/title?lang=en
