cp -r ./_book ~/Desktop
git co gh-pages
cp -r ~/Desktop/_book/* . 
echo "Please enter the version:"
read version
date_time=`date +'%m%d'`
git add .
git ci -am "deploy@${date_time}-${version}"
git push -f origin gh-pages
rm -rf ~/Desktop/_book
git co master
