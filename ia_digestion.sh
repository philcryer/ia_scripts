#!/bin/bash

###############
# about 
###############
# bring in IA data, from files.xml


###############
# variables
###############
#BASE_URL=http://mbgdevlsrv01.mobot.org/ia
BASE_URL=http://archive.org/download.php
#BASE_URL=http://archive.org/download
CONTROL_GRP=M
#CONTROL_GRP=E
WD=`pwd`
STATE=A
PID_NAME=bhl
FEDORA_HOST=mbgdevlsrv01.mobot.org
FEDORA_PORT=8080
FEDORA_USER=fedoraAdmin
FEDORA_PASS=fedoraAdmin
IA_BASE=/tmp
CATALINA_BASE=/opt/fedora/tomcat
CATALINA_HOME=/opt/fedora/tomcat
CATALINA_TMPDIR=/opt/fedora/tomcat/temp
JRE_HOME=/usr/lib/jvm/java-6-sun
export FEDORA_HOME=/opt/fedora
export JAVA_HOME=/usr/lib/jvm/java-6-sun
export ST_TIME=`date +%Y%m%d.%H%M%S`


###############
# sanity check
###############
if [ ! -f "target_urls" ]; then 
	echo "Fail:	basefile target_urls not found in `pwd`"
	echo "	create a file named 'target_urls' in this directory,"
	echo " 	populate it with one IA object URL per line, like:"
	echo "		http://archive.org/download/descriptivecatal00alco"
	exit 1
fi
if [ -f "ingest.log" ]; then rm ingest.log > /dev/null; fi
cp target_urls /tmp/working_urls


###############
# start the loop
###############
echo " > starting @ ${ST_TIME}"
until [ `cat /tmp/working_urls | wc -l` -lt "1" ]; do
	head -n1 /tmp/working_urls > /tmp/working_url
        sed '1d' /tmp/working_urls > /tmp/working_urls.tmp; mv /tmp/working_urls.tmp /tmp/working_urls
SUBJECT_NAME=`cat /tmp/working_url | cut -d"/" -f5`


###############
# get next pid from fedora
###############
echo -n " > getting pid from fedora..."
curl --user ${FEDORA_USER}:${FEDORA_PASS} -i --output ingest_pid.txt -s -H "Content-type: text/xml" -XPOST "http://${FEDORA_HOST}:${FEDORA_PORT}/fedora/objects/nextPID"
PID=`grep "${PID_NAME}" ingest_pid.txt | cut -d"<" -f2 | cut -d":" -f2`
echo -n "Done"; echo "  (${PID_NAME}:${PID})" 


###############
# get files from IA
###############
if [ ! -d "${IA_BASE}/${SUBJECT_NAME}" ]; then
	mkdir -p ${IA_BASE}/${SUBJECT_NAME}
fi
cd ${IA_BASE}/${SUBJECT_NAME}
curl -s -L ${BASE_URL}/${SUBJECT_NAME}/${SUBJECT_NAME}_files.xml -o "${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_files.xml"
cat ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_files.xml | grep "file name=" | cut -d"\"" -f2 > ${IA_BASE}/${SUBJECT_NAME}/files
DC_URL=${BASE_URL}/${SUBJECT_NAME}/`cat ${IA_BASE}/${SUBJECT_NAME}/files | grep "_dc.xml"`
curl -s -L -O ${DC_URL} 
cd ${WD}


