#!/bin/bash

# This Bash script automatically upgrades your Laravel 4.2 project to 5.8
VERSION=0.1.0
AUTHOR='M. Mert Yildiran'
HOMEPAGE='https://github.com/mertyildiran/laraup'

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

source $(dirname $0)/library.sh

[ -z ${1+x} ] && help_die "Argument 1 required, $# provided"
[ -z ${2+x} ] && help_die "Argument 2 required, $# provided"

OLD_PROJECT_PATH="$(realpath $1)"
NEW_PROJECT_PATH="$(realpath $2)"
LARAUP_DIR="$(pwd)"

php $LARAUP_DIR/check.php $OLD_PROJECT_PATH 4.2 || help_die "Your Laravel version is not 4.2"

try_mkdir $NEW_PROJECT_PATH

clear
echo -e "${YELLOW}"
# ASCII Art - ANSI Shadow
cat << "EOF"
  ██╗      █████╗ ██████╗  █████╗ ██╗   ██╗██████╗
  ██║     ██╔══██╗██╔══██╗██╔══██╗██║   ██║██╔══██╗
  ██║     ███████║██████╔╝███████║██║   ██║██████╔╝
  ██║     ██╔══██║██╔══██╗██╔══██║██║   ██║██╔═══╝
  ███████╗██║  ██║██║  ██║██║  ██║╚██████╔╝██║
  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝
EOF
echo -e "${NC}"

echo -e "Version: ${YELLOW}${VERSION}${NC}    Author: ${YELLOW}${AUTHOR}${NC}    Homepage: ${YELLOW}${HOMEPAGE}${NC}\n"

echo -e "Path to old Laravel 4.2 project:\t${GREEN}${OLD_PROJECT_PATH}${NC}"
echo -e "Path to new Laravel 5.8 project:\t${GREEN}${NEW_PROJECT_PATH}${NC}\n"

cd $OLD_PROJECT_PATH && composer install

composer create-project --prefer-dist laravel/laravel $NEW_PROJECT_PATH || die "New Laravel project cloudn't be created, check the above message or your composer installation"
cp -r $OLD_PROJECT_PATH/.git $NEW_PROJECT_PATH && cd $NEW_PROJECT_PATH && git checkout -b laravel-5-upgrade && git_commit "Bring in Laravel 5.8 base"


