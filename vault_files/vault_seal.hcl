# // seal stanza eg: seal "awkskms" { ...
seal "pkcs11" {
	lib		= "/opt/utimaco/lib64/libcs_pkcs11_R2.so"
	slot		= "3"
	pin		= "1234"
	key_label	= "hsm:v1:vault"
	hmac_key_label	= "hsm:v1:vault-hmac"
	generate_key	= "true"
	#mechanism 	= "0x1087"  # // may be needed with some hw
	#hmac_mechanism = "0x0251"  # // may be needed with some hw
}

entropy "seal" {
	mode = "augmentation"
}
