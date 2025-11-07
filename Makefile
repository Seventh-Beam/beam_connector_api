APP_NAME = pays-connector
PKG = github.com/setldpay/pays_connector
CONNECTOR ?= mock_connect
CLOUD_RUN_SERVICE ?= pays-connector
PROJECT ?= setldpay-staging
REGION ?= europe-west2

PROTO_DIR=/work/proto
API_OUT=./api
ANDROID_OUT=./clients/android
IOS_OUT=./clients/ios
PROTO_FILES=$(PROTO_DIR)/payment/v1/payment.proto

GO := go
PROTOC := docker run --rm -v $(PWD):/work -w /work rvolosatovs/protoc

.PHONY: all build run clean test proto-gen install-tools docker-build docker-run compose-up compose-down \
	client-android-gen client-ios-gen client-gen cloud-run-deploy

clean:
	rm -rf bin
	rm -rf $(API_OUT)
	rm -rf $(ANDROID_OUT)
	rm -rf $(IOS_OUT)

install-tools:
	@echo "Installing protoc plugins (Go)..."
	$(GO) install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	$(GO) install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
	@echo "Note: For Android stubs, ensure protoc-gen-grpc-java is installed and on PATH (or use Docker-based generation in your mobile project)."

proto-gen:
	@mkdir -p $(API_OUT)
	$(PROTOC) \
		--go_out=$(API_OUT) --go_opt=paths=source_relative \
		--go-grpc_out=$(API_OUT) --go-grpc_opt=paths=source_relative \
		--proto_path $(PROTO_DIR) \
		$(PROTO_FILES)

# Generate Android client stubs (Java lite; consumable from Kotlin)
client-android-gen:
	@mkdir -p $(ANDROID_OUT)
	$(PROTOC) \
		--proto_path=/work/proto \
		--java_out=lite:$(ANDROID_OUT) \
		--grpc-java_out=lite:$(ANDROID_OUT) \
		$(PROTO_FILES)

# Generate iOS Swift client stubs via official grpc-swift Docker image
client-ios-gen:
	@mkdir -p $(IOS_OUT)
	$(PROTOC) \
			--proto_path=/work/proto \
			--swift_opt=Visibility=Public \
			--swift_out=/work/clients/ios \
			--grpc-swift_opt=Visibility=Public,Client=true,Server=false \
			--grpc-swift_out=/work/clients/ios \
			$(PROTO_FILES)

# Convenience target to generate both
client-gen: client-android-gen client-ios-gen