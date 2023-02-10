FROM ubuntu:22.04

RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends software-properties-common gpg-agent git curl cron zip unzip ca-certificates apt-transport-https lsof mcrypt libmcrypt-dev libreadline-dev wget sudo nginx build-essential unixodbc-dev gcc cmake

# Install PHP Repo
RUN LANG=C.UTF-8 add-apt-repository ppa:ondrej/php -y && \
    ## Update the system
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --allow-unauthenticated \
    ## PHP Dependencies
    php8.1-common \
    php8.1-xml \
    php8.1-cli \
    php8.1-curl \
    php8.1-mysqlnd \
    php8.1-sqlite \
    php8.1-soap \
    php8.1-mbstring \
    php8.1-zip \
    php8.1-bcmath \
    php8.1-dev \
    php8.1-ldap \
    php8.1-pgsql \
    php8.1-interbase \
    php8.1-gd \
    php8.1-sybase \
    php8.1-fpm \
    php8.1-odbc \
    php8.1-pdo \
    php8.1-dev \
    php8.1-http \
    php8.1-raphf

    ## PECL
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --allow-unauthenticated php-pear && \
    pecl channel-update pecl.php.net && \
    pecl install mcrypt && \
    pecl install mongodb && \
    pecl install igbinary && \
    pecl install sqlsrv && \
    pecl install pdo_sqlsrv

    ## Install Python2 Bunch & Python3 Munch
RUN apt-get update && apt install -y --no-install-recommends --allow-unauthenticated python2 python3 python3-pip python-setuptools python3-setuptools && \
    wget https://bootstrap.pypa.io/pip/2.7/get-pip.py && \
    python2 get-pip.py && \
    pip2 install bunch && \
    pip3 install munch

# Additional Drivers
RUN apt-get update && \
    ## MCrypt 
    echo "extension=mcrypt.so" >"/etc/php/8.1/mods-available/mcrypt.ini" && \
    phpenmod -s ALL mcrypt && \
    ## IGBINARY
    echo "extension=igbinary.so" >"/etc/php/8.1/mods-available/igbinary.ini" && \
    phpenmod -s ALL igbinary && \
    ## MongoDB
    echo "extension=mongodb.so" >"/etc/php/8.1/mods-available/mongodb.ini" && \
    phpenmod -s ALL mongodb && \
    ## Install MS SQL Drivers
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list >/etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y DEBIAN_FRONTEND=noninteractive apt-get install -y msodbcsql18 mssql-tools && \
    echo "extension=sqlsrv.so" >"/etc/php/8.1/mods-available/sqlsrv.ini" && \
    phpenmod -s ALL sqlsrv && \
    ## DRIVERS FOR MSSQL (pdo_sqlsrv)
    echo "extension=pdo_sqlsrv.so" >"/etc/php/8.1/mods-available/pdo_sqlsrv.ini" && \
    phpenmod -s ALL pdo_sqlsrv && \
    ## Node
    curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --allow-unauthenticated nodejs && \
    ## Install Composer
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    chmod +x /usr/local/bin/composer && \
    ## Configure Sendmail
    echo 'sendmail_path = "/usr/sbin/ssmtp -t"' > /etc/php/8.1/cli/conf.d/mail.ini && \
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
    git clone --depth 1 https://github.com/snowflakedb/pdo_snowflake.git /opt/snowflake && \
    cd /opt/snowflake && \
    export PHP_HOME=/usr && \
    /opt/snowflake/scripts/build_pdo_snowflake.sh && \
    cp /opt/snowflake/modules/pdo_snowflake.so /usr/lib/php/20210902 && \
    cp /opt/snowflake/libsnowflakeclient/cacert.pem /etc/php/8.1/fpm/conf.d && \
    echo "extension=pdo_snowflake.so" > /etc/php/8.1/mods-available/pdo_snowflake.ini && \
    echo "pdo_snowflake.cacert=/etc/php/8.1/fpm/conf.d/cacert.pem" >> /etc/php/8.1/mods-available/pdo_snowflake.ini && \
    phpenmod pdo_snowflake && \
    rm -rf /opt/snowflake
    # Build and install pdo_snowflake - end
    
# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
