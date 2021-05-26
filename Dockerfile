ARG IMAGE=alpine:latest

# first image to download qemu and make it executable
FROM alpine AS qemu
ARG QEMU=x86_64
ARG QEMU_VERSION=4.2.0-6
ARG VERSION=9-1-07
ADD https://github.com/multiarch/qemu-user-static/releases/download/v${QEMU_VERSION}/qemu-${QEMU}-static /usr/bin/qemu-${QEMU}-static
ADD https://www.picapport.de/download/${VERSION}/picapport-headless.jar /picapport-headless.jar
RUN chmod +x /usr/bin/qemu-${QEMU}-static

# second image to deliver the picapport container
FROM ${IMAGE}
ARG QEMU=x86_64
COPY --from=qemu /usr/bin/qemu-${QEMU}-static /usr/bin/qemu-${QEMU}-static
ARG ARCH=amd64

ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL
ARG VERSION

ENV PICAPPORT_PORT=80
ENV PICAPPORT_LANG=en
ENV PICAPPORT_LOG=WARNING
ENV XMS=256m
ENV XMX=2048m

RUN apk add --update --no-cache tini openjdk8-jre && \
    mkdir -p /opt/picapport/.picapport && \
    printf "%s\n%s\n%s\n" "server.port=$PICAPPORT_PORT" "robot.root.0.path=/srv/photos" "foto.jpg.usecache=2" > /opt/picapport/.picapport/picapport.properties

COPY --from=qemu /picapport-headless.jar /opt/picapport/picapport-headless.jar
WORKDIR /opt/picapport
EXPOSE ${PICAPPORT_PORT}

ENTRYPOINT tini -- java -Xms$XMS -Xmx$XMX -DTRACE=$PICAPPORT_LOG -Duser.language=$PICAPPORT_LANG -Duser.home=/opt/picapport -jar picapport-headless.jar

LABEL de.whatever4711.picapport.version=$VERSION \
    de.whatever4711.picapport.name="PicApport" \
    de.whatever4711.picapport.docker.cmd="docker run -d -p 8080:80 whatever4711/picapport" \
    de.whatever4711.picapport.vendor="Marcel Grossmann" \
    de.whatever4711.picapport.architecture=$ARCH \
    de.whatever4711.picapport.vcs-ref=$VCS_REF \
    de.whatever4711.picapport.vcs-url=$VCS_URL \
    de.whatever4711.picapport.build-date=$BUILD_DATE
