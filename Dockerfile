FROM ubuntu:bionic

RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends software-properties-common git curl cron npm zip unzip ca-certificates apt-transport-https lsof mcrypt libmcrypt-dev libreadline-dev wget sudo nginx nodejs build-essential unixodbc-dev gcc cmake

# Install PHP Repo
RUN LANG=C.UTF-8 add-apt-repository ppa:ondrej/php -y && \
    ## Update the system
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --allow-unauthenticated \
    gpg-agent \
    ## PHP Dependencies and PECL
    php7.4-common \
    php7.4-xml \
    php7.4-cli \
    php7.4-curl \
    php7.4-json \
    php7.4-mysqlnd \
    php7.4-sqlite \
    php7.4-soap \
    php7.4-mbstring \
    php7.4-zip \
    php7.4-bcmath \
    php7.4-dev \
    php7.4-ldap \
    php7.4-pgsql \
    php7.4-interbase \
    php7.4-gd \
    php7.4-sybase \
    php7.4-fpm \
    php7.4-odbc \
    php7.4-pdo \
    php7.4-json \
    php7.4-dev \
    php-pear \
    php-pecl-http \
    php-raphf \
    php-propro && \
    pecl channel-update pecl.php.net && \
    pecl install mcrypt-1.0.2 && \
    pecl install mongodb && \
    pecl install igbinary && \
    pecl install pcs-1.3.7 && \
    pecl install sqlsrv && \
    pecl install pdo_sqlsrv && \
    ## Install Python2 Bunch & Python3 Munch
    apt install -y --no-install-recommends --allow-unauthenticated python python-pip python3 python3-pip python-setuptools python3-setuptools && \
    pip install bunch && \
    pip3 install munch

# Additional Drivers
RUN apt-get update && \
    ## MCrypt 
    echo "extension=mcrypt.so" >"/etc/php/7.4/mods-available/mcrypt.ini" && \
    phpenmod -s ALL mcrypt && \
    ## IGBINARY
    echo "extension=igbinary.so" >"/etc/php/7.4/mods-available/igbinary.ini" && \
    phpenmod -s ALL igbinary && \
    ## PCS
    echo "extension=pcs.so" >"/etc/php/7.4/mods-available/pcs.ini" && \
    phpenmod -s ALL pcs && \
    ## MongoDB
    echo "extension=mongodb.so" >"/etc/php/7.4/mods-available/mongodb.ini" && \
    phpenmod -s ALL mongodb && \
    ## Install MS SQL Drivers
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/ubuntu/18.04/prod.list >/etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y DEBIAN_FRONTEND=noninteractive apt-get install -y msodbcsql17 mssql-tools && \
    echo "extension=sqlsrv.so" >"/etc/php/7.4/mods-available/sqlsrv.ini" && \
    phpenmod -s ALL sqlsrv && \
    ## DRIVERS FOR MSSQL (pdo_sqlsrv)
    echo "extension=pdo_sqlsrv.so" >"/etc/php/7.4/mods-available/pdo_sqlsrv.ini" && \
    phpenmod -s ALL pdo_sqlsrv && \
    ## Node
    curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --allow-unauthenticated nodejs && \
    ## Install Composer
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    chmod +x /usr/local/bin/composer && \
    ## Configure Sendmail
    echo 'sendmail_path = "/usr/sbin/ssmtp -t"' > /etc/php/7.4/cli/conf.d/mail.ini && \
    ## Install Async and Lodash
    npm install -g async lodash && \
    # Install Hive driver
    mkdir /opt/hive && \
    cd /opt/hive && \
    curl --fail -O https://odbc-drivers.s3.amazonaws.com/apache-hive/maprhiveodbc_2.6.1.1001-2_amd64.deb && \
    dpkg -i maprhiveodbc_2.6.1.1001-2_amd64.deb && \
    test -f /opt/mapr/hiveodbc/lib/64/libmaprhiveodbc64.so && \
    rm maprhiveodbc_2.6.1.1001-2_amd64.deb && \
    export HIVE_SERVER_ODBC_DRIVER_PATH=/opt/mapr/hiveodbc/lib/64/libmaprhiveodbc64.so && \
    # Install Hive driver - end
    # Build and install pdo_snowflake
    git clone https://github.com/snowflakedb/pdo_snowflake.git /opt/snowflake && \
    cd /opt/snowflake && \
    export PHP_HOME=/usr && \
    /opt/snowflake/scripts/build_pdo_snowflake.sh && \
    cp /opt/snowflake/modules/pdo_snowflake.so /usr/lib/php/20180731 && \
    cp /opt/snowflake/libsnowflakeclient/cacert.pem /etc/php/7.4/fpm/conf.d && \
    echo "extension=pdo_snowflake.so \n pdo_snowflake.cacert=/etc/php/7.4/fpm/conf.d/cacert.pem" > /etc/php/7.4/fpm/conf.d/20-pdo_snowflake.ini && \
    rm -rf /opt/snowflake
    # Build and install pdo_snowflake - end
    
# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