###############
# build foxml
###############
echo -n " > building foxml ingest file..."
if [ -f "ingestable.xml" ]; then rm ingestable.xml > /dev/null; touch ingestable.xml; fi
cat <<EOF >>ingestable.xml
<?xml version="1.0" encoding="UTF-8"?> 
<foxml:digitalObject PID="${PID_NAME}:${PID}" VERSION="1.1" xmlns:foxml="info:fedora/fedora-system:def/foxml#" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="info:fedora/fedora-system:def/foxml# http://www.fedora.info/definitions/1/0/foxml1-1.xsd">
	<foxml:objectProperties> 
		<foxml:property NAME="info:fedora/fedora-system:def/model#state" VALUE="A"/>
   		<foxml:property NAME="info:fedora/fedora-system:def/model#label" VALUE="${SUBJECT_NAME}"/>
		<foxml:property NAME="info:fedora/fedora-system:def/model#ownerId" VALUE="fedoraAdmin"/>
        </foxml:objectProperties>
        <foxml:datastream CONTROL_GROUP="X" ID="${SUBJECT_NAME}_dc.xml" STATE="${STATE}" VERSIONABLE="true">
                <foxml:datastreamVersion ID="DC.0" 
                LABEL="Dublin Core" MIMETYPE="text/xml">
                <foxml:contentDigest DIGEST="none" TYPE="DISABLED"/>
                <foxml:xmlContent>
                <oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/">
			`grep "<dc:title" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml`
			`grep "<dc:creator" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml`
			`grep "<dc:subject" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml`
			`grep "<dc:description" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml`
			`grep "<dc:publisher" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml`
			`grep "<dc:identifier" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml`
			`grep "<dc:contributor" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml`
			`grep "<dc:date" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml`
			`grep "<dc:type" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml`
			`grep "<dc:format" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml`
			`grep "<dc:source" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml`
			`grep "<dc:language" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml`
			`grep "<dc:relation" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml`
			`grep "<dc:converage" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml`
			`grep "<dc:rights" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml`
                </oai_dc:dc>
                </foxml:xmlContent>
                </foxml:datastreamVersion>
        </foxml:datastream>


EOF
echo "Done"


if [ -f "solr_import.xml" ]; then rm solr_import.xml > /dev/null; touch solr_import.xml; fi
echo -n " > building solr import file..."
cat <<EOF >>solr_import.xml
<add>
	<doc>
  	<field name="id">${PID_NAME}:${PID}</field>
	<field name="title">`grep "<dc:title" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml | cut -d"<" -f2 | cut -d">" -f2`</field>
	<filed name="creator">`grep "<dc:creator" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml | cut -d"<" -f2 | cut -d">" -f2`</field>
	<field name="subject">`grep "<dc:subject" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml | cut -d"<" -f2 | cut -d">" -f2`</field> 
	<field name="description">`grep "<dc:description" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml | cut -d"<" -f2 | cut -d">" -f2`</field> 
	<field name="publisher">`grep "<dc:publisher" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml | cut -d"<" -f2 | cut -d">" -f2`</field> 
	<field name="identifier">`grep "<dc:identifier" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml | cut -d"<" -f2 | cut -d">" -f2`</field> 
	<field name="contributor">`grep "<dc:contributor" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml | cut -d"<" -f2 | cut -d">" -f2`</field> 
	<field name="date">`grep "<dc:date" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml | cut -d"<" -f2 | cut -d">" -f2`</field> 
	<field name="type">`grep "<dc:type" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml | cut -d"<" -f2 | cut -d">" -f2`</field> 
	<field name="format">`grep "<dc:format" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml | cut -d"<" -f2 | cut -d">" -f2`</field> 
	<field name="source">`grep "<dc:source" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml | cut -d"<" -f2 | cut -d">" -f2`</field> 
	<field name="language">`grep "<dc:language" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml | cut -d"<" -f2 | cut -d">" -f2`</field> 
	<field name="relation">`grep "<dc:relation" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml | cut -d"<" -f2 | cut -d">" -f2`</field> 
	<field name="coverage">`grep "<dc:coverage" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml | cut -d"<" -f2 | cut -d">" -f2`</field> 
	<field name="rights'>`grep "<dc:rights" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml | cut -d"<" -f2 | cut -d">" -f2`</field> echo "Done" 
	</doc>
</add>
EOF
echo "Done"


###############
# .djvu
###############
if [[ `grep ".djvu" ${IA_BASE}/${SUBJECT_NAME}/files | wc -l` -gt "0" ]]; then
cat <<EOF >>ingestable.xml
	<foxml:datastream CONTROL_GROUP="${CONTROL_GRP}" ID="${SUBJECT_NAME}.djvu" STATE="${STATE}"> 
		<foxml:datastreamVersion ID="DJVU.0" MIMETYPE="image/vnd.djvu" 
			LABEL="DjVu">
			<foxml:contentLocation REF="${BASE_URL}/${SUBJECT_NAME}/${SUBJECT_NAME}.djvu" TYPE="URL"/> 
		</foxml:datastreamVersion>
	</foxml:datastream>
EOF
fi


