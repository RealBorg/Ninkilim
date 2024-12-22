# Ninkilim: Usage

# Multilingual Articles in Markdown
```sh
    mkdir root/articles
    mkdir root/articles/$title
    vi root/articles/$title/en.md
```
Article will be available at http://$server/articles/$title
Save additional languages as root/articles/$title/$langcode.md
Ninkilim will use the language preference configured in your web browser
You can override the language selection by appending ?lang=$langcode

# Search Engine Optimization
If you want your postings to be found by search engines, you can use the 
commands below to generate XML sitemap files with 25,000 entries each
```sh
wget -o root/static/sitemap-1.xml https://<yoursite>/sitemap/1
wget -o root/static/sitemap-2.xml https://<yoursite>/sitemap/2
...
```
Repeat as needed to create entries for all your postings. You will then
want to manually add these sitemaps to root/static/sitemap.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <sitemap>
    <loc>https://$server/sitemap-1.xml</loc>
  </sitemap>
</sitemapindex>
and root/static/robots.txt
```robots.txt
Sitemap: https://hostmaster.org/sitemap.xml
```
