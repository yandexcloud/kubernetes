FROM linuxkit/alpine:a3d78322152a8b341bdaecfe182a2689fdbdee53 as alpine
RUN apk add tzdata

WORKDIR $GOPATH/src/github.com/containerd/containerd
RUN cp bin/containerd bin/ctr bin/containerd-shim bin/containerd-shim-runc-v2 /usr/bin/

RUN mkdir -p /etc/init.d && ln -s /usr/bin/service /etc/init.d/020-containerd

WORKDIR /
COPY . .

RUN mkdir -p /out/etc/apk && cp -r /etc/apk/* /out/etc/apk/
RUN apk add --no-cache --initdb -p /out \
    iptables
RUN rm -rf /out/etc/apk /out/lib/apk /out/var/cache

FROM alpine:3.12 as archiver

RUN apk add upx
RUN mkdir -p /out/usr/bin
COPY --from=alpine /usr/bin/containerd /usr/bin/ctr /usr/bin/containerd-shim /usr/bin/containerd-shim-runc-v2 /out/usr/bin/
RUN upx /out/usr/bin/containerd
RUN upx /out/usr/bin/containerd-shim
RUN upx /out/usr/bin/containerd-shim-runc-v2
RUN upx /out/usr/bin/ctr

FROM scratch
ENV PATH "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ENTRYPOINT []
WORKDIR /
COPY --from=alpine /out /
COPY --from=alpine /etc/containerd/config.toml /etc/containerd/
COPY --from=alpine /usr/share/zoneinfo/UTC /etc/localtime
COPY --from=alpine /etc/init.d/ /etc/init.d/
COPY --from=archiver /out/usr/bin/containerd /usr/bin/containerd
COPY --from=archiver /out/usr/bin/containerd-shim /usr/bin/containerd-shim
COPY --from=archiver /out/usr/bin/containerd-shim-runc-v2 /usr/bin/containerd-shim-runc-v2
COPY --from=archiver /out/usr/bin/ctr /usr/bin/ctr
COPY etc etc/
