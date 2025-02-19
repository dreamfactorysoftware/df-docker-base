FROM ubuntu:24.04

RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends software-properties-common gpg-agent git curl cron zip unzip ca-certificates apt-transport-https lsof mcrypt libmcrypt-dev libreadline-dev wget sudo nginx build-essential unixodbc-dev gcc cmake jq libaio1t64 python3 python3-pip python3-setuptools python3-venv alien

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
    # Install Microsoft repository and tools with proper key
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg && \
    echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/ubuntu/24.04/prod noble main" | tee /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends unixodbc-dev && \
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
    mkdir /opt/dremio && \
    cd /opt/dremio && \
    curl --fail -O https://download.dremio.com/arrow-flight-sql-odbc-driver/arrow-flight-sql-odbc-driver-LATEST.x86_64.rpm && \
    RPM_FILE=$(ls arrow-flight-sql-odbc-driver-*.rpm) && \
    alien --to-deb "$RPM_FILE" && \
    DEB_FILE=$(ls arrow-flight-sql-odbc-driver*.deb) && \
    dpkg -i "$DEB_FILE" && \
    rm -f "$RPM_FILE" "$DEB_FILE" && \
    test -f /opt/arrow-flight-sql-odbc-driver/lib64/libarrow-odbc.so.0.9.1.168 && \
    export DREMIO_SERVER_ODBC_DRIVER_PATH=/opt/arrow-flight-sql-odbc-driver/lib64/libarrow-odbc.so.0.9.1.168 && \
    mkdir /opt/databricks && \
    cd /opt/databricks && \
    curl --fail -O https://databricks-bi-artifacts.s3.us-east-2.amazonaws.com/simbaspark-drivers/odbc/2.8.2/SimbaSparkODBC-2.8.2.1013-Debian-64bit.zip && \
    unzip -q SimbaSparkODBC-2.8.2.1013-Debian-64bit.zip && \
    rm -f SimbaSparkODBC-2.8.2.1013-Debian-64bit.zip && \
    rm -rf docs/ && \
    dpkg -i simbaspark_2.8.2.1013-2_amd64.deb && \
    test -f /opt/simba/spark/lib/64/libsparkodbc_sb64.so && \
    rm simbaspark_2.8.2.1013-2_amd64.deb && \
    export DATABRICKS_SERVER_ODBC_DRIVER_PATH=/opt/simba/spark/lib/64/libsparkodbc_sb64.so && \
    git clone --depth 1 https://github.com/snowflakedb/pdo_snowflake.git /opt/snowflake && \
    cd /opt/snowflake && \
    export PHP_HOME=/usr && \
    /opt/snowflake/scripts/build_pdo_snowflake.sh && \
    cp /opt/snowflake/modules/pdo_snowflake.so /usr/lib/php/20230831/ && \
    cp /opt/snowflake/libsnowflakeclient/cacert.pem /etc/php/8.3/fpm/conf.d && \
    echo "extension=pdo_snowflake.so" > /etc/php/8.3/mods-available/pdo_snowflake.ini && \
    echo "pdo_snowflake.cacert=/etc/php/8.3/fpm/conf.d/cacert.pem" >> /etc/php/8.3/mods-available/pdo_snowflake.ini && \
    phpenmod pdo_snowflake && \
    rm -rf /opt/snowflake

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
