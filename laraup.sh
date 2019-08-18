#!/bin/bash

# This Bash script upgrades a Laravel 4.2 project to Laravel 5.8
VERSION=0.1.0
AUTHOR='M. Mert Yildiran'
HOMEPAGE='https://github.com/mertyildiran/laraup'

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

die () {
  echo -e >&2 "$@"
  printf "\n"
  help
  exit 1
}

help () {
  read -r -d '' MSG << EOF
USAGE:
  ./laraup.sh PATH_TO_OLD_LARAVEL_4.2_PROJECT PATH_TO_NEW_LARAVEL_5.8_PROJECT
EXAMPLE:
  ./laraup.sh ../todo-app ../upgrade/todo-app5
EOF

  echo "$MSG"
}

source $(dirname $0)/library.sh

[ -z ${1+x} ] && die "${RED}Argument 1 required, $# provided${NC}"
[ -z ${2+x} ] && die "${RED}Argument 2 required, $# provided${NC}"

OLD_PROJECT_PATH="$(realpath $1)"
NEW_PROJECT_PATH="$(realpath $2)"
LARAUP_DIR="$(pwd)"

php $LARAUP_DIR/check.php $OLD_PROJECT_PATH 4.2 || die "${RED}Your Laravel version is not 4.2${NC}"

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

if [[ ! -e $NEW_PROJECT_PATH ]]; then
  mkdir -p $NEW_PROJECT_PATH
  echo -e "${GREEN}Created directory ${NEW_PROJECT_PATH}${NC}"
elif [[ ! -d $NEW_PROJECT_PATH ]]; then
  echo -e >&2 "${RED}${NEW_PROJECT_PATH} already exists but is not a directory${NC}"
  exit 1
fi


composer create-project --prefer-dist laravel/laravel $NEW_PROJECT_PATH || { echo -e "${RED}New Laravel project cloudn't be created, check the above message or your composer installation${NC}" ; exit 1; }
cp -r $OLD_PROJECT_PATH/.git $NEW_PROJECT_PATH && cd $NEW_PROJECT_PATH && git checkout -b laravel-5-upgrade && git add -A . && git commit -m "Bring in Laravel 5.8 base"