###############
# .gif
###############
if [[ `grep ".gif" ${IA_BASE}/${SUBJECT_NAME}/files | wc -l` -gt "0" ]]; then
cat <<EOF >>ingestable.xml
	<foxml:datastream CONTROL_GROUP="${CONTROL_GRP}" ID="${SUBJECT_NAME}.gif" STATE="${STATE}"> 
		<foxml:datastreamVersion ID="GIF.0" MIMETYPE="image/gif" 
			LABEL="Animated GIF"> 
			<foxml:contentLocation REF="${BASE_URL}/${SUBJECT_NAME}/${SUBJECT_NAME}.gif" TYPE="URL"/> 
		</foxml:datastreamVersion>
	</foxml:datastream>
EOF
fi


###############
# .pdf
###############
if [[ `grep ".pdf" ${IA_BASE}/${SUBJECT_NAME}/files | wc -l` -gt "0" ]]; then
cat <<EOF >>ingestable.xml
	<foxml:datastream CONTROL_GROUP="${CONTROL_GRP}" ID="${SUBJECT_NAME}.pdf" STATE="${STATE}"> 
		<foxml:datastreamVersion ID="PDF.0" MIMETYPE="application/pdf" 
		LABEL="Standard LuraTech PDF"> 
			<foxml:contentLocation REF="${BASE_URL}/${SUBJECT_NAME}/${SUBJECT_NAME}.pdf" TYPE="URL"/> 
		</foxml:datastreamVersion>
	</foxml:datastream>
EOF
fi


###############
# abbyy.gz
###############
if [[ `grep "_abbyy.gz" ${IA_BASE}/${SUBJECT_NAME}/files | wc -l` -gt "0" ]]; then
cat <<EOF >>ingestable.xml
	<foxml:datastream CONTROL_GROUP="${CONTROL_GRP}" ID="${SUBJECT_NAME}_abbyy.gz" STATE="${STATE}"> 
		<foxml:datastreamVersion ID="ABBYYGZ.0" MIMETYPE="application/octet-stream" 
		LABEL="Abbyy GZ"> 
			<foxml:contentLocation REF="${BASE_URL}/${SUBJECT_NAME}/${SUBJECT_NAME}_abbyy.gz" TYPE="URL"/> 
		</foxml:datastreamVersion>
	</foxml:datastream>
EOF
fi


###############
# _bw.pdf
###############
if [[ `grep "_bw.pdf" ${IA_BASE}/${SUBJECT_NAME}/files | wc -l` -gt "0" ]]; then
cat <<EOF >>ingestable.xml
	<foxml:datastream CONTROL_GROUP="${CONTROL_GRP}" ID="${SUBJECT_NAME}_bw.pdf" STATE="${STATE}"> 
		<foxml:datastreamVersion ID="BWPDF.0" MIMETYPE="application/pdf" 
			LABEL="Grayscale LuraTech PDF"> 
			<foxml:contentLocation REF="${BASE_URL}/${SUBJECT_NAME}/${SUBJECT_NAME}_bw.pdf" TYPE="URL"/> 
		</foxml:datastreamVersion>
	</foxml:datastream>
EOF
fi


###############
# _djvu.txt
###############
if [[ `grep "_djvu.txt" ${IA_BASE}/${SUBJECT_NAME}/files | wc -l` -gt "0" ]]; then
cat <<EOF >>ingestable.xml
	<foxml:datastream CONTROL_GROUP="${CONTROL_GRP}" ID="${SUBJECT_NAME}_djvu.txt" STATE="${STATE}"> 
		<foxml:datastreamVersion ID="DJVUTXT.0" MIMETYPE="text/plain" 
		LABEL="DjVuTXT"> 
			<foxml:contentLocation REF="${BASE_URL}/${SUBJECT_NAME}/${SUBJECT_NAME}_djvu.txt" TYPE="URL"/> 
		</foxml:datastreamVersion>
	</foxml:datastream>
EOF
fi


###############
# _djvu.xml
###############
if [[ `grep "_djvu.xml" ${IA_BASE}/${SUBJECT_NAME}/files | wc -l` -gt "0" ]]; then
cat <<EOF >>ingestable.xml
	<foxml:datastream CONTROL_GROUP="${CONTROL_GRP}" ID="${SUBJECT_NAME}_djvu.xml" STATE="${STATE}"> 
		<foxml:datastreamVersion ID="DJVUXML.0" MIMETYPE="application/xml" 
		LABEL="DjVu XML"> 
			<foxml:contentLocation REF="${BASE_URL}/${SUBJECT_NAME}/${SUBJECT_NAME}_djvu.xml" TYPE="URL"/> 
		</foxml:datastreamVersion>
	</foxml:datastream>
