# 1. Build Layer (Maven)
FROM maven:3.9.6-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline

COPY src ./src
RUN mvn clean package -DskipTests

# 2. Distroless Runtime Layer
FROM gcr.io/distroless/java21-debian12
COPY --from=build /app/target/kerosene-vault-1.0.0.jar /app/vault.jar

# Libera tranca de memoria mlock para a camada off-heap
USER root:root

ENTRYPOINT ["java", "-jar", "/app/vault.jar"]
