# 1. Base image com Java 21
FROM eclipse-temurin:21-jdk-jammy

# 2. Diretório dentro do container onde a app ficará
WORKDIR /app

# 3. Copia o JAR construído localmente para dentro do container
COPY build/libs/v0.5-0.0.1-SNAPSHOT.jar app.jar

# 4. Expõe a porta do Spring Boot
EXPOSE 8080

# 5. Comando para rodar a aplicação
ENTRYPOINT ["java","-jar","app.jar"]
