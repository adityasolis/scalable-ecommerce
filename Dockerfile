# Use an official PHP image with Apache, PHP version 8.2
FROM php:8.2-apache

# Set the working directory in the container
WORKDIR /var/www/html

# Install PHP dependencies including GD, MySQL PDO, and other necessary packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    libzip-dev \
    libgd-dev \
    libfreetype6-dev \
    libjpeg-dev \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    curl \
    nodejs \
    npm \
    mariadb-client \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) zip gd pdo_mysql \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy composer.json and composer.lock for PHP dependencies
COPY composer.json ./

# Run composer install to install PHP dependencies
RUN composer install --no-scripts --no-autoloader

# Copy package.json for Node.js dependencies
COPY package.json ./

# Install Node.js dependencies
RUN npm install 

# Copy the rest of the application code into the container
COPY . .

# Set permissions for the web root directory
RUN chown -R www-data:www-data /var/www/html && \
    find /var/www/html -type d -exec chmod 755 {} \; && \
    find /var/www/html -type f -exec chmod 644 {} \;

# Copy the Apache virtual host configuration file
COPY Portfolio.conf /etc/apache2/sites-available/Portfolio.conf

# Enable the new site configuration and disable the default site
RUN a2ensite Portfolio && a2dissite 000-default

# Enable mod_rewrite (if you're using it for URL rewriting)
RUN a2enmod rewrite

# Set the ServerName to your IP address (for production use)
RUN echo "ServerName 65.2.69.107" >> /etc/apache2/apache2.conf

# Expose port 80 (this will be used for the web server inside the container)
EXPOSE 80

# Start Apache server in the foreground
CMD ["apache2-foreground"]
