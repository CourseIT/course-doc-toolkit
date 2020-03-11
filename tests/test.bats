#!/usr/bin/env bats

[ -n "${DOCKER_IMAGE_NAME_TO_TEST}" ] || export DOCKER_IMAGE_NAME_TO_TEST=lihame/course-doc

@test "Image build successful" {
  docker build -t "${DOCKER_IMAGE_NAME_TO_TEST}" "${BATS_TEST_DIRNAME}/../"
}

@test "asciidoctor version ${ASCIIDOCTOR_VERSION} is installed" {
  docker run -t --rm "${DOCKER_IMAGE_NAME_TO_TEST}" asciidoctor -v \
    | grep "Asciidoctor" | grep "${ASCIIDOCTOR_VERSION}"
}

@test "DejaVu and PT fonts are installed" {
  docker run -t --rm "${DOCKER_IMAGE_NAME_TO_TEST}" fc-list "DejaVu Sans"
  docker run -t --rm "${DOCKER_IMAGE_NAME_TO_TEST}" fc-list "PT Sans"
}

@test "asciidoctor-fopub is installed" {
  docker run -t --rm "${DOCKER_IMAGE_NAME_TO_TEST}" which fopub
}

@test "Plant UML is installed" {
  docker run -t --rm "${DOCKER_IMAGE_NAME_TO_TEST}" which plantuml
}

@test "Saxon is installed" {
  docker run -t --rm "${DOCKER_IMAGE_NAME_TO_TEST}" which saxon
}

@test "pdf-diff is installed" {
  docker run -t --rm "${DOCKER_IMAGE_NAME_TO_TEST}" which pdf-diff
}

@test "OpenAPI 3 Generator is installed" {
  docker run -t --rm "${DOCKER_IMAGE_NAME_TO_TEST}" which og
}

@test "make is installed and in the path" {
  docker run -t --rm "${DOCKER_IMAGE_NAME_TO_TEST}" which make
}

@test "curl is installed and in the path" {
  docker run -t --rm "${DOCKER_IMAGE_NAME_TO_TEST}" which curl
}

@test "bash is installed and in the path" {
  docker run -t --rm "${DOCKER_IMAGE_NAME_TO_TEST}" which bash
}

@test "Java is installed, in the path and executable" {
  docker run -t --rm "${DOCKER_IMAGE_NAME_TO_TEST}" which java
  docker run -t --rm "${DOCKER_IMAGE_NAME_TO_TEST}" java -version
}

@test "Python 3 is installed, in the path and executable" {
  docker run -t --rm "${DOCKER_IMAGE_NAME_TO_TEST}" which python3
  docker run -t --rm "${DOCKER_IMAGE_NAME_TO_TEST}" python3 --version
}

@test "Can generate a PDF document with fopub" {
  docker run -t --rm -v "${BATS_TEST_DIRNAME}"/resources:/documents "${DOCKER_IMAGE_NAME_TO_TEST}" \
    fopub -t ./docbook-xsl ./asciidoctor/sample.xml
}

@test "Can generate a PNG file with Plant UML" {
  docker run -t --rm -v "${BATS_TEST_DIRNAME}"/resources:/documents "${DOCKER_IMAGE_NAME_TO_TEST}" \
    plantuml ./plantuml/sample.pu
}

@test "ajv-cli validates data from JSON-schema" {
docker run -t --rm -v "${BATS_TEST_DIRNAME}"/resources:/documents "${DOCKER_IMAGE_NAME_TO_TEST}" \
    ajv compile -s ./ajv-cli/_current-schema.json
}

