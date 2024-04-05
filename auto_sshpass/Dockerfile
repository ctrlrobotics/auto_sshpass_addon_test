ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

RUN apk add --no-cache jq vim curl tzdata openssh sshpass

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]