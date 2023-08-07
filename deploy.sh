#!/bin/bash

source_dir="."
destination_dir="deploy"

rm -rf "$destination_dir"
mkdir -p "$destination_dir"

rsync -av \
	--exclude='.DS_Store' \
	--exclude='.bundle' \
	--exclude='.idea' \
	--exclude='.git' \
	--exclude='.gitignore' \
	--exclude='.rubocop.yml' \
	--exclude='deploy' \
	--exclude='deploy.sh' \
	--exclude='deployment-package.zip' \
	--exclude='public' \
	--exclude='sig' \
	--exclude='vendor' \
	"$source_dir/" "$destination_dir/"

cd "$destination_dir"

bundle install --path 'vendor/bundle' --without development || exit 1

rm -rf Gemfile Gemfile.lock .bundle
zip -r deployment-package.zip .
mv deployment-package.zip ..
cd ..

rm -rf "$destination_dir"

echo "Deployment completed successfully!"
