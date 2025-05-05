https://developers.facebook.com/docs/whatsapp/cloud-api/reference/whatsapp-business-encryption

openssl genrsa -des3 -out private.pem 2048
openssl rsa -in private.pem -outform PEM -pubout -out public.pem
openssl x509 -pubkey -noout -in private.pem  > public.pem   
