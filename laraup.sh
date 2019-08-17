#!/bin/bash

# This Bash script upgrades a Laravel 4.2 project to Laravel 5.8

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
  ./laraup.sh PATH_TO_LARAVEL_4.2 PATH_TO_NEW_LARAVEL_5.8_PROJECT NEW_LARAVEL_5.8_PROJECT_NAME
EXAMPLE:
  ./laraup.sh ../todo-app ../upgrade/ todo-app5
EOF

  echo "$MSG"
}

fix_the_namespace_of_file () {
  filename=$1
  [ -f "$filename" ] || continue
  filename_dir=$(dirname "${filename}")
  filename_base=$(basename "${filename}")
  namespace_dir=${filename_dir#"$NEW_PROJECT_PATH/"}

  namespace=""
  IFS='/' read -ra ADDR <<< "$namespace_dir"
  for i in "${ADDR[@]}"; do
    [ -z "$namespace" ] || namespace="${namespace}\\\\"
    namespace="${namespace}${i^}"
  done

  echo -e "${YELLOW}Fixing the namespace of ${namespace_dir}/${filename_base}${NC}";
  sed -i '/^namespace/d' $filename
  sed -i "1 anamespace ${namespace};" $filename
  sed -i '1 a\\' $filename
}

fix_the_blade_tags () {
  filename=$1
  [ -f "$filename" ] || continue
  filename_dir=$(dirname "${filename}")
  filename_base=$(basename "${filename}")
  namespace_dir=${filename_dir#"$NEW_PROJECT_PATH/"}

  namespace=""
  IFS='/' read -ra ADDR <<< "$namespace_dir"
  for i in "${ADDR[@]}"; do
    [ -z "$namespace" ] || namespace="${namespace}\\\\"
    namespace="${namespace}${i^}"
  done

  echo -e "${YELLOW}Fixing the Blade tags in ${namespace_dir}/${filename_base}${NC}";
  php $LARAUP_DIR/blade.php $filename
}

[ -z ${1+x} ] && die "${RED}Argument 1 required, $# provided${NC}"
[ -z ${2+x} ] && die "${RED}Argument 2 required, $# provided${NC}"
[ -z ${3+x} ] && die "${RED}Argument 3 required, $# provided${NC}"

OLD_PROJECT_PATH="$(realpath $1)"
TARGET_PATH="$(realpath $2)"
NEW_PROJECT_NAME=$3
NEW_PROJECT_PATH="${TARGET_PATH}/${NEW_PROJECT_NAME}"
LARAUP_DIR="$(pwd)"

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

echo -e "Path to old Laravel 4.2 project:\t\t${GREEN}${OLD_PROJECT_PATH}${NC}"
echo -e "Target directory for the new project:\t\t${GREEN}${TARGET_PATH}${NC}"
echo -e "Name of new Laravel 5.8 project:\t\t${GREEN}${NEW_PROJECT_NAME}${NC}\n"

if [[ ! -e $TARGET_PATH ]]; then
  mkdir -p $TARGET_PATH
  echo -e "${GREEN}Created directory ${TARGET_PATH}${NC}"
elif [[ ! -d $TARGET_PATH ]]; then
  echo -e >&2 "${RED}${TARGET_PATH} already exists but is not a directory${NC}"
  exit 1
fi

composer create-project --prefer-dist laravel/laravel $NEW_PROJECT_PATH || { echo -e "${RED}New Laravel project cloudn't be created, check the above message or your composer installation${NC}" ; exit 1; }
cd $NEW_PROJECT_PATH && git init && git add -A . && git commit -m "Bring in Laravel 5.8 base"

echo -e "\n${YELLOW}COPYING THE CONTROLLERS${NC}"
rm -rf $NEW_PROJECT_PATH/app/Http/Controllers/*
cp -r $OLD_PROJECT_PATH/app/controllers/* $NEW_PROJECT_PATH/app/Http/Controllers
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Copy the controllers"

for filename in $(find $NEW_PROJECT_PATH/app/Http/Controllers -name '*.php'); do
  fix_the_namespace_of_file $filename
done
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Fix the namespaces of the controllers"

echo -e "\n${YELLOW}COPYING THE VIEWS${NC}"
rm -rf $NEW_PROJECT_PATH/resources/views/*
cp -r $OLD_PROJECT_PATH/app/views/* $NEW_PROJECT_PATH/resources/views
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Copy the views"

for filename in $(find $NEW_PROJECT_PATH/resources/views -name '*.php'); do
  fix_the_blade_tags $filename
done
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Fix the Blade tags"

echo -e "\n${YELLOW}COPYING THE MODELS${NC}"
mkdir -p $NEW_PROJECT_PATH/app/Models
cp -r $OLD_PROJECT_PATH/app/models/* $NEW_PROJECT_PATH/app/Models
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Copy the models"

for filename in $(find $NEW_PROJECT_PATH/app/Models -name '*.php'); do
  fix_the_namespace_of_file $filename
done
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Fix the namespaces of the models"


echo -e "\n${YELLOW}MIGRATING ROUTES${NC}"
cd $NEW_PROJECT_PATH && composer require lesichkovm/laravel-advanced-route
ex -snc '$-1,$d|x' $NEW_PROJECT_PATH/routes/api.php
ex -snc '$-2,$d|x' $NEW_PROJECT_PATH/routes/web.php
php $LARAUP_DIR/routes.php $OLD_PROJECT_PATH/app/routes.php $NEW_PROJECT_PATH/routes
echo -e "});" >> $NEW_PROJECT_PATH/routes/api.php
sed -i 's/Route::controller/AdvancedRoute::controller/g' $NEW_PROJECT_PATH/routes/api.php
sed -i 's/Route::controller/AdvancedRoute::controller/g' $NEW_PROJECT_PATH/routes/web.php
cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Migrate the routes"
