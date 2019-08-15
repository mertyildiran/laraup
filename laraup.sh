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

[ -z ${1+x} ] && die "${RED}Argument 1 required, $# provided${NC}"
[ -z ${2+x} ] && die "${RED}Argument 2 required, $# provided${NC}"
[ -z ${3+x} ] && die "${RED}Argument 3 required, $# provided${NC}"

OLD_PROJECT_PATH="$(realpath $1)"
TARGET_PATH="$(realpath $2)"
NEW_PROJECT_NAME=$3
NEW_PROJECT_PATH="${TARGET_PATH}/${NEW_PROJECT_NAME}"

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

echo -e "\n\n\n --- PROJECT MIGRATION STARTS --- \n\n"

echo "Copying the controllers"
rm -rf $NEW_PROJECT_PATH/app/Http/Controllers/*
cp -r $OLD_PROJECT_PATH/app/controllers/* $NEW_PROJECT_PATH/app/Http/Controllers

echo "Copying the views"
rm -rf $NEW_PROJECT_PATH/resources/views/*
cp -r $OLD_PROJECT_PATH/app/views/* $NEW_PROJECT_PATH/resources/views

echo "Copying the models"
mkdir -p $NEW_PROJECT_PATH/app/Models
cp -r $OLD_PROJECT_PATH/app/models/* $NEW_PROJECT_PATH/app/Models

echo "Migrating routes"
ex -snc '$-1,$d|x' $NEW_PROJECT_PATH/routes/api.php
ex -snc '$-2,$d|x' $NEW_PROJECT_PATH/routes/web.php
php routes.php $OLD_PROJECT_PATH/app/routes.php $NEW_PROJECT_PATH/routes
echo -e "});" >> $NEW_PROJECT_PATH/routes/api.php
