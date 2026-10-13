# Toolchain for the MicroJava compiler: JDK 8 (the course libraries target Java 7/8) + Apache Ant.
FROM eclipse-temurin:8-jdk-jammy

ARG ANT_VERSION=1.10.14
ARG ANT_SHA512=4e74b382dd8271f9eac9fef69ba94751fb8a8356dbd995c4d642f2dad33de77bd37d4001d6c8f4f0ef6789529754968f0c1b6376668033c8904c6ec84543332a
RUN curl -fsSLo /tmp/ant.tar.gz https://archive.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz \
 && echo "${ANT_SHA512}  /tmp/ant.tar.gz" | sha512sum -c - \
 && tar -xzf /tmp/ant.tar.gz -C /opt \
 && ln -s /opt/apache-ant-${ANT_VERSION}/bin/ant /usr/local/bin/ant \
 && rm /tmp/ant.tar.gz

WORKDIR /mjc
COPY . .

# 1. The original build: regenerate lexer (JFlex) + parser/AST (CUP), then compile.
#    build.xml's "delete" step expects logs/ to exist.
# 2. Also compile test/ (the Compiler driver lives there) into out/.
RUN mkdir -p logs \
 && ant -q repackage compile \
 && mkdir -p out \
 && javac -nowarn -encoding UTF-8 -d out -cp "lib/*" $(find src test -name '*.java') \
 && chmod +x scripts/*.sh

ENTRYPOINT ["/mjc/scripts/mjc.sh"]