EOF
fi


###############
# _files.xml
###############
if [[ `grep "_files.xml" ${IA_BASE}/${SUBJECT_NAME}/files | wc -l` -gt "0" ]]; then
cat <<EOF >>ingestable.xml
        <foxml:datastream CONTROL_GROUP="${CONTROL_GRP}" ID="${SUBJECT_NAME}_files.xml" STATE="${STATE}"> 
		<foxml:datastreamVersion ID="XML.0" MIMETYPE="application/xml" 
		LABEL="Metadata"> 
			<foxml:contentLocation REF="${BASE_URL}/${SUBJECT_NAME}/${SUBJECT_NAME}_files.xml" TYPE="URL"/> 
		</foxml:datastreamVersion>
	</foxml:datastream>
EOF
fi


###############
# _flippy.zip
###############
if [[ `grep "_flippy.zip" ${IA_BASE}/${SUBJECT_NAME}/files | wc -l` -gt "0" ]]; then
cat <<EOF >>ingestable.xml
	<foxml:datastream CONTROL_GROUP="${CONTROL_GRP}" ID="${SUBJECT_NAME}_flippy.zip" STATE="${STATE}"> 
		<foxml:datastreamVersion ID="FLIPPYZIP.0" MIMETYPE="application/zip" 
		LABEL="Flippy Zip"> 
			<foxml:contentLocation REF="${BASE_URL}/${SUBJECT_NAME}/${SUBJECT_NAME}_flippy.zip" TYPE="URL"/> 
		</foxml:datastreamVersion>
	</foxml:datastream>
EOF
fi


###############
# _marc.xml
###############
if [[ `grep "_marc.xml" ${IA_BASE}/${SUBJECT_NAME}/files | wc -l` -gt "0" ]]; then
cat <<EOF >>ingestable.xml
	<foxml:datastream CONTROL_GROUP="${CONTROL_GRP}" ID="${SUBJECT_NAME}_marc.xml" STATE="${STATE}"> 
		<foxml:datastreamVersion ID="MARC.0" MIMETYPE="application/xml" 
			LABEL="MARC"> 
			<foxml:contentLocation REF="${BASE_URL}/${SUBJECT_NAME}/${SUBJECT_NAME}_marc.xml" TYPE="URL"/> 
		</foxml:datastreamVersion>
	</foxml:datastream>
EOF
fi


###############
# _meta.mrc
###############
if [[ `grep "_meta.mrc" ${IA_BASE}/${SUBJECT_NAME}/files | wc -l` -gt "0" ]]; then
cat <<EOF >>ingestable.xml
	<foxml:datastream CONTROL_GROUP="${CONTROL_GRP}" ID="${SUBJECT_NAME}_meta.mrc" STATE="${STATE}"> 
		<foxml:datastreamVersion ID="MARCMRC.0" MIMETYPE="application/octet-stream" 
			LABEL="MARC Binary"> 
			<foxml:contentLocation REF="${BASE_URL}/${SUBJECT_NAME}/${SUBJECT_NAME}_meta.mrc" TYPE="URL"/> 
		</foxml:datastreamVersion>
	</foxml:datastream>
EOF
fi


###############
# _meta.xml
###############
if [[ `grep "_meta.xml" ${IA_BASE}/${SUBJECT_NAME}/files | wc -l` -gt "0" ]]; then
cat <<EOF >>ingestable.xml
	<foxml:datastream CONTROL_GROUP="${CONTROL_GRP}" ID="${SUBJECT_NAME}_meta.xml" STATE="${STATE}"> 
		<foxml:datastreamVersion ID="METAXML.0" MIMETYPE="application/xml" 
			LABEL="Metadata"> 
			<foxml:contentLocation REF="${BASE_URL}/${SUBJECT_NAME}/${SUBJECT_NAME}_meta.xml" TYPE="URL"/> 
		</foxml:datastreamVersion>
	</foxml:datastream>
EOF
fi


