FROM ubuntu:24.04

# Install basic dependencies
RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    software-properties-common \
    curl \
    unzip \
    alien \
    unixodbc-dev \
    gpg-agent \
    ca-certificates \
    apt-transport-https \
    libsasl2-modules-gssapi-mit \
    git \
    cron \
    zip \
    lsof \
    mcrypt \
    libmcrypt-dev \
    libreadline-dev \
    wget \
    sudo \
    nginx \
    build-essential \
    gcc \
    cmake \
    jq

# Install PHP Repo
RUN LANG=C.UTF-8 add-apt-repository ppa:ondrej/php -y && \
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
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
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends php-pear && \
    pecl channel-update pecl.php.net && \
    pecl install mcrypt && \
    pecl install mongodb && \
    pecl install igbinary && \
    pecl install sqlsrv-5.11.1 && \
    pecl install pdo_sqlsrv-5.11.1

# Install Python and required packages
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment and install Python packages
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install munch

# Install Node.js
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash - && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends nodejs && \
    npm install -g async lodash

# Configure PHP extensions
RUN echo "extension=mcrypt.so" > "/etc/php/8.3/mods-available/mcrypt.ini" && \
    phpenmod -s ALL mcrypt && \
    echo "extension=igbinary.so" > "/etc/php/8.3/mods-available/igbinary.ini" && \
    phpenmod -s ALL igbinary && \
    echo "extension=mongodb.so" > "/etc/php/8.3/mods-available/mongodb.ini" && \
    phpenmod -s ALL mongodb && \
    echo "extension=sqlsrv.so" > "/etc/php/8.3/mods-available/sqlsrv.ini" && \
    phpenmod -s ALL sqlsrv && \
    echo "extension=pdo_sqlsrv.so" > "/etc/php/8.3/mods-available/pdo_sqlsrv.ini" && \
    phpenmod -s ALL pdo_sqlsrv

# Install MS SQL Drivers
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | tee /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y DEBIAN_FRONTEND=noninteractive apt-get install -y msodbcsql18 mssql-tools

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    chmod +x /usr/local/bin/composer && \
    echo 'sendmail_path = "/usr/sbin/ssmtp -t"' > /etc/php/8.3/cli/conf.d/mail.ini

# Install Dremio ODBC driver
RUN cd /opt && \
    echo "Downloading Dremio driver..." && \
    curl -v -L --fail -O https://download.dremio.com/arrow-flight-sql-odbc-driver/arrow-flight-sql-odbc-driver-LATEST.x86_64.rpm && \
    alien --to-deb arrow-flight-sql-odbc-driver-LATEST.x86_64.rpm && \
    dpkg -i arrow-flight-sql-odbc-driver_*.deb && \
    rm -rf arrow-flight-sql-odbc-driver-LATEST.x86_64.rpm arrow-flight-sql-odbc-driver_*.deb && \
    echo "Verifying installation..." && \
    test -f /opt/arrow-flight-sql-odbc-driver/lib64/libarrow-odbc.so.0.9.5.470 && \
    export DREMIO_SERVER_ODBC_DRIVER_PATH=/opt/arrow-flight-sql-odbc-driver/lib64/libarrow-odbc.so.0.9.5.470

# Install Databricks ODBC driver
RUN cd /opt && \
    curl --fail -O https://databricks-bi-artifacts.s3.us-east-2.amazonaws.com/simbaspark-drivers/odbc/2.8.2/SimbaSparkODBC-2.8.2.1013-Debian-64bit.zip && \
    unzip -q SimbaSparkODBC-2.8.2.1013-Debian-64bit.zip && \
    echo "Installing Databricks driver..." && \
    dpkg -i simbaspark_2.8.2.1013-2_amd64.deb && \
    rm -rf SimbaSparkODBC-2.8.2.1013-Debian-64bit.zip docs/ simbaspark_2.8.2.1013-2_amd64.deb && \
    echo "Verifying installation..." && \
    test -f /opt/simba/spark/lib/64/libsparkodbc_sb64.so && \
    export DATABRICKS_SERVER_ODBC_DRIVER_PATH=/opt/simba/spark/lib/64/libsparkodbc_sb64.so

# Install Snowflake PDO driver
RUN git clone --depth 1 https://github.com/snowflakedb/pdo_snowflake.git /opt/snowflake && \
    cd /opt/snowflake && \
    export PHP_HOME=/usr && \
    /opt/snowflake/scripts/build_pdo_snowflake.sh && \
    cp /opt/snowflake/modules/pdo_snowflake.so /usr/lib/php/20230831/ && \
    cp /opt/snowflake/libsnowflakeclient/cacert.pem /etc/php/8.3/fpm/conf.d && \
    echo "extension=pdo_snowflake.so" > /etc/php/8.3/mods-available/pdo_snowflake.ini && \
    echo "pdo_snowflake.cacert=/etc/php/8.3/fpm/conf.d/cacert.pem" >> /etc/php/8.3/mods-available/pdo_snowflake.ini && \
    phpenmod pdo_snowflake && \
    rm -rf /opt/snowflake

# Install SAP HANA Client
RUN mkdir -p /opt/hana/lib && \
    cd /opt/hana/lib && \
    echo "Downloading SAP HANA client library..." && \
    curl -L "https://odbc-drivers.s3.us-east-1.amazonaws.com/sap-hana/libodbcHDB.so" -o libodbcHDB.so && \
    echo "/opt/hana/lib" > /etc/ld.so.conf.d/sap.conf && \
    ldconfig

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
