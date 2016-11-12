FROM ubuntu:14.04

MAINTAINER b00stfr3ak

RUN apt-get update
RUN apt-get -y install software-properties-common
RUN apt-add-repository ppa:brightbox/ruby-ng
RUN apt-get update
run apt-get -y upgrade
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
 libcurl4-openssl-dev libssl-dev zlib1g-dev apache2-threaded-dev \
 libapr1-dev libaprutil1-dev php5 apache2 mysql-server git curl \
 ruby2.1 ruby2.1-dev build-essential

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
RUN apt-get install -y apt-transport-https ca-certificates

RUN sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main > /etc/apt/sources.list.d/passenger.list'
RUN apt-get update

RUN apt-get install -y libapache2-mod-passenger

ADD /pf.conf /etc/apache2/sites-enabled/pf.conf

RUN git clone https://github.com/pentestgeek/phishing-frenzy.git /var/www/phishing-frenzy
RUN touch /etc/apache2/httpd.conf
RUN chown www-data:www-data /etc/apache2/httpd.conf

RUN gem install --no-rdoc --no-ri bundler
#RUN gem install --no-rdoc --no-ri passenger

#RUN passenger-install-apache2-module

ADD /apache2.conf /etc/apache2/apache2.conf

RUN echo "www-data ALL=(ALL) NOPASSWD: /etc/init.d/apache2 reload" >> /etc/sudoers

RUN /etc/init.d/mysql start && \
 mysqladmin -u root password "Funt1me!" && \
 mysql -uroot -pFunt1me! -e "create database pf_dev;" && \
 mysql -uroot -pFunt1me! -e "grant all privileges on pf_dev.* to 'pf_dev'@'localhost' identified by 'password';"

RUN cd /var/www/phishing-frenzy/ && bundle install && \
 /etc/init.d/mysql start && \
 bundle exec rake db:migrate && bundle exec rake db:seed

RUN cd /var/www/phishing-frenzy/ && \
 curl http://download.redis.io/releases/redis-stable.tar.gz -o redis-stable.tar.gz && \
 tar xzf redis-stable.tar.gz && rm redis-stable.tar.gz && cd redis-* && \
 make && make install && cd utils/ && ./install_server.sh

RUN cd /var/www/phishing-frenzy/ && mkdir -p tmp/pids

RUN sudo chown -R www-data:www-data /var/www/phishing-frenzy/

RUN cd /var/www/phishing-frenzy/ && /etc/init.d/mysql start && bundle exec rake templates:load

#RUN chown -R www-data:www-data /etc/apache2/sites-available/

#RUN chown -R www-data:www-data /etc/apache2/sites-enabled/
RUN rm -f /etc/apache2/sites-enabled/000-default.conf

RUN chown -R www-data:www-data /var/www/phishing-frenzy/public/uploads/

RUN chmod -R 755 /var/www/phishing-frenzy/public/uploads/

ADD /startup.sh /startup.sh

RUN chmod +x /startup.sh

CMD /startup.sh
