# Payload Manager - Native PS5 ELF Daemon Makefile

# Tools
PYTHON := python3
CC     := /opt/ps5-payload-sdk/bin/prospero-clang
STRIP  := /opt/ps5-payload-sdk/bin/prospero-strip

# Paths
SDK      := /opt/ps5-payload-sdk
TARGET   := $(SDK)/target
INCLUDES := -Iinclude -I$(TARGET)/include
LIBS     := -L$(TARGET)/lib -lcurl -lmbedtls -lmbedx509 -lmbedcrypto -lmicrohttpd -lpthread -lSceNetCtl -lSceUserService -lSceSystemService -lSceAppInstUtil -lSceHttp2 -lSceSsl -lSceNet

# Source Files
SRCS := src/main.c src/payload_mgr.c src/ps5_launcher.c src/notification.c src/utils.c src/autoload.c src/app_installer.c
OBJS := $(SRCS:.c=.o)
ELF  := pldmgr.elf

# Assets
FRONTEND_DIST := frontend/dist/index.html
ASSET_HEADER  := include/assets_index_html.h
CA_HEADER     := include/assets_cacert_pem.h
MANIFEST_HEADER := include/assets_cache_appcache.h
FRONTEND_MANIFEST := frontend/dist/cache.appcache
FAVICON_SVG_HEADER := include/assets_favicon_svg.h
ICON_PNG_HEADER := include/assets_icon_png.h




# Compiler Flags
CFLAGS := -Os -Wall -ffunction-sections -fdata-sections $(INCLUDES)
LDFLAGS := -Wl,--gc-sections

all: $(ELF)

# Build the React frontend
.PHONY: frontend-build
frontend-build:
	@echo "Building frontend..."
	cd frontend && npm install && npm run build
	@VERSION=$$(grep '#define MENU_VERSION' include/pldmgr.h | awk '{print $$3}' | tr -d '"'); \
	COMMIT=$$(git rev-parse --short HEAD 2>/dev/null || echo "unknown"); \
	git diff --quiet || COMMIT="DEV"; \
	DATE=$$(date -u +"%Y-%m-%d %H:%M:%S UTC"); \
	TITLE="Payload Manager v$$VERSION by PLK ($$COMMIT, built at $$DATE)"; \
	echo "Updating title in index.html to: $$TITLE"; \
	TMP=$$(mktemp "$${TMPDIR:-/tmp}/pldmgr.XXXXXX"); \
	sed "s|\[\[TITLE_PLACEHOLDER\]\]|$$TITLE|g" frontend/dist/index.html > $$TMP; \
	mv $$TMP frontend/dist/index.html; \
	echo "Updating build date in cache.appcache to: $$DATE"; \
	TMP=$$(mktemp "$${TMPDIR:-/tmp}/pldmgr.XXXXXX"); \
	sed "s|\[\[BUILD_DATE\]\]|$$DATE|g" frontend/dist/cache.appcache > $$TMP; \
	mv $$TMP frontend/dist/cache.appcache



$(ASSET_HEADER): $(FRONTEND_DIST)
	@echo "Generating asset header..."
	$(PYTHON) tools/gen_assets.py $(FRONTEND_DIST) $(ASSET_HEADER) index_html

$(MANIFEST_HEADER): $(FRONTEND_DIST)
	@echo "Generating Manifest asset header..."
	$(PYTHON) tools/gen_assets.py $(FRONTEND_MANIFEST) $(MANIFEST_HEADER) cache_appcache

$(FAVICON_SVG_HEADER): $(FRONTEND_DIST)
	@echo "Generating Favicon SVG asset header..."
	$(PYTHON) tools/gen_assets.py frontend/dist/favicon.svg $(FAVICON_SVG_HEADER) favicon_svg

$(ICON_PNG_HEADER): $(FRONTEND_DIST)
	@echo "Generating Icon PNG asset header..."
	$(PYTHON) tools/gen_assets.py frontend/dist/icon.png $(ICON_PNG_HEADER) icon_png

