# BUILD STAGE
# from redhat website: https://catalog.redhat.com/software/containers/ubi8/openjdk-11/5dd6a4b45a13461646f677f4?container-tabs=gti&gti-tabs=unauthenticated
FROM registry.access.redhat.com/ubi8/openjdk-11 
WORKDIR /app
COPY ./target/todo-backend-bootable.jar /app/

# 8080 for services 、9990 for web console  
EXPOSE 8080/tcp 9990/tcp 

ENV TZ=Asia/Taipei
ENV JAVA_OPTS=""

# from wilfly to-do backend app, https://github.com/wildfly/quickstart/tree/main/todo-backend
ENV POSTGRESQL_DATABASE=todos 
ENV POSTGRESQL_SERVICE_HOST=localhost
ENV POSTGRESQL_SERVICE_PORT=5432
ENV POSTGRESQL_USER=todos
ENV POSTGRESQL_PASSWORD=mysecretpassword
ENV POSTGRESQL_DATASOURCE=ToDos

ENTRYPOINT [ "sh", "-c", "java $JAVA_OPTS     -jar  /app/todo-backend-bootable.jar"]
