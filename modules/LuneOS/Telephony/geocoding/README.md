### Using Google's geocoding data in LuneOS

## Introduction

Google's geocoding statistical data are located here:
https://github.com/googlei18n/libphonenumber/tree/master/resources/geocoding

They are organized by language, and then by country code. So each country's geocoding data Can be found here:
```
<language>/<country_code>.txt
```

In these files, the format is the following:
```
# comment
<beginning of international number>|<location string>
```

For example:
```
35865|Vaasa
```

## Compiling the data to a JSON file

If the geocoding data files are located in the directory $GEOCODING, then the following command will create a series a JSON files with the corresponding content in the $OUTPUTDIR directory:

```
for i in "$GEOCODING"/*/*.txt; do
   OUTPUTFILE="$OUTPUTDIR"/$(basename ${i%.txt}.json)
   grep '^[0-9].*' $i | awk ' BEGIN { ORS = ""; FS="|"; print "{"; } NR>1 { print ", \n" } { print "\""$1"\": \""$2"\""; } END { print " }"; }' > "$OUTPUTFILE"
done
```


