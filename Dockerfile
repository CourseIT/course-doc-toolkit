FROM alpine:3.11.3

# Asciidoctor versions
ARG asciidoctor_version=2.0.10
ARG asciidoctor_confluence_version=0.0.2
ARG asciidoctor_pdf_version=1.5.0.rc.3
ARG asciidoctor_diagram_version=1.5.19
ARG asciidoctor_epub3_version=1.5.0.alpha.12
ARG asciidoctor_mathematical_version=0.3.1
ARG asciidoctor_revealjs_version=3.1.0
ARG kramdown_asciidoc_version=1.0.1

# PlantUML version 
ARG plantuml_version=1.2019.13

# Saxon version
ARG saxon_version=9-9-1-6

ENV ASCIIDOCTOR_VERSION=${asciidoctor_version} \
  ASCIIDOCTOR_CONFLUENCE_VERSION=${asciidoctor_confluence_version} \
  ASCIIDOCTOR_PDF_VERSION=${asciidoctor_pdf_version} \
  ASCIIDOCTOR_DIAGRAM_VERSION=${asciidoctor_diagram_version} \
  ASCIIDOCTOR_EPUB3_VERSION=${asciidoctor_epub3_version} \
  ASCIIDOCTOR_MATHEMATICAL_VERSION=${asciidoctor_mathematical_version} \
  ASCIIDOCTOR_REVEALJS_VERSION=${asciidoctor_revealjs_version} \
  KRAMDOWN_ASCIIDOC_VERSION=${kramdown_asciidoc_version} \
  PLANTUML_VERSION=${plantuml_version} \
  SAXON_VERSION=${saxon_version}

# Installing package required for the runtime of
# any of the asciidoctor-* functionnalities
RUN apk update && apk add --no-cache \
	bash \
	curl \
	ca-certificates \
	cmake \
    	findutils \
	fontconfig \
	gcc \
	g++ \
	git \
	graphviz \
	inotify-tools \
  jq \
	make \
	nano \
	openjdk11 \
	poppler-utils \
	python3-dev \
	py3-lxml \
	py3-pillow \
	py3-setuptools \
	ruby \
	ruby-mathematical \
	ruby-rake \
	ttf-dejavu \
	unzip \
	wget \
	which

# Installing Ruby Gems needed in the image
# including asciidoctor itself
RUN apk add --no-cache --virtual .rubymakedepends \
	build-base \
	libxml2-dev \
	ruby-dev \
  && gem install --no-document \
	"asciidoctor:${ASCIIDOCTOR_VERSION}" \
	"asciidoctor-confluence:${ASCIIDOCTOR_CONFLUENCE_VERSION}" \
	"asciidoctor-diagram:${ASCIIDOCTOR_DIAGRAM_VERSION}" \
	"asciidoctor-epub3:${ASCIIDOCTOR_EPUB3_VERSION}" \
	"asciidoctor-mathematical:${ASCIIDOCTOR_MATHEMATICAL_VERSION}" \
	asciimath \
	"asciidoctor-pdf:${ASCIIDOCTOR_PDF_VERSION}" \
	"asciidoctor-revealjs:${ASCIIDOCTOR_REVEALJS_VERSION}" \
	coderay \
	epubcheck-ruby:4.2.2.0 \
	haml \
	kindlegen:3.0.5 \
	"kramdown-asciidoc:${KRAMDOWN_ASCIIDOC_VERSION}" \
	rouge \
	slim \
	thread_safe \
	tilt \
  && apk del -r --no-cache .rubymakedepends

# Installing Python dependencies for additional
# functionnalities as diagrams or syntax highligthing
RUN apk add --no-cache --virtual .pythonmakedepends \
	build-base \
	python3-dev \
	py3-pip \
  && pip3 install --no-cache-dir \
	actdiag \
	'blockdiag[pdf]' \
	nwdiag \
	seqdiag \
	psycopg2-binary \
  && apk del -r --no-cache .pythonmakedepends

