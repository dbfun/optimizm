#!/bin/bash

# Скрипт lossless оптимизации изображений (без потери качества) в указанных каталогах $DIRS
# Для пропуска "повторной" оптимизации список уже оптимизированных файлов в SQLite $DB_FILE
# Запуск: ./optimizm.sh
# Зависимости: sudo apt-get install jpegoptim gifsicle optipng
# Все пути - относительно скрипта

# База данных SQLite для хранения уже оптимизированных изображений
DB_FILE=optimizm.db

# Пути к изображениям через пробел
DIRS="templates/beez images media"

# RUN

function init {
  cd "$(dirname "$0")"

  resp=`which sqlite3`

  if [[ $? != "0" ]]; then
    echo 'No sqlite3'
    exit 1
  fi

  resp=`which jpegoptim`

  if [[ $? != "0" ]]; then
    echo 'No jpegoptim. Run: sudo apt-get install jpegoptim gifsicle optipng'
    exit 1
  fi

  resp=`which gifsicle`

  if [[ $? != "0" ]]; then
    echo 'No gifsicle. Run: sudo apt-get install jpegoptim gifsicle optipng'
    exit 1
  fi

  resp=`which optipng`

  if [[ $? != "0" ]]; then
    echo 'No optipng. Run: sudo apt-get install jpegoptim gifsicle optipng'
    exit 1
  fi

  # Создает БД если ее еще нет
  sqlite3 $DB_FILE "CREATE TABLE IF NOT EXISTS images (filepath VARCHAR(512) NOT NULL UNIQUE, date DATETIME NOT NULL);"
}

function optimizeExt {

  local EXT=$1
  local CMD=$2

  echo "# Optimize *.$EXT"

  for DIR in $DIRS; do
    echo "## /$DIR"
    NUM_FILES=`find $DIR -type f -iname "*.$EXT" | wc -l`
    NUM_COUNTER=0
    find $DIR -type f -iname "*.$EXT" -print0 | while read -d $'\0' FILE; do
      let "NUM_COUNTER += 1"
      progressBar $NUM_FILES $NUM_COUNTER
      COUNT=`sqlite3 $DB_FILE "SELECT COUNT(*) FROM images WHERE filepath = '${FILE//\'/''}';"`
      if [[ "$COUNT" == "0" ]]; then
        $CMD "$FILE" > /dev/null
        `sqlite3 $DB_FILE "INSERT INTO images (filepath, date) VALUES ('${FILE//\'/''}', datetime());"`
      fi
    done
  done

}

function progressBar {
  local X=$1
  local Y=$2
  let "PERCENT = Y * 100 / X"
  echo -ne "$PERCENT%\r"
  if [[ $PERCENT == "100" ]]; then
    echo -ne '\n'
  fi
}


init
optimizeExt 'jpg' 'jpegoptim --strip-all'
optimizeExt 'jpeg' 'jpegoptim --strip-all'
optimizeExt 'gif' 'gifsicle --careful -w -b -O2'
optimizeExt 'png' 'optipng -o5 -quiet -preserve'
