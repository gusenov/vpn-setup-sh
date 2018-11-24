#!/bin/bash
#set -x  # echo on

# Usage:

#  $ ./key-crt.sh --working_directory="./easy-rsa-client" --make
#  $ ./key-crt.sh --working_directory="./easy-rsa-client" --build_certificate_request_from="my-vpn-client"
#  Output:
#    ./easy-rsa-client/keys/my-vpn-client.key
#    ./easy-rsa-client/keys/my-vpn-client.csr

#  $ ./key-crt.sh --working_directory="./easy-rsa-server" --make
#  $ ./key-crt.sh --working_directory="./easy-rsa-server" --build_certificate_request_from="my-vpn-server"
#  Output:
#    ./easy-rsa-server/keys/my-vpn-server.key
#    ./easy-rsa-server/keys/my-vpn-server.csr

#  $ ./key-crt.sh --working_directory="./easy-rsa-server" --build_diffie_hellman_key
#  Output: ./easy-rsa-server/dh2048.pem

#  $ ./key-crt.sh --working_directory="./easy-rsa-server" --build_tls_auth_key="ta.key"
#  Output: ./easy-rsa-server/ta.key

#  $ ./key-crt.sh --working_directory="./easy-rsa-ca" --make
#  $ ./key-crt.sh --working_directory="./easy-rsa-ca" --build_certificate_authority
#  Output:
#    ./easy-rsa-ca/keys/ca.key
#    ./easy-rsa-ca/keys/ca.crt

#  $ ./key-crt.sh --working_directory="./easy-rsa-ca" --sign_certificate_request_for="./easy-rsa-client/keys/my-vpn-client"
#  Output: ./easy-rsa-ca/keys/my-vpn-client.crt

#  $ ./key-crt.sh --working_directory="./easy-rsa-ca" --sign_certificate_request_for="./easy-rsa-server/keys/my-vpn-server"
#  Output: ./easy-rsa-ca/keys/my-vpn-server.crt


country_name="US"
state_or_province_name="CA"
locality_name="SanFrancisco"
organization_name="Fort-Funston"
email_address="me@myhost.mydomain"
organizational_unit_name="MyOrganizationalUnit"


function make_working_directory() {
  make-cadir "$1"
  cd "$1"

  sed -i "s|export KEY_COUNTRY=\"US\"|export KEY_COUNTRY=\"$country_name\"|g" "./vars"
  sed -i "s|export KEY_PROVINCE=\"CA\"|export KEY_PROVINCE=\"$state_or_province_name\"|g" "./vars"
  sed -i "s|export KEY_CITY=\"SanFrancisco\"|export KEY_CITY=\"$locality_name\"|g" "./vars"
  sed -i "s|export KEY_ORG=\"Fort-Funston\"|export KEY_ORG=\"$organization_name\"|g" "./vars"
  sed -i "s|export KEY_EMAIL=\"me@myhost.mydomain\"|export KEY_EMAIL=\"$email_address\"|g" "./vars"
  sed -i "s|export KEY_OU=\"MyOrganizationalUnit\"|export KEY_OU=\"$organizational_unit_name\"|g" "./vars"

  if [ ! -f "openssl.cnf" ] && [ -f "openssl-1.0.0.cnf" ]; then
    ln -s "openssl-1.0.0.cnf" "openssl.cnf"
    #sed -i 's|export KEY_CONFIG=`$EASY_RSA/whichopensslcnf $EASY_RSA`|export KEY_CONFIG=$EASY_RSA/openssl-1.0.0.cnf|g' "./vars"
  fi

  source "./vars"

  ./clean-all  # rm -rf on $1/keys
}

function build_certificate_request_from() {
  ./build-req "$1"
}

function build_diffie_hellman_key() {
  ./build-dh
}

function build_tls_auth_key() {
  openvpn --genkey --secret "$1"
}

function build_certificate_authority() {
  ./build-ca
}

function sign_certificate_request_for() {
  if [ ! -f "./keys/index.txt.attr" ]; then
    touch "./keys/index.txt.attr"
  fi
  ./sign-req "$1"
}


for i in "$@"; do
  case $i in

    --working_directory=*)
        working_directory="${i#*=}"
        shift  # past argument=value
        ;;

    --make)
        make_working_directory "$working_directory"
        ls -lah "./"

        shift  # past argument=value
        ;;

    --build_certificate_request_from=*)
        cd "$working_directory"
        source "./vars"

        build_certificate_request_from "${i#*=}"
        ls -lah "./keys"

        shift  # past argument=value
        ;;

    --build_diffie_hellman_key)
        cd "$working_directory"
        source "./vars"

        build_diffie_hellman_key
        ls -lah "./keys"

        shift  # past argument=value
        ;;

    --build_tls_auth_key=*)
        cd "$working_directory"
        source "./vars"

        build_tls_auth_key "${i#*=}"
        ls -lah "./"

        shift  # past argument=value
        ;;

    --build_certificate_authority)
        cd "$working_directory"
        source "./vars"

        build_certificate_authority
        ls -lah "./keys"

        shift  # past argument=value
        ;;

    --sign_certificate_request_for=*)
        certificate_request_path="$(realpath ${i#*=})"

        cd "$working_directory"

        cp "$certificate_request_path.csr" "./keys/"
        cp "$certificate_request_path.key" "./keys/"

        source "./vars"
        sign_certificate_request_for "$(basename $certificate_request_path)"
        ls -lah "./keys"

        shift  # past argument=value
        ;;

  esac
done
