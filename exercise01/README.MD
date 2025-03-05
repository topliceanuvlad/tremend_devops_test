## Starting an Ubuntu Container

```bash
docker run -it ubuntu
```
### 1. Lookup the Public IP of tremend.com

```bash
apt update && apt install -y dnsutils
nslookup tremend.com
```
![alt text](images/image-4.png)

### 2. Map IP address `8.8.8.8` to hostname `google-dns`

```bash
apt install -y nano
nano /etc/hosts
```
![alt text](images/image-1.png)

### 3. Check if DNS Port is Open for `google-dns`

```bash
apt update && apt install -y iputils-ping
ping -c 4 google-dns
```
![alt text](images/image-2.png)

### 4. Change system DNS to Google’s Public DNS (`8.8.8.8`)

```bash
nano /etc/resolv.conf
cat /etc/resolv.conf
```
![alt text](images/image-3.png)

```bash
nslookup tremend.com
```
![alt text](images/image-5.png)

*Notice DNS queries now using Google's DNS.*

### 5. Install and verify Nginx service

```bash
apt install -y nginx
apt install -y systemctl
service nginx status
ps aux | grep nginx
```
![alt text](images/image-6.png)

### 6. Find the listening port for Nginx

```bash
ss -tulnp | grep nginx
```
![alt text](images/image-7.png)


## Bonus Tasks

```bash
nano /etc/nginx/sites-available/default
```
![alt text](images/image-8.png)

```bash
service nginx restart
```
![alt text](images/image-9.png)

```bash
nano /var/www/html/index.nginx-debian.html
```
![alt text](images/image-11.png)
![alt text](images/image-12.png)