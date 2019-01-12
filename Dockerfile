# CentOS7 Minimal
FROM centos:7
# Set the local timezone
ENV TIMEZONE="America/New_York"
# Set a unique cache serial
ENV REFRESHED_AT="2019-01-12"
# Supervisor start delay
ENV SUPERVISOR_DELAY=30

# Install daemon packages
RUN yum -y install epel-release
RUN yum -y install supervisor syslog-ng cronie
# Install base packages
RUN yum -y install wget vim-enhanced net-tools rsync sudo mlocate git logrotate

# Configure Syslog-NG for use in a Docker container
RUN sed -i 's|system();|unix-stream("/dev/log");|g' /etc/syslog-ng/syslog-ng.conf

# Install newest stable MariaDB: 10.3 
RUN { echo "[mariadb]"; echo "name = MariaDB"; echo "baseurl = http://yum.mariadb.org/10.3/centos7-amd64"; \
      echo "gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB"; echo "gpgcheck=1"; \
    } | tee /etc/yum.repos.d/MariaDB-10.3.repo && yum -y install MariaDB-server MariaDB-client
# Create MySQL Start Script
RUN { echo '#!/bin/bash'; \
      echo "[[ \`pidof /usr/sbin/mysqld\` == \"\" ]] && /usr/bin/mysqld_safe &"; \
      echo "export SQL_TO_LOAD='/mysql_load_on_first_boot.sql';"; echo "while true; do"; \
      echo "if [[ \`find /var/lib/mysql -type d | wc -l\` == \"4\" ]]; then sleep 5"; \
      echo " /usr/bin/mysql -u root --password='' < \$SQL_TO_LOAD && mv \$SQL_TO_LOAD \$SQL_TO_LOAD.loaded; fi"; \
      echo "sleep 10;"; echo "done"; \
    } | tee /start-mysqld.sh && chmod a+x /start-mysqld.sh   

# Install Webtatic YUM REPO + Webtatic PHP7, 
RUN wget https://mirror.webtatic.com/yum/el7/webtatic-release.rpm && \
    yum -y localinstall webtatic-release.rpm && yum -y install php72w-cli
# Install Apache & Webtatic mod_php support
RUN yum -y install httpd mod_php72w php72w-opcache php72w-mysqli && \
    rm -rf /etc/httpd/conf.d/welcome.conf

# Create Cron start script    
#RUN { echo '#!/bin/bash'; echo 'sleep 30 && /usr/sbin/crond -n'; } | tee /start_crond.sh    
RUN { echo '#!/bin/bash'; echo '/usr/sbin/crond -n'; } | tee /start_crond.sh    
    
# Create beginning of supervisord.conf file
RUN { echo '[supervisord]';\
      echo 'nodaemon=true';\
      echo 'user=root';\
      echo 'logfile=/var/log/supervisord';\
    } | tee /etc/supervisord.conf
# Create script to add more supervisor boot-time entries
RUN { echo '#!/bin/bash'; \
      echo 'echo "[program:$1]";'; echo 'echo "process_name=$1";'; \
      echo 'echo "autostart=true";'; echo 'echo "autorestart=false";'; \
      echo 'echo "directory=/";'; echo 'echo "command=$2";'; \
      echo 'echo "startsecs=3";'; echo 'echo "priority=1";'; echo 'echo "";'; \
    } | tee /gen_sup.sh

# Create start_supervisor.sh script
RUN { echo "#!/bin/bash"; \
      echo "sleep ${SUPERVISOR_DELAY}"; \
      echo "/usr/bin/supervisord -c /etc/supervisord.conf"; \
    } | tee /start_supervisor.sh       
    
# Create different supervisor entries
RUN chmod a+x /*.sh && \
    /gen_sup.sh syslog-ng "/usr/sbin/syslog-ng --no-caps -F -p /var/run/syslogd.pid" >> /etc/supervisord.conf && \
    /gen_sup.sh crond "/start_crond.sh" >> /etc/supervisord.conf && \
    /gen_sup.sh httpd "/usr/sbin/apachectl -D FOREGROUND" >> /etc/supervisord.conf && \
    /gen_sup.sh mysqld "/start-mysqld.sh" >> /etc/supervisord.conf 

# Ensure all packages are up-to-date, then fully clean out all cache
RUN yum -y update && yum clean all && rm -rf /tmp/* && rm -rf /var/tmp/*

# Set to start the supervisor daemon on bootup
ENTRYPOINT ["/start_supervisor.sh"]