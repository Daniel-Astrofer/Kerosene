# Erros do Servico Completo

Data da verificacao: 2026-06-16

Escopo verificado: backend `backend/kerosene`.

## Resumo

| Area | Status | Detalhe |
| --- | --- | --- |
| Testes backend completos | Sem falhas | `562` testes executados, `0` falhas, `0` ignorados. |
| Build com Java 21 | OK | `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test` concluiu com sucesso. |
| Build com Java 25 padrao | Erro de ambiente | Gradle/Kotlin DSL falha antes de compilar o servico. |
| Logs durante testes | Ruido conhecido | Hibernate emitiu erros ao tentar dropar tabelas de notificacao no shutdown de testes. |

## Comandos Executados

```bash
JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test
```

Resultado:

```text
BUILD SUCCESSFUL
562 tests
0 failures
0 ignored
```

Tambem foi testado o Gradle com o Java padrao do ambiente:

```bash
./gradlew test --stacktrace --tests source.kfe.service.KfeWalletServiceTest
```

Resultado: falhou antes da compilacao do projeto.

## Erros Encontrados

### 1. Gradle falha com Java 25

Severidade: alta para ambiente local/CI configurado com Java 25.

Status: aberto no ambiente; contornado usando Java 21.

Sintoma:

```text
FAILURE: Build failed with an exception.

* What went wrong:
25.0.3

* Exception is:
java.lang.IllegalArgumentException: 25.0.3
    at org.jetbrains.kotlin.com.intellij.util.lang.JavaVersion.parse(JavaVersion.java:305)
    at org.jetbrains.kotlin.com.intellij.util.lang.JavaVersion.current(JavaVersion.java:174)
```

Impacto:

O Gradle 8.7 com Kotlin DSL nao consegue interpretar a versao `25.0.3` do JDK neste ambiente. A falha ocorre durante avaliacao dos scripts Gradle, antes de `compileJava`, portanto nao indica erro funcional no codigo do servico.

Mitigacao atual:

```bash
JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test
```

Acao recomendada:

Fixar Java 21 para builds locais e CI, ou atualizar a stack Gradle/Kotlin DSL quando o projeto for preparado para Java 25.

### 2. Logs `ERROR` do Hibernate no shutdown dos testes

Severidade: baixa enquanto os testes continuam passando.

Status: observado durante a suite completa.

Sintoma:

```text
HHH000478: Unsuccessful: drop table if exists public.notification_device_tokens cascade
HHH000478: Unsuccessful: drop table if exists public.notifications cascade
```

Impacto:

Esses logs aparecem durante o encerramento do contexto JPA em testes. A suite terminou com sucesso, entao isso nao esta quebrando o build atual. Ainda assim, vale investigar porque o schema de teste esta tentando remover tabelas em uma condicao que o banco rejeita ou ja nao consegue atender no shutdown.

Acao recomendada:

Revisar a configuracao de schema dos testes que sobem contexto Spring/JPA e as migracoes relacionadas a `notifications` e `notification_device_tokens`.

## Falhas Nao Encontradas

Nao foram encontrados failures ou errors nos arquivos JUnit XML gerados em:

```text
backend/kerosene/build/test-results/test
```

Resumo do relatorio Gradle:

```text
tests: 562
failures: 0
ignored: 0
duration: 15.470s
successful: 100%
```

## Observacoes

Este arquivo registra os erros observados na validacao do backend completo. Frontend, containers Docker, Vault, Tor, Bitcoin/LND reais e infraestrutura local completa nao foram executados nesta verificacao.
