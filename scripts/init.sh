#!/bin/sh




mkdir -p volumes/final-project/config
rm -rf volumes/final-project/config/*
mkdir -p volumes/home-page/{config,html}
rm -rf volumes/home-page/{config,html}/*

docker pull nginx:alpine3.21
docker run --rm --name temp-nginx -d nginx:alpine3.21

docker cp temp-nginx:/etc/nginx/conf.d volumes/final-project/config
docker cp temp-nginx:/etc/nginx/nginx.conf volumes/final-project/config/nginx.conf

docker cp temp-nginx:/etc/nginx/conf.d volumes/home-page/config
docker cp temp-nginx:/etc/nginx/nginx.conf volumes/home-page/config/nginx.conf
docker cp temp-nginx:/usr/share/nginx/html volumes/home-page/
docker stop temp-nginx



# find and replace 80 with 7901 in volumes/final-project/config/conf.d/default.conf
# the best bash tool for find and replace is sed
sed -i '' 's/80/7901/g' "volumes/final-project/config/conf.d/default.conf"

LOC_BLOCK=$(cat <<'EOF'
    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
EOF
)
FP_REPO_NAME="Multi-page-site"
NEW_LOC_BLOCK=$(cat <<EOF
    location /$FP_REPO_NAME {
        alias   /usr/share/nginx/html;
        index  index.html index.htm;
    }
    location / {
        proxy_pass http://hp-svc:6969;
    }
EOF
)

# Debugging: Print the variables to ensure they are set correctly
echo "LOC_BLOCK: $LOC_BLOCK"
echo "NEW_LOC_BLOCK: $NEW_LOC_BLOCK"

# replace the location block in volumes/final-project/config/conf.d/default.conf
perl -0777 -i -pe "s|\Q$LOC_BLOCK\E|$NEW_LOC_BLOCK|g" "volumes/final-project/config/conf.d/default.conf"

# Debugging: Check if the replacement was successful
grep -q "$NEW_LOC_BLOCK" "volumes/final-project/config/conf.d/default.conf" && echo "Replacement successful" || echo "Replacement failed"

sed -i '' 's/80/6969/g' "volumes/home-page/config/conf.d/default.conf"

#volumes/home-page/html/index.html
#replace the contents of the body element only with:
#<h1>Home</h1>
    #<p>Please visit the <a href="/your-github-repo-name/">your-github-repo-name</a> page.</p>
OLD_HTML_BODY=$(cat <<'EOF'
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
EOF
)

NEW_HTML_BODY=$(cat <<EOF
<h1>Home</h1>
    <p>Please visit the <a href="/$FP_REPO_NAME/">$FP_REPO_NAME</a> page.</p>
EOF
)
perl -0777 -i -pe "s|\Q$OLD_HTML_BODY\E|$NEW_HTML_BODY|g" "volumes/home-page/html/index.html"