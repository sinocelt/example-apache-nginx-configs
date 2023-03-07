server {
  listen 80;
  listen [::]:80;

  # 🔥🔥🔥
  # make sure you that you change example.com with the name of your domain
  server_name www.example.com example.com;
  
  # 🔥🔥🔥
  # make sure that you edit the root location with the actual location of your website
  root /var/www/example.com/;

  index index.php index.html index.htm index.nginx-debian.html;

  # 🔥🔥🔥
  # edit the names of the access log and error log if you want
  error_log /var/log/nginx/example_wordpress.error;
  access_log /var/log/nginx/example_wordpress.access;

  location / {
    try_files $uri $uri/ /index.php;
  }

   location ~ ^/wp-json/ {
     rewrite ^/wp-json/(.*?)$ /?rest_route=/$1 last;
   }

  location ~* /wp-sitemap.*\.xml {
    try_files $uri $uri/ /index.php$is_args$args;
  }

  # 🔥🔥🔥
  # make sure that if you want custom error pages, that you create the custom html files
  # error_page 404 /404.html;
  # error_page 500 502 503 504 /50x.html;

  client_max_body_size 20M;

  # 🔥🔥🔥
  # Like above, if you might want to create custom error pages
  # location = /50x.html {
  #  root /usr/share/nginx/html;
  # }

  location ~ \.php$ {
    # 🔥🔥🔥
    # NOTE YOU WILL NEED TO MAKE SURE YOU ARE USING THE RIGHT PHP sock. Run the command 
    # ls -la /run/php/php*
    # then edit 7.4 below with the version of php you get with the previous command
    # fastcgi_pass unix:/run/php/php8.1-fpm.sock;
    fastcgi_pass unix:/run/php/php7.4-fpm.sock;
    
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
    include snippets/fastcgi-php.conf;
    fastcgi_buffers 1024 4k;
    fastcgi_buffer_size 128k;
  }

  #enable gzip compression
  gzip on;
  gzip_vary on;
  gzip_min_length 1000;
  gzip_comp_level 5;
  gzip_types application/json text/css application/x-javascript application/javascript image/svg+xml;
  gzip_proxied any;

  # A long browser cache lifetime can speed up repeat visits to your page
  location ~* \.(jpg|jpeg|gif|png|webp|svg|woff|woff2|ttf|css|js|ico|xml)$ {
       access_log        off;
       log_not_found     off;
       expires           360d;
  }

  # disable access to hidden files
  location ~ /\.ht {
      access_log off;
      log_not_found off;
      deny all;
  }
    
    #🔥🔥🔥
    # The following assumes that you have already set up a Certbot SSL file
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

}

# 🔥🔥🔥
# The following assumes that you have already set up a Certbot SSL file
server {
    # 🔥🔥🔥
    # make sure you that you change example.com with the name of your domain
    if ($host = example.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

    # 🔥🔥🔥
    # make sure you that you change example.com with the name of your domain
    server_name example.com www.example.com;
    listen 80;
    return 404; # managed by Certbot
}
