FROM ubuntu:xenial

RUN apt-get update -y && apt-get install -y --no-install-recommends software-properties-common git curl cron npm zip unzip ca-certificates apt-transport-https lsof mcrypt libmcrypt-dev libreadline-dev wget sudo nginx nodejs build-essential unixodbc-dev

# Install PHP Repo
RUN LANG=C.UTF-8 add-apt-repository ppa:ondrej/php -y && \
    ## Update the system
    apt-get update && apt-get install -y --no-install-recommends --allow-unauthenticated \
    ## PHP Dependencies and PECL
    php7.3-common \
    php7.3-xml \
    php7.3-cli \
    php7.3-curl \
    php7.3-json \
    php7.3-mysqlnd \
    php7.3-sqlite \
    php7.3-soap \
    php7.3-mbstring \
    php7.3-zip \
    php7.3-bcmath \
    php7.3-dev \
    php7.3-ldap \
    php7.3-pgsql \
    php7.3-interbase \
    php7.3-gd \
    php7.3-sybase \
    php7.3-fpm \
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
    echo "extension=mcrypt.so" >"/etc/php/7.3/mods-available/mcrypt.ini" && \
    phpenmod -s ALL mcrypt && \
    ## IGBINARY
    echo "extension=igbinary.so" >"/etc/php/7.3/mods-available/igbinary.ini" && \
    phpenmod -s ALL igbinary && \
    ## PCS
    echo "extension=pcs.so" >"/etc/php/7.3/mods-available/pcs.ini" && \
    phpenmod -s ALL pcs && \
    ## MongoDB
    echo "extension=mongodb.so" >"/etc/php/7.3/mods-available/mongodb.ini" && \
    phpenmod -s ALL mongodb && \
    ## Install MS SQL Drivers
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list >/etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql17 mssql-tools && \
    echo "extension=sqlsrv.so" >"/etc/php/7.3/mods-available/sqlsrv.ini" && \
    phpenmod -s ALL sqlsrv && \
    ## DRIVERS FOR MSSQL (pdo_sqlsrv)
    echo "extension=pdo_sqlsrv.so" >"/etc/php/7.3/mods-available/pdo_sqlsrv.ini" && \
    phpenmod -s ALL pdo_sqlsrv && \
    ## Node
    curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y --no-install-recommends --allow-unauthenticated nodejs && \
    ## Install Composer
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    chmod +x /usr/local/bin/composer && \
    ## Configure Sendmail
    echo 'sendmail_path = "/usr/sbin/ssmtp -t"' > /etc/php/7.3/cli/conf.d/mail.ini && \
    ## Install Async and Lodash
    npm install -g async lodash
    
# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
