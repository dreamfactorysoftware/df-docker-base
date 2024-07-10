FROM ubuntu:24.04

RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends software-properties-common gpg-agent git curl cron zip unzip ca-certificates apt-transport-https lsof mcrypt libmcrypt-dev libreadline-dev wget sudo nginx build-essential unixodbc-dev gcc cmake jq libaio1t64 python3 python3-pip python3-setuptools python3-venv

# Install PHP Repo
RUN LANG=C.UTF-8 add-apt-repository ppa:ondrej/php -y && \
    ## Update the system
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --allow-unauthenticated \
    ## PHP Dependencies
    php8.3-common \
    php8.3-xml \
    php8.3-cli \
    php8.3-curl \
    php8.3-mysqlnd \
    php8.3-sqlite \
    php8.3-soap \
    php8.3-mbstring \
    php8.3-zip \
    php8.3-bcmath \
    php8.3-dev \
    php8.3-ldap \
    php8.3-pgsql \
    php8.3-interbase \
    php8.3-gd \
    php8.3-sybase \
    php8.3-fpm \
    php8.3-odbc \
    php8.3-pdo \
    php8.3-http \
    php8.3-raphf 

# Install PECL extensions
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --allow-unauthenticated php-pear && \
    pecl channel-update pecl.php.net && \
    pecl install mcrypt && \
    pecl install mongodb && \
    pecl install igbinary && \
    pecl install sqlsrv-5.11.1 && \
    pecl install pdo_sqlsrv-5.11.1

# Create virtual environment and install Python packages
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install munch

# Additional Drivers
RUN apt-get update && \
    echo "extension=mcrypt.so" > "/etc/php/8.3/mods-available/mcrypt.ini" && \
    phpenmod -s ALL mcrypt && \
    echo "extension=igbinary.so" > "/etc/php/8.3/mods-available/igbinary.ini" && \
    phpenmod -s ALL igbinary && \
    echo "extension=mongodb.so" > "/etc/php/8.3/mods-available/mongodb.ini" && \
    phpenmod -s ALL mongodb && \
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | tee /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y DEBIAN_FRONTEND=noninteractive apt-get install -y msodbcsql18 mssql-tools && \
    echo "extension=sqlsrv.so" > "/etc/php/8.3/mods-available/sqlsrv.ini" && \
    phpenmod -s ALL sqlsrv && \
    echo "extension=pdo_sqlsrv.so" > "/etc/php/8.3/mods-available/pdo_sqlsrv.ini" && \
    phpenmod -s ALL pdo_sqlsrv && \
    curl -sL https://deb.nodesource.com/setup_20.x | bash - && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends nodejs && \
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    chmod +x /usr/local/bin/composer && \
    echo 'sendmail_path = "/usr/sbin/ssmtp -t"' > /etc/php/8.3/cli/conf.d/mail.ini && \
    npm install -g async lodash && \
    mkdir /opt/hive && \
    cd /opt/hive && \
    curl --fail -O https://odbc-drivers.s3.amazonaws.com/apache-hive/maprhiveodbc_2.6.1.1001-2_amd64.deb && \
    dpkg -i maprhiveodbc_2.6.1.1001-2_amd64.deb && \
    test -f /opt/mapr/hiveodbc/lib/64/libmaprhiveodbc64.so && \
    rm maprhiveodbc_2.6.1.1001-2_amd64.deb && \
    export HIVE_SERVER_ODBC_DRIVER_PATH=/opt/mapr/hiveodbc/lib/64/libmaprhiveodbc64.so && \
    git clone --depth 1 https://github.com/snowflakedb/pdo_snowflake.git /opt/snowflake && \
    cd /opt/snowflake && \
    export PHP_HOME=/usr && \
    /opt/snowflake/scripts/build_pdo_snowflake.sh && \
    cp /opt/snowflake/modules/pdo_snowflake.so /usr/lib/php/20210902 && \
    cp /opt/snowflake/libsnowflakeclient/cacert.pem /etc/php/8.3/fpm/conf.d && \
    echo "extension=pdo_snowflake.so" > /etc/php/8.3/mods-available/pdo_snowflake.ini && \
    echo "pdo_snowflake.cacert=/etc/php/8.3/fpm/conf.d/cacert.pem" >> /etc/php/8.3/mods-available/pdo_snowflake.ini && \
    phpenmod pdo_snowflake && \
    rm -rf /opt/snowflake

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
