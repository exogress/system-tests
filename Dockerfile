FROM ruby:3.0.0-buster

RUN apt update && apt install -y gnupg && \
    curl -s https://apt.exogress.com/KEY.gpg | apt-key add - && \
    echo "deb https://apt.exogress.com/ /" > /etc/apt/sources.list.d/exogress.list && \
    apt update && apt install -y exogress

ADD . /code
WORKDIR /code

RUN bundle install

CMD bundle exec cucumber