# Installing csvkit, imagemagick, pdf-diff, nodejs, yamllint and npm
RUN pip3 install --upgrade pip setuptools csvkit pdf-diff yamllint \
  && apk add --update --no-cache imagemagick nodejs nodejs-npm

# Installing PlantUML
RUN mkdir /usr/local/bin/plantuml/ \
  && curl -L https://sourceforge.net/projects/plantuml/files/plantuml.${PLANTUML_VERSION}.jar/download -o /usr/local/bin/plantuml/plantuml.jar \
  && echo 'alias plantuml="java -Djava.awt.headless=true -jar /usr/local/bin/plantuml/plantuml.jar"'
ADD /files/scripts/plantuml /usr/local/bin/plantuml/
RUN chmod +x /usr/local/bin/plantuml/plantuml
ENV PATH="$PATH:/usr/local/bin/plantuml/"


# Installing Saxon
RUN curl -L https://www.saxonica.com/download/SaxonEE${SAXON_VERSION}J.zip -o /usr/local/SaxonEE${SAXON_VERSION}J.zip \
  && cd /usr/local/ \
  && unzip SaxonEE${SAXON_VERSION}J.zip -d /usr/local/bin/saxon/
ENV CLASSPATH="/usr/local/bin/saxon/saxon9ee.jar:/usr/local/bin/saxon/icu4j-59_1.jar:/usr/local/bin/saxon/saxon9-sql.jar"
ADD /files/scripts/saxon /usr/local/bin/saxon/
RUN chmod +x /usr/local/bin/saxon/saxon
ENV PATH="$PATH:/usr/local/bin/saxon/"

# Installing asciidoctor-fopub
RUN cd /usr/local \
  && git clone --depth=1 https://github.com/asciidoctor/asciidoctor-fopub.git \
  && cd /usr/local/asciidoctor-fopub \
  && ./gradlew -p "/usr/local/asciidoctor-fopub" -q -u installDist \
  && cp -r /usr/local/asciidoctor-fopub/ /usr/local/bin/ \
  && chmod +x /usr/local/bin/asciidoctor-fopub/fopub \
  && rm -r /usr/local/asciidoctor-fopub/
ENV PATH="$PATH:/usr/local/bin/asciidoctor-fopub/"

# Installing ajv-cli, OpenAPI 3 Generator and hbs-cli
RUN npm install -g --unsafe-perm=true --allow-root ajv-cli openapi3-generator hbs-cli nunjucks-cli

# Installing tidy-html5
RUN cd /usr/local \
  && git clone --depth=1 https://github.com/htacg/tidy-html5.git \
  && cd /usr/local/tidy-html5/build/cmake \
  && cmake ../.. -DCMAKE_BUILD_TYPE=Release \
  && make \
  && make install

# Installing PT font family
ADD /files/fonts/ /usr/share/fonts/truetype/paratype/

ADD /files/cpdf /usr/local/bin/
RUN chmod +x /usr/local/bin/cpdf

ADD /tests/resources/docbook /usr/local/bin/docbook
ADD /tests/resources/docbook-xsl /usr/local/bin/docbook-xsl
ADD /files/main.js /usr/lib/node_modules/nunjucks-cli

# Command wrappers
ADD /files/scripts/a2pdfs /usr/local/bin/wrappers/
ADD /files/scripts/vjschema /usr/local/bin/wrappers/
ADD /files/scripts/diff2pdf /usr/local/bin/wrappers/
RUN chmod +x /usr/local/bin/wrappers/a2pdfs \
  && chmod +x /usr/local/bin/wrappers/vjschema \
  && chmod +x /usr/local/bin/wrappers/diff2pdf \
  && chmod +x /usr/lib/node_modules/nunjucks-cli/main.js
ENV PATH="$PATH:/usr/local/bin/wrappers/"

WORKDIR /documents
VOLUME /documents

CMD ["/bin/bash"]
