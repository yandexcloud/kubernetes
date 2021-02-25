FROM alpine:3.12 AS build

ARG CNI_VERSION=
ARG CNI_URL=https://github.com/containernetworking/plugins

RUN test -n ${CNI_VERSION}

RUN apk add \
    bash \
    coreutils \
    curl \
    git \
    go \
    upx

RUN mkdir -p $GOPATH/github.com/containernetworking/ \
    && cd $GOPATH/github.com/containernetworking/ \
    && git clone ${CNI_URL} plugins
WORKDIR $GOPATH/github.com/containernetworking/plugins
RUN git checkout -q ${CNI_VERSION}
RUN ./build_linux.sh

RUN mkdir -p /out/etc/apk && cp -r /etc/apk/* /out/etc/apk/
RUN mkdir -p /out/out
RUN apk add --no-cache --initdb -p /out tar gzip
RUN rm -rf /out/etc/apk /out/lib/apk /out/var/cache
RUN for f in $(ls bin); do upx bin/$f; done
RUN tar -czf /out/cni.tgz -C bin .

FROM scratch
COPY --from=build /out /
WORKDIR /
ENTRYPOINT ["tar", "-xvf", "/cni.tgz", "-C", "/out"]