$(CA_HEADER):
	@echo "Downloading CA bundle..."
	wget -O include/cacert.pem https://curl.se/ca/cacert.pem
	$(PYTHON) tools/gen_assets.py include/cacert.pem $(CA_HEADER) cacert_pem
	rm include/cacert.pem

$(FRONTEND_DIST):
	@echo "ERROR: frontend/dist/index.html not found!"
	@echo "Please run 'make frontend-build' locally on your host machine first."
	@exit 1

$(ELF): $(ASSET_HEADER) $(MANIFEST_HEADER) $(CA_HEADER) $(FAVICON_SVG_HEADER) $(ICON_PNG_HEADER) $(SRCS)
	@echo "Building $(ELF)..."
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(ELF) $(SRCS) $(LIBS)
	@echo "Stripping $(ELF)..."
	$(STRIP) $(ELF)

clean:
	rm -f $(ELF) $(ASSET_HEADER) $(MANIFEST_HEADER) $(CA_HEADER) $(FAVICON_SVG_HEADER) $(ICON_PNG_HEADER) src/*.o





dist-clean: clean
	rm -rf frontend/dist

.PHONY: all clean frontend-build dist-clean

# --- Bundle pldmgr + ps5-elfldr ---

# Define the output for your bundle
ELF_BUNDLE := pldmgr_elfldr.elf
ELFLDR_DIR := ps5-elfldr

# Target for bundle
.PHONY: bundle
bundle: $(ELF)
	@echo "Creating bundled payload..."
	@echo "1. Generating C header of PLDMGR..."
	xxd -i $(ELF) > pldmgr_elf.c

	@echo "2. Building socksrv.elf inside ps5-elfldr tools..."
	$(CC) $(CFLAGS) -c $(ELFLDR_DIR)/socksrv.c -o socksrv.o
	$(CC) $(CFLAGS) -c $(ELFLDR_DIR)/selfldr.c -o selfldr.o
	$(CC) $(CFLAGS) -c $(ELFLDR_DIR)/elfldr.c -o elfldr_sub.o
	$(CC) $(CFLAGS) -c $(ELFLDR_DIR)/pt.c -o pt.o
	$(CC) $(CFLAGS) -c $(ELFLDR_DIR)/notify.c -o notify.o
	$(CC) $(CFLAGS) -c $(ELFLDR_DIR)/uri.c -o uri.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o socksrv.elf socksrv.o selfldr.o elfldr_sub.o pt.o notify.o uri.o -lSceSsl -lSceHttp
	$(STRIP) socksrv.elf

	@echo "3. Generating C header of socksrv.elf..."
	xxd -i socksrv.elf > socksrv_elf.c

	@echo "4. Building bundled bootstrap..."
	$(CC) $(CFLAGS) -I$(ELFLDR_DIR) -c bundle_bootstrap.c -o bundle_bootstrap.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o bootstrap.elf bundle_bootstrap.o elfldr_sub.o pt.o notify.o
	$(STRIP) bootstrap.elf

	@echo "5. Generating C header of bootstrap.elf..."
	xxd -i bootstrap.elf > bootstrap_elf.c

	@echo "6. Building final pldmgr_elfldr.elf wrapper..."
	$(CC) $(CFLAGS) -I. -I$(ELFLDR_DIR) -c $(ELFLDR_DIR)/main.c -o final_main.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(ELF_BUNDLE) final_main.o elfldr_sub.o pt.o notify.o
	$(STRIP) $(ELF_BUNDLE)

	@echo "Cleaning up intermediates..."
	rm -f socksrv.o selfldr.o elfldr_sub.o pt.o notify.o uri.o socksrv.elf socksrv_elf.c pldmgr_elf.c bundle_bootstrap.o bootstrap.elf bootstrap_elf.c final_main.o
	@echo "Success! Bundled payload created at: $(ELF_BUNDLE)"
