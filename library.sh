#!/bin/bash

help_die () {
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

die () {
  echo -e >&2 "$@"
  printf "\n"
  exit 1
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

fix_the_base_controller () {
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

  echo -e "${YELLOW}Fixing the base controller ${namespace_dir}/${filename_base}${NC}";
  sed -i "3 ause Illuminate\\\\Routing\\\\Controller;" $filename
  sed -i "3 ause View;" $filename
  sed -i '3 a\\' $filename
  cd $NEW_PROJECT_PATH && git add -A . && git commit -m "Fix the base controller ${namespace_dir}/${filename_base}"
}

fix_the_migration () {
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

  echo -e "${YELLOW}Fixing the migration ${namespace_dir}/${filename_base}${NC}";
  #sed -i "2 ause Illuminate\\\\Database\\\\Schema\\\\Blueprint;" $filename
  sed -i "2 ause Illuminate\\\\Support\\\\Facades\\\\Schema;" $filename
  sed -i 's/\(($table)\)/(Blueprint $table)/g' $filename
}

fix_the_seed () {
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

  echo -e "${YELLOW}Fixing the seed ${namespace_dir}/${filename_base}${NC}";
  sed -i "2 ause Illuminate\\\\Database\\\\Seeder;" $filename
  sed -i '3 a\\' $filename
}

