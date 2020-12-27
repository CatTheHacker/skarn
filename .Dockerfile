FROM golang:buster as golang
WORKDIR /app
COPY . .
RUN apt -yq update \
&& apt -yq install git build-essential mime-support \
&& export VCS_REF=$(git tag --points-at HEAD) \
&& echo $VCS_REF \
&& go install -v github.com/rakyll/statik \
&& $GOPATH/bin/statik -src="./www/" \
&& go get -v . \
&& CGO_ENABLED=1 go build -ldflags "-extldflags=-static -s -w -X main.Version=$VCS_REF" -tags sqlite_omit_load_extension .

FROM alpine:latest as alpine
RUN apk --no-cache add tzdata zip ca-certificates
WORKDIR /usr/share/zoneinfo
RUN zip -r -0 /zoneinfo.zip .

FROM scratch
COPY --from=golang /app/andesite /app/andesite
ENV ZONEINFO /zoneinfo.zip
COPY --from=alpine /zoneinfo.zip /
COPY --from=alpine /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=golang /etc/mime.types /etc/mime.types

VOLUME /data
ENTRYPOINT ["/app/skarn", "--config", "/data/config.json"]
