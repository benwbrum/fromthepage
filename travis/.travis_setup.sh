set -eux

sudo apt-get -qq update
sudo apt-get install ghostscript
sudo apt-get install graphviz
sudo apt-get install qt5-default libqt5webkit5-dev gstreamer1.0-plugins-base gstreamer1.0-tools gstreamer1.0-x
qtchooser -qt=qt5
gem uninstall capybara-webkit
gem install capybara-webkit

# Install MySQL 5.7 if DB=mysql57
if [[ -n ${DB-} && x$DB =~ ^xmysql57 ]]; then
  sudo bash travis/.travis_mysql57.sh
fi

#Update mysql connector for maria db
if [[ -n ${DB-} && x$DB =~ ^xmariadb ]]; then
  sudo bash travis/.travis_mariadb.sh
fi
