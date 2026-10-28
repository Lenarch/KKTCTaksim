# Yerel https test sunucusu

iPhone Safari konumu yalnızca https bağlantıda paylaştığı için web derlemesini kendi imzaladığımız
bir sertifikayla yayınlıyoruz. Sertifikalar `tool/certs/` altında durur ve git'e eklenmez.

1. Sertifika oluştur (bir kez; IP'yi `ipconfig` çıktısındaki Wi-Fi adresinle değiştir):
   ```bash
   mkdir -p tool/certs
   MSYS_NO_PATHCONV=1 openssl req -x509 -newkey rsa:2048 -nodes -days 30 \
     -keyout tool/certs/key.pem -out tool/certs/cert.pem -subj "/CN=KKTC Taksim test" \
     -addext "subjectAltName=IP:192.168.1.104,DNS:localhost,IP:127.0.0.1"
   ```
2. Derle ve yayınla:
   ```bash
   flutter build web --release
   python -u tool/serve_https.py build/web tool/certs
   ```
3. Telefondan `https://<IP>:8080` adresini aç, Safari uyarısında
   "Ayrıntıları Göster → bu web sitesini ziyaret et" de.
