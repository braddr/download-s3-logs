DMD=dmd
OUTPUT_DIR=obj

DFLAGS=-m64 -gc

LIBS=-L-lcurl -L-lcrypto

ALL_APPS=download-s3-logs
ALL_APPS_OUTPUT=$(addprefix $(OUTPUT_DIR)/,$(ALL_APPS))

LOGS_SRC=$(addprefix src/,download_s3_logs.d config.d s3.d aws.d)

all: $(ALL_APPS_OUTPUT)

.PHONY: $(OUTPUT_DIR)
$(OUTPUT_DIR):
	@if [ ! -d "$(OUTPUT_DIR)" ]; then echo "creating $(OUTPUT_DIR)"; mkdir -p $(OUTPUT_DIR); fi

$(OUTPUT_DIR)/download-s3-logs: $(OUTPUT_DIR) $(LOGS_SRC)
	$(DMD) $(DFLAGS) -of$@ $(LOGS_SRC) $(LIBS)

clean:
	rm -f $(OUTPUT_DIR)/*.o $(ALL_APPS_OUTPUT)

