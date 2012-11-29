#!/bin/sh

LOCDIR=$HOME/Dropbox/website # Run script from this directory
PUBDIR=$HOME/publish
FOOTER=$LOCDIR/_footer.html
NAVBAR=$LOCDIR/_navigation.html
PANOPTS="--smart --standalone -f markdown --template=website.html\
 --css=./main.css --include-before-body="$NAVBAR""

# $PANOPTS above assume that the website template is in
# $HOME/.pandoc/templates/ and that the CSS file is in $PUBDIR.
# Next block assumes posts to be published are ...
# 1. In folders by category in $LOCDIR.
# 2. In markdown files with *.txt extension.
# 3. Contain a standard pandoc title block in first three lines.

> $LOCDIR/.allposts
echo "Processing posts ..."
find `ls -l $LOCDIR | awk '/^d/ {print $NF}'` -type d -maxdepth 1 | \
while read -r folder
do
CATEGORY=$(basename "$folder")
for file in `ls "$folder"/*.txt`
do
	if head -n 1 "$file" | grep -Eq "^%"; then
	POST=$(basename "$file" .txt)
	TITLE=$(sed -n '1 s/% //p' "$file")
	POSTDATE=$(sed -n '3 s/% //p' "$file" | sed 's/[ ]$//')
	# Next two lines use BSD date command. For GNU date, use commented line
	# Thanks to @fravashi http://github.com/wcaleb/website/issues/1
	SORTDATE=$(date -jf '%B %e, %Y' "$POSTDATE" +%y%m%d)
	# SORTDATE=$(date -d "$POSTDATE" +%y%m%d)
	RSSDATE=$(date -jf '%B %e, %Y' "$POSTDATE" '+%a, %d %b %Y 00:00:00 %Z')
	# RSSDATE=$(date -d "$POSTDATE" '+%a, %d %b %Y 00:00:00 %Z')
	pandoc $PANOPTS\
 	 --variable=category:"$CATEGORY"\
	 --include-after-body="$FOOTER"\
	 --output=$PUBDIR/"$POST".html\
	 "$file"
	CLIP=$(grep -m 1 -Eo '<p>.+</p>' $PUBDIR/"$POST".html) 
	echo ""$SORTDATE"%"$TITLE"%"$POST".html%"$POSTDATE"%"$RSSDATE"%"$CLIP""\
	 >> $LOCDIR/"$CATEGORY".txt
	fi
done
cat $LOCDIR/"$CATEGORY".txt >> $LOCDIR/.allposts
sort -nr $LOCDIR/"$CATEGORY".txt |\
 awk 'BEGIN{FS="%"};{print "* [" $2 "](" $3 ") | " $4 }'\
 > $LOCDIR/.postlist
pandoc $PANOPTS\
 -A "$FOOTER"\
 --output=$PUBDIR/"$CATEGORY".html\
 $LOCDIR/"$CATEGORY".pdc .postlist
rm $LOCDIR/"$CATEGORY".txt
done

echo "Processing index ..."
sort -nr $LOCDIR/.allposts | sed -n '1,5 p'|\
 awk 'BEGIN{FS="%"};{print "* [" $2 "](" $3 ") | " $4 }'\
 > $LOCDIR/recentposts.pdc 
pandoc $PANOPTS\
 -B $LOCDIR/_contact.html\
 -o $PUBDIR/index.html\
 $LOCDIR/index.pdc $LOCDIR/recentposts.pdc

if [ $LOCDIR/cv.pdc -nt $PUBDIR/cv.html ];then
echo "Processing CV ..."
pandoc $PANOPTS\
 -B $LOCDIR/_contact.html\
 -A "$FOOTER"\
 -o $PUBDIR/cv.html\
 $LOCDIR/cvhead.pdc $LOCDIR/cv.pdc
sed -E 's/^[^#\[\\]/\\\ind &/g' $LOCDIR/cv.pdc |\
 pandoc -s -S -f markdown --latex-engine=xelatex\
 --template=cv.tex\
 -o $PUBDIR/mcdanielcv.pdf
fi

echo "Processing colophon ..."
cat $LOCDIR/$0 |\
 awk '
 BEGIN { print "Code used to generate site on"; system("date");
 print "\n`````bash" }
 { print }
 END { print "\n`````" }' > $LOCDIR/.script
pandoc $PANOPTS\
 -A "$FOOTER"\
 -o $PUBDIR/colophon.html\
 $LOCDIR/colophon.pdc $LOCDIR/.script
rm $LOCDIR/.script

echo "Processing RSS feed ..."
cp $LOCDIR/_feed.xml $PUBDIR/feed.xml
sort -nr $LOCDIR/.allposts | sed -n '1,5 p'|\
 awk 'BEGIN{FS="%"}
 {print "\t<item>"}
 {print "\t\t<title>" $2 "</title>"}
 {print "\t\t<link>http://wcm1.web.rice.edu/" $3 "</link>"}
 {print "\t\t<guid>http://wcm1.web.rice.edu/" $3 "</guid>"}
 {print "\t\t<pubDate>" $5 "</pubDate>"}
 {print "\t\t<description>" $6 "[...]</description>\n\t</item>"}
 END{print "</channel>\n</rss>"}'\
 >> $PUBDIR/feed.xml

exit 0
