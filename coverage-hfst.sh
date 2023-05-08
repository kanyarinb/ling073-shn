
#!/bin/bash

CORPUS=$1
ANALYSER=$2
RLX=$3
TOKEN=$4
LG=$(echo $CORPUS | sed 's:.*\/::' | sed -E 's:(.*\..*)\..*\.txt.*:\1:') # get corpus prefix

person=`whoami`
TMPCORPUS=/tmp/$person.$LG.corpus.txt
TMPPARADE=/tmp/$person.$LG.parade.txt

if [[ $1 =~ .*bz2 ]]; then
	CAT="bzcat"
else
	CAT="cat"
fi;

$CAT $CORPUS > $TMPCORPUS

echo "Generating hitparade (might take a bit!)"

zero=0;
if [ "$TOKEN" -eq "$zero" ]; then
	cat $TMPCORPUS | apertium-destxt | hfst-proc -w $ANALYSER | apertium-retxt | sed -E $'s/\\$[^^]*/\\$\\\n/g' > $TMPPARADE
else
	cat $TMPCORPUS | apertium-destxt | python3 tokeniser.py shn.autotok.hfst | hfst-proc -w $ANALYSER | apertium-retxt | sed -E $'s/\\$[^^]*/\\$\\\n/g' > $TMPPARADE
fi;

echo "TOP UNKNOWN WORDS:"

cat $TMPPARADE | grep '\*' | sort | uniq -c | sort -rn | head -n20

TOTAL=`grep -v '^$' $TMPPARADE | wc -l`
KNOWN=`grep -v '^$' $TMPPARADE | grep -v '\*' | wc -l`
UNKNOWN=`grep -v '^$' $TMPPARADE | grep '\*' | wc -l`
ANALYSES=`sed 's/$\W*\^/$\n^/g' $TMPPARADE | cut -f2- -d'/' | sed 's/\//\n/g' | wc -l`;
AMBIG=`echo $ANALYSES/$TOTAL | calc -p | sed 's/[\s\t]//g'`

if [ "$TOKEN" -eq "$zero" ]; then
	DISAM=`cat $CORPUS | apertium-destxt | hfst-proc -w $ANALYSER | apertium-retxt | cg-proc $RLX | sed 's/$\W*\^/$\n^/g' | cut -f2- -d'/' | sed 's/\//\n/g' | wc -l`
else
	DISAM=`cat $CORPUS | apertium-destxt |  python3 tokeniser.py shn.autotok.hfst | hfst-proc -w $ANALYSER | apertium-retxt | cg-proc $RLX | sed 's/$\W*\^/$\n^/g' | cut -f2- -d'/' | sed 's/\//\n/g' | wc -l`
fi;

DISAMBIG=`echo $DISAM/$TOTAL | calc -p | sed 's/[\s\t]//g'`
PERCENTAGE=`echo $KNOWN/$TOTAL | calc -p | sed 's/[\s\t]//g'`

echo "coverage: $KNOWN / $TOTAL ($PERCENTAGE)"
echo "remaining unknown forms: $UNKNOWN"
echo "ambiguity: $ANALYSES / $TOTAL ($AMBIG)"
echo "ambiguity with disambiguator: $DISAM / $TOTAL ($DISAMBIG)"

DATE=`date`;
echo -e $LG $DATE"\t"$KNOWN"/"$TOTAL"\t"$PERCENTAGE"\t\|\t"$ANALYSES"/"$TOTAL"\t"$AMBIG >> history.log
tail -1 history.log