###############
# _metasource.xml
###############
if [[ `grep "_metasource.xml" ${IA_BASE}/${SUBJECT_NAME}/files | wc -l` -gt "0" ]]; then
cat <<EOF >>ingestable.xml
	<foxml:datastream CONTROL_GROUP="${CONTROL_GRP}" ID="${SUBJECT_NAME}_metasource.xml" STATE="${STATE}"> 
		<foxml:datastreamVersion ID="METASOURCEXML.0" MIMETYPE="application/xml" 
			LABEL="MARC Source"> 
			<foxml:contentLocation REF="${BASE_URL}/${SUBJECT_NAME}/${SUBJECT_NAME}_metasource.xml" TYPE="URL"/> 
		</foxml:datastreamVersion>
	</foxml:datastream>
EOF
fi


###############
# _jp2.zip
###############
if [[ `grep "_jp2.zip" ${IA_BASE}/${SUBJECT_NAME}/files | wc -l` -gt "0" ]]; then
cat <<EOF >>ingestable.xml
	<foxml:datastream CONTROL_GROUP="${CONTROL_GRP}" ID="${SUBJECT_NAME}_jp2.zip" STATE="${STATE}"> 
		<foxml:datastreamVersion ID="JP2ZIP.0" MIMETYPE="application/zip" 
		LABEL="Single Page Processed JP2 ZIP"> 
			<foxml:contentLocation REF="${BASE_URL}/${SUBJECT_NAME}/${SUBJECT_NAME}_jp2.zip" TYPE="URL"/> 
		</foxml:datastreamVersion>
	</foxml:datastream>
EOF
fi


###############
# _pure_jp2.zip
###############
if [[ `grep "_pure_jp2.zip" ${IA_BASE}/${SUBJECT_NAME}/files | wc -l` -gt "0" ]]; then
cat <<EOF >>ingestable.xml
	<foxml:datastream CONTROL_GROUP="${CONTROL_GRP}" ID="${SUBJECT_NAME}_pure_jp2.zip" STATE="${STATE}"> 
		<foxml:datastreamVersion ID="PUREJP2ZIP.0" MIMETYPE="application/zip" 
		LABEL="Single Page Processed JP2 ZIP"> 
			<foxml:contentLocation REF="${BASE_URL}/${SUBJECT_NAME}/${SUBJECT_NAME}_pure_jp2.zip" TYPE="URL"/> 
		</foxml:datastreamVersion>
	</foxml:datastream>
EOF
fi


###############
# _raw_jp2.zip
###############
if [[ `grep "_raw_jp2.zip" ${IA_BASE}/${SUBJECT_NAME}/files | wc -l` -gt "0" ]]; then
cat <<EOF >>ingestable.xml
	<foxml:datastream CONTROL_GROUP="${CONTROL_GRP}" ID="${SUBJECT_NAME}_raw_jp2.zip" STATE="${STATE}"> 
		<foxml:datastreamVersion ID="RAWJP2ZIP.0" MIMETYPE="application/zip" 
		LABEL="Single Page Processed JP2 ZIP"> 
			<foxml:contentLocation REF="${BASE_URL}/${SUBJECT_NAME}/${SUBJECT_NAME}_raw_jp2.zip" TYPE="URL"/> 
		</foxml:datastreamVersion>
	</foxml:datastream>
EOF
fi


###############
# _orig_jp2.tar
###############
if [[ `grep "_orig_jp2.tar" ${IA_BASE}/${SUBJECT_NAME}/files | wc -l` -gt "0" ]]; then
cat <<EOF >>ingestable.xml
	<foxml:datastream CONTROL_GROUP="${CONTROL_GRP}" ID="${SUBJECT_NAME}_orig_jp2.tar" STATE="${STATE}"> 
		<foxml:datastreamVersion ID="ORIGJP2TAR.0" MIMETYPE="application/tar" 
		LABEL="Single Page Original JP2 Tar"> 
			<foxml:contentLocation REF="${BASE_URL}/${SUBJECT_NAME}/${SUBJECT_NAME}_orig_jp2.tar" TYPE="URL"/> 
		</foxml:datastreamVersion>
	</foxml:datastream>
EOF
fi


###############
# _scanfactors.xml
###############
if [[ `grep "_scanfactors.xml" ${IA_BASE}/${SUBJECT_NAME}/files | wc -l` -gt "0" ]]; then
cat <<EOF >>ingestable.xml
	<foxml:datastream CONTROL_GROUP="${CONTROL_GRP}" ID="${SUBJECT_NAME}_scanfactors.xml" STATE="${STATE}"> 
		<foxml:datastreamVersion ID="SCANFACTORSXML.0" MIMETYPE="text/xml" 
			LABEL="Scan Factors"> 
			<foxml:contentLocation REF="${BASE_URL}/${SUBJECT_NAME}/${SUBJECT_NAME}_scanfactors.xml" TYPE="URL"/> 
		</foxml:datastreamVersion>
	</foxml:datastream>