echo -e "\n${YELLOW}COPYING THE CONTROLLERS${NC}"
rm -rf $NEW_PROJECT_PATH/app/Http/Controllers/*
cp -r $OLD_PROJECT_PATH/app/controllers/* $NEW_PROJECT_PATH/app/Http/Controllers
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Copy the controllers"

for filename in $(find $NEW_PROJECT_PATH/app/Http/Controllers -name '*.php'); do
  fix_the_namespace_of_file $filename
done
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Fix the namespaces of the controllers"

for filename in $(find $NEW_PROJECT_PATH/app/Http/Controllers/ -type f -exec grep -l "extends Controller" {} \;); do
  fix_the_base_controller $filename
done

find $NEW_PROJECT_PATH/app/Http/Controllers/ -type f -exec sed -i 's/extends \\BaseController/extends BaseController/g' {} +
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Fix the controllers that incorrectly trying to extend from base controller"


echo -e "\n${YELLOW}COPYING THE VIEWS${NC}"
rm -rf $NEW_PROJECT_PATH/resources/views/*
cp -r $OLD_PROJECT_PATH/app/views/* $NEW_PROJECT_PATH/resources/views
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Copy the views"

for filename in $(find $NEW_PROJECT_PATH/resources/views -name '*.php'); do
  fix_the_blade_tags $filename
done
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Fix the Blade tags"

cd $NEW_PROJECT_PATH && composer require laravelcollective/html && \
  git add -A . && git commit -m "Composer require laravelcollective/html"


echo -e "\n${YELLOW}COPYING THE MODELS${NC}"
mkdir -p $NEW_PROJECT_PATH/app/Models
cp -r $OLD_PROJECT_PATH/app/models/* $NEW_PROJECT_PATH/app/Models
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Copy the models"

for filename in $(find $NEW_PROJECT_PATH/app/Models -name '*.php'); do
  fix_the_namespace_of_file $filename
done
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Fix the namespaces of the models"

find $NEW_PROJECT_PATH/app/Models/ -type f -exec sed -i 's/SoftDeletingTrait/SoftDeletes/g' {} +
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Rename SoftDeletingTrait usages as SoftDeletes in app/Models/"


echo -e "\n${YELLOW}COPYING THE MIGRATIONS & SEEDS${NC}"
rm $NEW_PROJECT_PATH/database/migrations/*
cp -r $OLD_PROJECT_PATH/app/database/migrations/* $NEW_PROJECT_PATH/database/migrations
rsync -a $OLD_PROJECT_PATH/app/database/seeds/* $NEW_PROJECT_PATH/database/seeds/ --exclude=DatabaseSeeder.php
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Copy the migrations and seeds"


echo -e "\n${YELLOW}COPYING THE PUBLIC FILES${NC}"
rsync -a $OLD_PROJECT_PATH/public/* $NEW_PROJECT_PATH/public/ --exclude=index.php --exclude=.htaccess
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Copy the public files"


echo -e "\n${YELLOW}MIGRATING ROUTES${NC}"
cd $NEW_PROJECT_PATH && composer require lesichkovm/laravel-advanced-route
ex -snc '$-1,$d|x' $NEW_PROJECT_PATH/routes/api.php
ex -snc '$-2,$d|x' $NEW_PROJECT_PATH/routes/web.php
php $LARAUP_DIR/routes.php $OLD_PROJECT_PATH/app/routes.php $NEW_PROJECT_PATH/routes
echo -e "});" >> $NEW_PROJECT_PATH/routes/api.php
sed -i 's/Route::controller/AdvancedRoute::controller/g' $NEW_PROJECT_PATH/routes/api.php
sed -i 's/Route::controller/AdvancedRoute::controller/g' $NEW_PROJECT_PATH/routes/web.php
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Migrate the routes"


echo -e "\n${YELLOW}COPYING app/helpers.php${NC}"
cp -r $OLD_PROJECT_PATH/app/helpers.php $NEW_PROJECT_PATH/app/
ex -e -s -c ":%s/function info/function info_deprecated/g" $NEW_PROJECT_PATH/app/helpers.php -c wq
php $LARAUP_DIR/composer.php $NEW_PROJECT_PATH
cd $NEW_PROJECT_PATH && composer dump-autoload
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Copy app/helpers.php"


echo -e "\n${YELLOW}TURNING FILTERS INTO MIDDLEWARES${NC}"
php $LARAUP_DIR/filters.php $OLD_PROJECT_PATH/app/filters.php $NEW_PROJECT_PATH
find $NEW_PROJECT_PATH/app/Http/Controllers/ -type f -exec sed -i 's/beforeFilter(/middleware(/g' {} +
find $NEW_PROJECT_PATH/app/Http/Controllers/ -type f -exec sed -i 's/afterFilter(/middleware(/g' {} +
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Turn filters into middlewares"


echo -e "\n${YELLOW}FIXING THE ADDITIONAL ISSUES IN THE CONTROLLERS${NC}"
find $NEW_PROJECT_PATH/app/Http/Controllers/ -type f -exec sed -i 's/App::make\(.*\);/app();/g' {} +
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Fix the additional issues in the controllers"


echo -e "\n${YELLOW}COPYING ARTISAN COMMANDS${NC}"
mkdir -p $NEW_PROJECT_PATH/app/Console/Commands
cp -r $OLD_PROJECT_PATH/app/commands/* $NEW_PROJECT_PATH/app/Console/Commands
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Copy Artisan commands"

for filename in $(find $NEW_PROJECT_PATH/app/Console/Commands -name '*.php'); do
  fix_the_namespace_of_file $filename
done
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Fix the namespaces of Artisan commands"

find $NEW_PROJECT_PATH/app/Console/Commands/ -type f -exec sed -i 's/public function fire()/public function handle()/g' {} +
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Rename the methods named fire() to handle() in Artisan commands"


echo -e "\n${YELLOW}FIXING THE MIGRATIONS & SEEDS${NC}"

for filename in $(find $NEW_PROJECT_PATH/database/migrations -name '*.php'); do
  fix_the_migration $filename
done
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Fix the migrations"

for filename in $(find $NEW_PROJECT_PATH/database/seeds -name '*.php' ! -name 'DatabaseSeeder.php'); do
  fix_the_seed $filename
done
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Fix the seeds"


echo -e "\n${YELLOW}COPYING THE LANGUAGE FILES${NC}"
rsync -a $OLD_PROJECT_PATH/app/lang/* $NEW_PROJECT_PATH/resources/lang/
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Copy the language files"


echo -e "\n${YELLOW}COPYING THE TESTS${NC}"
rsync -a $OLD_PROJECT_PATH/app/tests/* $NEW_PROJECT_PATH/tests/
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Copy the tests"


echo -e "\n${YELLOW}COPYING .env files${NC}"
yes | cp -rf $OLD_PROJECT_PATH/.env* $NEW_PROJECT_PATH/
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Copy .env files"


echo -e "\n${YELLOW}COPYING THE CONFIGURATION FILES${NC}"
rsync -Ir $OLD_PROJECT_PATH/app/config/* $NEW_PROJECT_PATH/config/ --exclude=/app.php
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Copy the configuration files"


#cd $NEW_PROJECT_PATH && composer require cartalyst/sentry:dev-feature/laravel-5 \
#  && php artisan vendor:publish --provider="Cartalyst\Sentry\SentryServiceProvider" \
#  && git add -A . && git commit -m "Composer require cartalyst/sentry:dev-feature/laravel-5"

#cd $NEW_PROJECT_PATH && php artisan make:middleware SentryAuth \
#  && git add -A . && git commit -m "Create SentryAuth middleware"

