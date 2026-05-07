# 1. Build Layer (Maven)
FROM docker.io/library/maven:3.9.6-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline

COPY src ./src
RUN mvn clean package -DskipTests

# 2. Distroless Runtime Layer
FROM gcr.io/distroless/java21-debian12:nonroot
WORKDIR /app
COPY --chown=65532:65532 --from=build /app/target/kerosene-vault-1.0.0.jar /app/vault.jar

# Run as nonroot. IPC_LOCK and memlock limits are granted by Compose.
USER 65532:65532

ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/app/vault.jar"]
