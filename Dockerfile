FROM debian:stretch

RUN apt-get update
RUN apt-get install siege -y

