set -eux

# Install MySQL 5.7 if DB=mysql57
if [[ -n ${DB-} && x$DB =~ ^xmysql57 ]]; then
  sudo bash travis/.travis_mysql57.sh
fi

#Update mysql connector for maria db
if [[ -n ${DB-} && x$DB =~ ^xmariadb ]]; then
  sudo bash travis/.travis_mariadb.sh
fi
