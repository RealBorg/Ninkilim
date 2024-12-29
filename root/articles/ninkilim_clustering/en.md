# Ninkilim: Cluster Configuration

For load-balancing, availability and data redundancy it may be desirable to 
have several nodes serving the same content. Ninkilim comes with built in 
replication which can save a lot of money compared to conventional setups 
using load balancers and high availability database clusters.

## Step 1: Install Ninkilim

Set up each node as described in [Ninkilim: Installation Guide](ninkilim_installation)

## Step 2: Import Your Data

### Option 1: Peer-to-Peer with pg\_dump/pg\_restore

Import your data on one of the nodes as described in [Ninkilim: Migration](ninkilim_migration)

Then use pg\_dump, pg\_restore and rsync to initialize the other nodes. For example:
``sh
cd /var/www/Ninkilim
pg_dump -F t -f ninkilim.tar
rsync . $othernode:/var/www/Ninkilim
``
then on each of the other nodes:
``sh
cd /var/www/Ninkilim
createdb ninkilim
pg_restore -d ninkilim ninkilim.tar
``
Skip to "Step 3: Peering Configuration"

## Option 2: Peer-to-Peer with Import

Follow the instructions from [Ninkilim: Migration](nikilim_migration) on each
of the nodes. Skip to "Step 3: Peering Configuration"

## Option 3: Master / Slave Configuration

Follow the instructions from [Ninkilim: Migration](nikilim_migration) on one 
of the nodes. Skip to "Step 3: Peering Configuration" - "Option 1: peers.txt"

## Step 3: Peering Configuration

### Option 1: peers.txt

Import your data on one of the nodes and then add the url of that node to
/var/www/Ninkilim/root/peers.txt on the other nodes.

### Option 2: Web-Interface

Navigate to /login on each of the nodes and enter your e-mail address to 
request a login link / token by e-mail. Navigate to /sync on each of the 
nodes and add all of the other nodes.

## Step 4: Crontab
On each of the nodes, add the following line to crontab -e
```
    * * * * * GET -d http://localhost:3000/sync/run
```
