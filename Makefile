update_metadata:
	(cd libPhoneNumberTests && ./metadataGenerator) && \
		(cd libPhoneNumber && ./GeneratePhoneNumberHeader.sh)
