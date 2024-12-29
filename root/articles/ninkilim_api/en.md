# Ninkilim: API

Ninkilim provides a public API to fetch postings and display them in an app 
or on another website. You can choose to receive the data as JSON, XML or YAML.

## Examples for API calls:
```sh
GET https://ninkilim.com/?format=json
GET https://ninkilim.com/search?q=ninkilim&format=xml
GET https://ninkilim.com/users/R34lB0rg?format=yaml
```
## Examples for Data

```json
{
  "postings": [
    {
      "author": {
        "website": "https://t.co/sULKXqza00",
        "bio": "والله انا قلبي فلسطيني",
        "displayname": "فريد 🇵🇸🍉🔻",
        "username": "R34lB0rg",
        "id": 42969356,
        "location": "Temple of Ninkilim"
      },
      "date": "2024-12-23 01:01:38",
      "lang": "en ",
      "parent": 0,
      "id": "1870998163776528163",
      "medias": [
        {
          "url": "https://ninkilim.com/media/1870998163776528163-gvZ5eWGY64T3Ucp.png",
          "filename": "1870998163776528163-gvZ5eWGY64T3Ucp.png",
          "type": "image"
        },
        {
          "url": "https://ninkilim.com/media/1870998163776528163-XkAUTzxWiNgIWhw.png",
          "filename": "1870998163776528163-XkAUTzxWiNgIWhw.png",
          "type": "image"
        },
        {
          "type": "image",
          "filename": "1870998163776528163-U5IvXSuiF7LnPHV.png",
          "url": "https://ninkilim.com/media/1870998163776528163-U5IvXSuiF7LnPHV.png"
        },
        {
          "filename": "1870998163776528163-xAzobSiJKtNIwHM.png",
          "type": "image",
          "url": "https://ninkilim.com/media/1870998163776528163-xAzobSiJKtNIwHM.png"
        }
      ],
      "text": "Ninkilim is an open-source social media network designed to import posts (tweets) from X (Twitter), offering users control over their data to overcome the political bias and censorship on X (Twitter).\r\n\r\nThe platform was developed in response to X (Twitter) limiting visibility and suspending accounts which go against the political agenda pushed by it's owner. It empowers the users to take control of their own content and provides a decentralized social media network featuring clustering, content syndication and an open API. It comes with it's own webserver but can also be integrated with existing Apache / NGINX installations."
    }
  ]
}
```
```xml
<xml>
    <postings>
        <id>1870998163776528163</id>
        <author>
            <id>42969356</id>
            <bio>والله انا قلبي فلسطيني</bio>
            <displayname>فريد 🇵🇸🍉🔻</displayname>
            <location>Temple of Ninkilim</location>
            <username>R34lB0rg</username>
            <website>https://t.co/sULKXqza00</website>
        </author>
        <date>2024-12-23 01:01:38</date>
        <lang>en </lang>
        <medias>
            <filename>1870998163776528163-gvZ5eWGY64T3Ucp.png</filename>
            <type>image</type>
            <url>https://ninkilim.com/media/1870998163776528163-gvZ5eWGY64T3Ucp.png</url>
        </medias>
        <medias>
            <filename>1870998163776528163-XkAUTzxWiNgIWhw.png</filename>
            <type>image</type>
            <url>https://ninkilim.com/media/1870998163776528163-XkAUTzxWiNgIWhw.png</url>
        </medias>
        <medias>
            <filename>1870998163776528163-U5IvXSuiF7LnPHV.png</filename>
            <type>image</type>
            <url>https://ninkilim.com/media/1870998163776528163-U5IvXSuiF7LnPHV.png</url>
        </medias>
        <medias>
            <filename>1870998163776528163-xAzobSiJKtNIwHM.png</filename>
            <type>image</type>
            <url>https://ninkilim.com/media/1870998163776528163-xAzobSiJKtNIwHM.png</url>
        </medias>
        <parent>0</parent>
        <text>Ninkilim is an open-source social media network designed to import posts (tweets) from X (Twitter), offering users control over their data to overcome the political bias and censorship on X (Twitter). The platform was developed in response to X (Twitter) limiting visibility and suspending accounts which go against the political agenda pushed by it's owner. It empowers the users to take control of their own content and provides a decentralized social media network featuring clustering, content syndication and an open API. It comes with it's own webserver but can also be integrated with existing Apache / NGINX installations.</text>
</postings>
</xml>
```
```yaml
---
postings:
- author:
    bio: والله انا قلبي فلسطيني
    displayname: "فريد \U0001F1F5\U0001F1F8\U0001F349\U0001F53B"
    id: 42969356
    location: Temple of Ninkilim
    username: R34lB0rg
    website: https://t.co/sULKXqza00
  date: 2024-12-23 01:01:38
  id: '1870998163776528163'
  lang: 'en '
  medias:
  - filename: 1870998163776528163-gvZ5eWGY64T3Ucp.png
    type: image
    url: https://ninkilim.com/media/1870998163776528163-gvZ5eWGY64T3Ucp.png
  - filename: 1870998163776528163-XkAUTzxWiNgIWhw.png
    type: image
    url: https://ninkilim.com/media/1870998163776528163-XkAUTzxWiNgIWhw.png
  - filename: 1870998163776528163-U5IvXSuiF7LnPHV.png
    type: image
    url: https://ninkilim.com/media/1870998163776528163-U5IvXSuiF7LnPHV.png
  - filename: 1870998163776528163-xAzobSiJKtNIwHM.png
    type: image
    url: https://ninkilim.com/media/1870998163776528163-xAzobSiJKtNIwHM.png
  parent: 0
  text: "Ninkilim is an open-source social media network designed to import posts
    (tweets) from X (Twitter), offering users control over their data to overcome
    the political bias and censorship on X (Twitter).\r\n\r\nThe platform was developed
    in response to X (Twitter) limiting visibility and suspending accounts which go
    against the political agenda pushed by it's owner. It empowers the users to take
    control of their own content and provides a decentralized social media network
    featuring clustering, content syndication and an open API. It comes with it's
    own webserver but can also be integrated with existing Apache / NGINX installations."
```
