FROM perl:5.34-buster

ENV DEBIAN_FRONTEND noninteractive
RUN apt update && apt install -y default-mysql-client \
  && apt clean \
  && cpanm --notest Term::ReadKey DBI DBD::mysql \
  && wget -q -O /usr/local/bin/innotop https://github.com/innotop/innotop/raw/master/innotop \
  && chmod u+w /usr/local/bin/innotop

ENTRYPOINT ["innotop"]
