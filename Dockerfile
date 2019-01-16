# CentOS7 Minimal
FROM centos:7
# Set the local timezone
ENV TIMEZONE="America/New_York"
# Set a unique cache serial
ENV REFRESHED_AT="2019-01-14"
# Supervisor start delay
ENV SUPERVISOR_DELAY=1

# Install daemon packages# Install base packages
RUN yum -y install epel-release && yum -y install supervisor syslog-ng cronie \
    wget vim-enhanced net-tools rsync sudo mlocate git logrotate && \
# Configure Syslog-NG for use in a Docker container
    sed -i 's|system();|unix-stream("/dev/log");|g' /etc/syslog-ng/syslog-ng.conf

# Install newest stable MariaDB: 10.3 
RUN printf '[mariadb]\nname = MariaDB\nbaseurl = http://yum.mariadb.org/10.3/centos7-amd64\n\
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB\ngpgcheck=1' > /etc/yum.repos.d/MariaDB-10.3.repo && \
    yum -y install MariaDB-server MariaDB-client
# Create MySQL Start Script
RUN echo $'#!/bin/bash\n/usr/bin/sleep 5\n\
[[ `pidof /usr/sbin/mysqld` == "" ]] && /usr/bin/mysqld_safe &\nsleep 5\n\
export SQL_TO_LOAD="/mysql_load_on_first_boot.sql"\n\
while true; do\n\
  if [[ -e "$SQL_TO_LOAD" ]]; then /usr/bin/mysql -u root --password=\'\' < $SQL_TO_LOAD && mv $SQL_TO_LOAD $SQL_TO_LOAD.loaded; fi\n\
  sleep 10\n\
done\n' > /start_mysqld.sh   

# Install Webtatic YUM REPO + Webtatic PHP7, # Install Apache & Webtatic mod_php support 
RUN yum -y localinstall https://mirror.webtatic.com/yum/el7/webtatic-release.rpm && \
    yum -y install php72w-cli httpd mod_php72w php72w-opcache php72w-mysqli php72w-curl && \
    rm -rf /etc/httpd/conf.d/welcome.conf

# Create beginning of supervisord.conf file
RUN printf '[supervisord]\nnodaemon=true\nuser=root\nlogfile=/var/log/supervisord\n' > /etc/supervisord.conf && \
# Create start_httpd.sh script
    printf '#!/bin/bash\nrm -rf /run/httpd/httpd.pid\nwhile true; do\n/usr/sbin/httpd -DFOREGROUND\nsleep 10\ndone' > /start_httpd.sh && \
# Create start_supervisor.sh script
    printf '#!/bin/bash\nsleep ${SUPERVISOR_DELAY}\n/usr/bin/supervisord -c /etc/supervisord.conf' > /start_supervisor.sh && \
# Create syslog-ng start script    
    printf '#!/bin/bash\n/usr/sbin/syslog-ng --no-caps -F -p /var/run/syslogd.pid' > /start_syslog-ng.sh && \
# Create Cron start script    
    printf '#!/bin/bash\n/usr/sbin/crond -n\n' > /start_crond.sh && \
# Create script to add more supervisor boot-time entries
    echo $'#!/bin/bash \necho "[program:$1]";\necho "process_name  = $1";\n\
echo "autostart     = true";\necho "autorestart   = false";\necho "directory     = /";\n\
echo "command       = $2";\necho "startsecs     = 3";\necho "priority      = 1";\n\n' > /gen_sup.sh

# Ensure all packages are up-to-date, then fully clean out all cache
RUN chmod a+x /*.sh && yum -y update && yum clean all && rm -rf /tmp/* && rm -rf /var/tmp/*    
    
# Create different supervisor entries
RUN /gen_sup.sh httpd "/start_httpd.sh" >> /etc/supervisord.conf && \
    /gen_sup.sh syslog-ng "/start_syslog-ng.sh" >> /etc/supervisord.conf && \
    /gen_sup.sh mysqld "/start_mysqld.sh" >> /etc/supervisord.conf && \
    /gen_sup.sh crond "/start_crond.sh" >> /etc/supervisord.conf  

# Set to start the supervisor daemon on bootup
ENTRYPOINT ["/start_supervisor.sh"]