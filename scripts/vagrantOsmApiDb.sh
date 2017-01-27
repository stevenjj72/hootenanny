sed -i s/^osmApiDbEnabled=.*$/osmApiDbEnabled=true/ /var/lib/tomcat8/webapps/hoot-services/WEB-INF/classes/conf/hoot-services.conf
sed -i s/^osmApiDbName=.*$/osmApiDbName=openstreetmap/ /var/lib/tomcat8/webapps/hoot-services/WEB-INF/classes/conf/hoot-services.conf
sed -i s/^osmApiDbUserId=.*$/osmApiDbUserId=vagrant/ /var/lib/tomcat8/webapps/hoot-services/WEB-INF/classes/conf/hoot-services.conf
sed -i s/^osmApiDbPassword=.*$/osmApiDbPassword=vagrant!/ /var/lib/tomcat8/webapps/hoot-services/WEB-INF/classes/conf/hoot-services.conf
sed -i s/^osmApiDbHost=.*$/osmApiDbHost=localhost:5432/ /var/lib/tomcat8/webapps/hoot-services/WEB-INF/classes/conf/hoot-services.conf
