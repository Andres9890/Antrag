NAME := Antrag
PLATFORM := iphoneos
SCHEMES := Antrag
TMP := $(TMPDIR)/$(NAME)
STAGE := $(TMP)/stage
APP := $(TMP)/Build/Products/Release-$(PLATFORM)
LDID := $(shell command -v ldid 2> /dev/null)

.PHONY: all clean $(SCHEMES) check-ldid

all: check-ldid $(SCHEMES)

check-ldid:
ifndef LDID
	$(error "ldid not found. Install with: brew install ldid")
endif

clean:
	rm -rf $(TMP)
	rm -rf packages
	rm -rf Payload

$(SCHEMES): check-ldid
	xcodebuild \
	    -project Antrag.xcodeproj \
	    -scheme "$@" \
	    -configuration Release \
	    -arch arm64 \
	    -sdk $(PLATFORM) \
	    -derivedDataPath $(TMP) \
	    -skipPackagePluginValidation \
	    CODE_SIGNING_ALLOWED=NO \
	    ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO

	rm -rf Payload
	rm -rf $(STAGE)/
	mkdir -p $(STAGE)/Payload

	mv "$(APP)/$@.app" "$(STAGE)/Payload/$@.app"

	# Copy dependencies if they exist
	cp deps/* "$(STAGE)/Payload/$@.app/" 2>/dev/null || true

	# Remove existing code signature
	rm -rf "$(STAGE)/Payload/$@.app/_CodeSignature"
	
	# Fake sign with TrollStore entitlements using ldid
	$(LDID) -S"$(STAGE)/Payload/$@.app/Antrag.entitlements" "$(STAGE)/Payload/$@.app/$@"
	
	ln -sf "$(STAGE)/Payload" Payload
	
	mkdir -p packages
	
	# Create both .ipa and .tipa for TrollStore
	zip -r9 "packages/$@.ipa" Payload
	cp "packages/$@.ipa" "packages/$@.tipa"
	
	@echo ""
	@echo "Built successfully!"
	@echo "Regular IPA: packages/$@.ipa"
	@echo "TrollStore TIPA: packages/$@.tipa"
	@echo ""
	@echo "For TrollStore installation:"
	@echo "   1. Transfer the .tipa file to your device"
	@echo "   2. Open in TrollStore to install with elevated privileges"
	@echo ""