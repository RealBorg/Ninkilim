# Ninkilim: Usage

## Import Postings from X (Twitter)
More -> Settings and privacy -> Download an archive of your data
```sh
    unzip twitter-\*.zip
    cp data/account.js data/profile.js data/tweets.js data/tweets.js data/tweets-part\*.js data/note-tweet.js Ninkilim/root
    cp -r data/tweets\_media Ninkilim/root/static
    sudo -u ninkilim Ninkilim/scripts/ninkilim\_test.pl /import
```
