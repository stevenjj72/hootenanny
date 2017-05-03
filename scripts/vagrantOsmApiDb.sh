sed -i s/^OSMAPI_DB_NAME=.*$/OSMAPI_DB_NAME=openstreetmap/ /var/lib/tomcat8/webapps/hoot-services/WEB-INF/classes/db/db.properties
sed -i s/^OSMAPI_DB_USER=.*$/OSMAPI_DB_USER=vagrant/ /var/lib/tomcat8/webapps/hoot-services/WEB-INF/classes/db/db.properties
sed -i s/^OSMAPI_DB_PASSWORD=.*$/OSMAPI_DB_PASSWORD=vagrant!/ /var/lib/tomcat8/webapps/hoot-services/WEB-INF/classes/db/db.properties
sed -i s/^OSMAPI_DB_HOST=.*$/OSMAPI_DB_HOST=localhost/ /var/lib/tomcat8/webapps/hoot-services/WEB-INF/classes/db/db.properties
sed -i s/^OSMAPI_DB_PORT=.*$/OSMAPI_DB_PORT=5432/ /var/lib/tomcat8/webapps/hoot-services/WEB-INF/classes/db/db.properties
