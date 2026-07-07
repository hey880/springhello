FROM eclipse-temurin:21-jdk

COPY target/*SNAPSHOT.jar app.jar

ENTRYPOINT ["java", "-jar", "/app.jar"]