section_title "COPYING THE CONTROLLERS"
rm -rf $NEW_PROJECT_PATH/app/Http/Controllers/*
cp -r $OLD_PROJECT_PATH/app/controllers/* $NEW_PROJECT_PATH/app/Http/Controllers
git_commit "Copy the controllers"

for filename in $(find $NEW_PROJECT_PATH/app/Http/Controllers -name '*.php'); do
  fix_the_namespace_of_file $filename
done
git_commit "Fix the namespaces of the controllers"

for filename in $(find $NEW_PROJECT_PATH/app/Http/Controllers/ -type f -exec grep -l "extends Controller" {} \;); do
  fix_the_base_controller $filename
done

find $NEW_PROJECT_PATH/app/Http/Controllers/ -type f -exec sed -i 's/extends \\BaseController/extends BaseController/g' {} +
git_commit "Fix the controllers that incorrectly trying to extend from base controller"


section_title "COPYING THE VIEWS"
rm -rf $NEW_PROJECT_PATH/resources/views/*
cp -r $OLD_PROJECT_PATH/app/views/* $NEW_PROJECT_PATH/resources/views
git_commit "Copy the views"

for filename in $(find $NEW_PROJECT_PATH/resources/views -name '*.php'); do
  fix_the_blade_tags $filename
done
git_commit "Fix the Blade tags"

cd $NEW_PROJECT_PATH && composer require laravelcollective/html && \
  git add -A . && git commit -m "Composer require laravelcollective/html"


section_title "COPYING THE MODELS"
mkdir -p $NEW_PROJECT_PATH/app/Models
cp -r $OLD_PROJECT_PATH/app/models/* $NEW_PROJECT_PATH/app/Models
git_commit "Copy the models"

for filename in $(find $NEW_PROJECT_PATH/app/Models -name '*.php'); do
  fix_the_namespace_of_file $filename
done
git_commit "Fix the namespaces of the models"

find $NEW_PROJECT_PATH/app/Models/ -type f -exec sed -i 's/SoftDeletingTrait/SoftDeletes/g' {} +
git_commit "Rename SoftDeletingTrait usages as SoftDeletes in app/Models/"


section_title "COPYING THE MIGRATIONS & SEEDS"
rm $NEW_PROJECT_PATH/database/migrations/*
cp -r $OLD_PROJECT_PATH/app/database/migrations/* $NEW_PROJECT_PATH/database/migrations
rsync -a $OLD_PROJECT_PATH/app/database/seeds/* $NEW_PROJECT_PATH/database/seeds/ --exclude=DatabaseSeeder.php
git_commit "Copy the migrations and seeds"


section_title "COPYING THE PUBLIC FILES"
rsync -a $OLD_PROJECT_PATH/public/* $NEW_PROJECT_PATH/public/ --exclude=index.php --exclude=.htaccess
git_commit "Copy the public files"


section_title "MIGRATING ROUTES"
cd $NEW_PROJECT_PATH && composer require lesichkovm/laravel-advanced-route
ex -snc '$-1,$d|x' $NEW_PROJECT_PATH/routes/api.php
ex -snc '$-2,$d|x' $NEW_PROJECT_PATH/routes/web.php
php $LARAUP_DIR/routes.php $OLD_PROJECT_PATH/app/routes.php $NEW_PROJECT_PATH/routes
echo -e "});" >> $NEW_PROJECT_PATH/routes/api.php
sed -i 's/Route::controller/AdvancedRoute::controller/g' $NEW_PROJECT_PATH/routes/api.php
sed -i 's/Route::controller/AdvancedRoute::controller/g' $NEW_PROJECT_PATH/routes/web.php
git_commit "Migrate the routes"


section_title "COPYING app/helpers.php"
cp -r $OLD_PROJECT_PATH/app/helpers.php $NEW_PROJECT_PATH/app/
ex -e -s -c ":%s/function info/function info_deprecated/g" $NEW_PROJECT_PATH/app/helpers.php -c wq
php $LARAUP_DIR/helpers.php $NEW_PROJECT_PATH
cd $NEW_PROJECT_PATH && composer dump-autoload
git_commit "Copy app/helpers.php"


section_title "TURNING FILTERS INTO MIDDLEWARES"
php $LARAUP_DIR/filters.php $OLD_PROJECT_PATH/app/filters.php $NEW_PROJECT_PATH
find $NEW_PROJECT_PATH/app/Http/Controllers/ -type f -exec sed -i 's/beforeFilter(/middleware(/g' {} +
find $NEW_PROJECT_PATH/app/Http/Controllers/ -type f -exec sed -i 's/afterFilter(/middleware(/g' {} +
git_commit "Turn filters into middlewares"


section_title "FIXING THE ADDITIONAL ISSUES IN THE CONTROLLERS"
find $NEW_PROJECT_PATH/app/Http/Controllers/ -type f -exec sed -i 's/App::make\(.*\);/app();/g' {} +
git_commit "Fix the additional issues in the controllers"


cd $NEW_PROJECT_PATH && composer dump-autoload || die "\nNew Composer packages couldn't be installed because \"composer dump-autoload\" is failed. Fix this issue and continue to run ${LARAUP_DIR}/laraup.sh from line: ${LINENO}"
section_title "INSTALLING NEW COMPOSER PACKAGES"
echo_warning "CAUTION: Run ssh-add otherwise it will keep asking to enter your passphrase a few times in case of secret repositories."
php $LARAUP_DIR/composer.php $OLD_PROJECT_PATH $NEW_PROJECT_PATH
git_commit "Install new Composer packages"


section_title "COPYING ARTISAN COMMANDS"
mkdir -p $NEW_PROJECT_PATH/app/Console/Commands
cp -r $OLD_PROJECT_PATH/app/commands/* $NEW_PROJECT_PATH/app/Console/Commands
git_commit "Copy Artisan commands"

for filename in $(find $NEW_PROJECT_PATH/app/Console/Commands -name '*.php'); do
  fix_the_namespace_of_file $filename
done
git_commit "Fix the namespaces of Artisan commands"

find $NEW_PROJECT_PATH/app/Console/Commands/ -type f -exec sed -i 's/public function fire()/public function handle()/g' {} +
git_commit "Rename the methods named fire() to handle() in Artisan commands"


section_title "FIXING THE MIGRATIONS & SEEDS"

for filename in $(find $NEW_PROJECT_PATH/database/migrations -name '*.php'); do
  fix_the_migration $filename
done
git_commit "Fix the migrations"

for filename in $(find $NEW_PROJECT_PATH/database/seeds -name '*.php' ! -name 'DatabaseSeeder.php'); do
  fix_the_seed $filename
done
git_commit "Fix the seeds"


section_title "COPYING THE LANGUAGE FILES"
rsync -a $OLD_PROJECT_PATH/app/lang/* $NEW_PROJECT_PATH/resources/lang/
git_commit "Copy the language files"


section_title "COPYING THE TESTS"
rsync -a $OLD_PROJECT_PATH/app/tests/* $NEW_PROJECT_PATH/tests/
git_commit "Copy the tests"


section_title "COPYING .env files"
yes | cp -rf $OLD_PROJECT_PATH/.env* $NEW_PROJECT_PATH/
git_commit "Copy .env files"


section_title "COPYING THE CONFIGURATION FILES"
rsync -r --ignore-existing $OLD_PROJECT_PATH/app/config/* $NEW_PROJECT_PATH/config/ --exclude=/app.php
git_commit "Copy the configuration files"

php $LARAUP_DIR/config.php $OLD_PROJECT_PATH $NEW_PROJECT_PATH
git_commit "Fix config/app.php file"


section_title "COPYING THE REMAINING FILES"
rsync -a --exclude={'.git','app','bootstrap','public','vendor','.env*','artisan','composer.*','package.json','package-lock.json','server.php'} $OLD_PROJECT_PATH/* $NEW_PROJECT_PATH/
rsync -r --ignore-existing $OLD_PROJECT_PATH/*.md $NEW_PROJECT_PATH/
git_commit "Copy the remaining files"

echo_success "\n\nCongragulations! \\( ﾟヮﾟ)/ Your Laravel 4.2 project has been upgraded to 5.8 successfully. You can find your upgraded project in here:${NC} ${NEW_PROJECT_PATH}\n"
