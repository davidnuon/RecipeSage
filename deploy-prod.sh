#!/bin/bash

cd Frontend

npm run dist

if [ $? -eq 0 ]; then
    echo OK

    tar -czf deploy-prod.tgz ./www/*

    ssh julian@recipesage.com 'cd ~/Projects/chefbook; git checkout Backend/package-lock.json; git pull; cd Backend; npm install; pm2 reload RecipeSageAPI'

    scp deploy-prod.tgz julian@recipesage.com:/tmp

    rm deploy-prod.tgz

    ssh julian@recipesage.com 'rm /tmp/deploy-prod.tgz; cd /var/www/recipesage.com; rm -rf ./*; tar -zxvf /tmp/deploy-prod.tgz; mv www/* .'
else
    echo FAIL
fi
