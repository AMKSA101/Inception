FROM debian:bullseye

RUN apt update -y && apt upgrade -y \
	&& apt install vsftpd -y && \
	mkdir -p /var/run/vsftpd/empty

EXPOSE 21 21100-21110

COPY ./conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/setup-ftp.sh /usr/local/bin/setup-ftp.sh
RUN chmod +x /usr/local/bin/setup-ftp.sh

ENTRYPOINT [ "/usr/local/bin/setup-ftp.sh" ]
CMD [ "/usr/sbin/vsftpd", "/etc/vsftpd.conf" ]
