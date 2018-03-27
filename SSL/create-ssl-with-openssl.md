
Check old SCR file information:
	openssl req -text -noout -in san_domain_com.csr

-----------------------------------
*First generate your RSA Private Key:
   openssl genrsa -des3 -out server.key 2048

*Remove the passpharaze from Key:
   cp server.key server.key.orig
   openssl rsa -in server.key.orig -out server.key

*Then generate a Certificate Signing Request (CSR)
   openssl req -new -key server.key -out server.csr

*Finally to generate a Sefl-Signed Certificate:
   openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt

*When update ssl key with crt and CA cert.
Co the dung lenh openssl s_client -connect domain:443
xem issuer: CN example: GlobalSign Domain Validation CA - SHA256 -G2/ JPRS ... 
on internet find CA Certificate -> Config

*Check CA 
openssl x509 -in secure.iam.ne.jp.cer -text -noout

*JPRS CA download
https://jprs.jp/pubcert/info/intermediate/

C=JP, ST=OSAKA, L=OSAKA, O=NANKAI-DENSETSU Co.Ltd,, CN=future-keith.jp


# JPRS 証明書設定

1．中間CA証明書確認方法
	openssl x509 -in secure.iam.ne.jp.cer -text -noout
	|-Issuer: C=JP, O=Japan Registry Services Co., Ltd., CN=JPRS Domain Validation Authority - G1
	|-Issuer: C=JP, O=Japan Registry Services Co., Ltd., CN=JPRS Organization Validation Authority - G1
	+JPRS Domain Validation Authority - G1: JPRS_DVCA.cerを利用します
	+JPRS Organization Validation Authority - G1：JPRS_OVCA.cerを利用します
