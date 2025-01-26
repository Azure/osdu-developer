# docker buildx bake <service>
# Set to "true" to build for arm64
variable "BUILD_ARM" {
    default = "auto"
}

function "platforms" {
    params = []
    result = equal(BUILD_ARM, "true") ? ["linux/amd64", "linux/arm64"] : ["linux/amd64"]
}

variable "REGISTRY" {}

group "default" {
    targets = [
        "partition",
        "entitlements",
        "legal",
        "schema",
        "storage",
        "file",
        "indexer",
        "indexer-queue",
        "search",
        "crs-catalog",
        "crs-conversion",
        "unit"
    ]
}

target "partition" {
    context = "."
    dockerfile = "Dockerfile-java"
    args = {
        SERVICE_PATH = "./core/partition"
    }
    platforms = platforms()
    tags = ["${REGISTRY}partition"]
    output = ["type=image,push=true"]
}

target "entitlements" {
    context = "."
    dockerfile = "Dockerfile-java"
    args = {
        SERVICE_PATH = "./core/entitlements"
        SKIP_TESTS = "true"
    }
    platforms = platforms()
    tags = ["${REGISTRY}entitlements"]
    output = ["type=image,push=true"]
}

target "legal" {
    context = "."
    dockerfile = "Dockerfile-java"
    args = {
        SERVICE_PATH = "./core/legal"
    }
    platforms = platforms()
    tags = ["${REGISTRY}legal"]
    output = ["type=image,push=true"]
}

target "schema" {
    context = "."
    dockerfile = "Dockerfile-java"
    args = {
        SERVICE_PATH = "./core/schema"
    }
    platforms = platforms()
    tags = ["${REGISTRY}schema"]
    output = ["type=image,push=true"]
}

target "storage" {
    context = "."
    dockerfile = "Dockerfile-java"
    args = {
        SERVICE_PATH = "./core/storage"
    }
    platforms = platforms()
    tags = ["${REGISTRY}storage"]
    output = ["type=image,push=true"]
}

target "file" {
    context = "."
    dockerfile = "Dockerfile-java"
    args = {
        SERVICE_PATH = "./core/file"
    }
    platforms = platforms()
    tags = ["${REGISTRY}file"]
    output = ["type=image,push=true"]
}

target "indexer" {
    context = "."
    dockerfile = "Dockerfile-java"
    args = {
        SERVICE_PATH = "./core/indexer"
    }
    platforms = platforms()
    tags = ["${REGISTRY}indexer"]
    output = ["type=image,push=true"]
}

target "indexer-queue" {
    context = "."
    dockerfile = "Dockerfile-java"
    args = {
        SERVICE_PATH = "./core/indexer-queue"
    }
    platforms = platforms()
    tags = ["${REGISTRY}indexer-queue"]
    output = ["type=image,push=true"]
}

target "search" {
    context = "."
    dockerfile = "Dockerfile-java"
    args = {
        SERVICE_PATH = "./core/search"
        INCLUDE_MODULES_OPT = "-pl search-core,provider/search-azure"
    }
    platforms = platforms()
    tags = ["${REGISTRY}search"]
    output = ["type=image,push=true"]
}

target "crs-catalog" {
    context = "."
    dockerfile = "Dockerfile-java"
    args = {
        SERVICE_PATH = "./core/crs-catalog"
        EXTRA_FILES = "data/crs_catalog_v2.json"
    }
    platforms = platforms()
    tags = ["${REGISTRY}crs-catalog"]
    output = ["type=image,push=true"]
}

target "crs-conversion" {
    context = "."
    dockerfile = "Dockerfile-java"
    args = {
        SERVICE_PATH = "./core/crs-conversion"
        EXTRA_FILES = "apachesis_setup"
    }
    platforms = platforms()
    tags = ["${REGISTRY}crs-conversion"]
    output = ["type=image,push=true"]
}

target "unit" {
    context = "."
    dockerfile = "Dockerfile-java"
    args = {
        SERVICE_PATH = "./core/unit"
        EXTRA_FILES = "data/unit_catalog_v2.json"
    }
    platforms = platforms()
    tags = ["${REGISTRY}unit"]
    output = ["type=image,push=true"]
} 