#!/bin/sh
# Creates the Google Play upload key and android/key.properties.
# Keep the key file and its password safe: every app update must be signed
# with it. Run from the project folder: sh tool/create_upload_key.sh
set -e
KEYSTORE="$HOME/i_fillup-upload-key.jks"
if [ -e "$KEYSTORE" ]; then
  echo "$KEYSTORE already exists; not overwriting it."
  exit 1
fi
printf "Choose a password for the upload key (at least 6 characters): "
stty -echo; read -r PASSWORD; stty echo; echo
printf "Repeat the password: "
stty -echo; read -r REPEAT; stty echo; echo
if [ "$PASSWORD" != "$REPEAT" ]; then
  echo "The passwords differ. Nothing was created."
  exit 1
fi
keytool -genkeypair -keystore "$KEYSTORE" -storetype PKCS12 -alias upload \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$PASSWORD" -keypass "$PASSWORD" -dname "CN=i fillup, C=CH"
cat > android/key.properties <<PROPERTIES
storePassword=$PASSWORD
keyPassword=$PASSWORD
keyAlias=upload
storeFile=$KEYSTORE
PROPERTIES
chmod 600 android/key.properties "$KEYSTORE"
echo
echo "Created $KEYSTORE and android/key.properties."
echo "Back up the key file and its password now (e.g. in a password manager)."
echo "SHA-1 of the upload key (for the Places API key restriction):"
keytool -list -v -keystore "$KEYSTORE" -storepass "$PASSWORD" | grep "SHA1:"