EOF
fi


###############
# _scandata.xml
###############
if [[ `grep "_scandata.xml" ${IA_BASE}/${SUBJECT_NAME}/files | wc -l` -gt "0" ]]; then
cat <<EOF >>ingestable.xml
	<foxml:datastream CONTROL_GROUP="${CONTROL_GRP}" ID="${SUBJECT_NAME}_scandata.xml" STATE="${STATE}"> 
		<foxml:datastreamVersion ID="SCANDATAXML.0" MIMETYPE="text/xml" 
			LABEL="Scandata"> 
			<foxml:contentLocation REF="${BASE_URL}/${SUBJECT_NAME}/${SUBJECT_NAME}_scandata.xml" TYPE="URL"/> 
		</foxml:datastreamVersion>
	</foxml:datastream>
EOF
fi


###############
# _scandata.zip
###############
if [[ `grep "_scandata.zip" ${IA_BASE}/${SUBJECT_NAME}/files | wc -l` -gt "0" ]]; then
cat <<EOF >>ingestable.xml
	<foxml:datastream CONTROL_GROUP="${CONTROL_GRP}" ID="${SUBJECT_NAME}_scandata.zip" STATE="${STATE}"> 
		<foxml:datastreamVersion ID="SCANDATAZIP.0" MIMETYPE="text/xml" 
			LABEL="Scandata"> 
			<foxml:contentLocation REF="${BASE_URL}/${SUBJECT_NAME}/${SUBJECT_NAME}_scandata.zip" TYPE="URL"/> 
		</foxml:datastreamVersion>
	</foxml:datastream>
EOF
fi


##########
# finish
##########
cat <<EOF >>ingestable.xml
</foxml:digitalObject>
EOF


##########
# ingest
##########
echo " --> Starting: ${PID_NAME}:${PID}" >> ingest.log
echo -n " > "; /var/lib/fedora/client/bin/fedora-ingest.sh f ingestable.xml info:fedora/fedora-system:FOXML-1.1 ${FEDORA_HOST}:${FEDORA_PORT} ${FEDORA_USER} ${FEDORA_PASS} http 
echo " --> Ingested: ${PID_NAME}:${PID}" >> ingest.log
echo " --> `grep "<dc:title" ${IA_BASE}/${SUBJECT_NAME}/${SUBJECT_NAME}_dc.xml`" >> ingest.log
echo " -------------------------->" >> ingest.log
echo " --> files ingested:" >> ingest.log
FILES_OUT=`find /opt/fedora/data -name "*${PID_NAME}_${PID}*"`; FILES_OUT_SIZE=`du -hc ${FILES_OUT}`; echo ${FILES_OUT_SIZE} >> ingest.log
echo " -------------------------->" >> ingest.log
if [ ! -d "ingested_${ST_TIME}" ]; then 
	mkdir ingested_${ST_TIME}
fi
if [ -f "ingestable.xml" ]; then 
	cp ingestable.xml ingested_${ST_TIME}/ingestable.${PID_NAME}_${PID}.xml 
fi


##########
# import into solr
##########
# TODO
# ...
if [ ! -d "ingested_${ST_TIME}" ]; then 
	mkdir ingested_${ST_TIME}
fi
if [ -f "solr_import.xml" ]; then 
	cp solr_import.xml ingested_${ST_TIME}/solr_import.${PID_NAME}_${PID}.xml
fi


##########
# all done, clean up, say something silly and exit
##########
done
if [ ! -d "ingested_${ST_TIME}" ]; then 
	mkdir ingested_${ST_TIME}
	mv ingest.log ingested_${ST_TIME}
fi
if [ -f "ingest_pid.txt" ]; then rm ingest_pid.txt > /dev/null; fi
if [ -f "ingest.log" ]; then rm ingest.log > /dev/null; fi
if [ -f "ingestable.xml" ]; then rm ingestable.xml > /dev/null; fi
if [ -f "solr_import.xml" ]; then rm solr_import.xml > /dev/null; fi
if [ -f "working_url*" ]; then rm working_url* > /dev/null; fi
echo " > Ingest complete, yum."
exit 0
