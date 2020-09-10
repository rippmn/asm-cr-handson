FROM golang:1.15.1-alpine
ADD . /go/src/hello-bg-app
RUN go install hello-bg-app

FROM alpine:latest
COPY --from=0 /go/bin/hello-bg-app .
ENV PORT 8080
CMD ["./hello-bg-app"]
