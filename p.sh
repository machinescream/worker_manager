dartfmt -w example lib
echo 'breaking, major, minor, patch, build ?'
read vt
cider bump "${vt}"
echo 'write commit message:'
read cm
git add .
git commit -am "${cm}"
git push

flutter packages pub publish -v
