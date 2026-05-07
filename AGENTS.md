# Repository Guidelines

## Project Structure & Module Organization

Kerosene is split into a Flutter client, Java services, a Go sidecar, and local infrastructure. The main Spring Boot backend lives in `backend/kerosene/src/main/java/source`, with tests in `backend/kerosene/src/test/java` and resources in `backend/kerosene/src/main/resources`. The Flutter app is in `frontend/lib`, organized by `core`, `design_system`, and `features`; tests mirror this under `frontend/test`, and assets live in `frontend/assets`. The MPC gRPC sidecar is in `backend/mpc-sidecar`, while the vault service is in `backend/vault`. Canonical documentation is under `docs`; operational scripts are in `scripts`.

## Build, Test, and Development Commands

- `bash scripts/start-local.sh`: start the local backend stack with Docker Compose.
- `bash scripts/stop-local.sh` / `bash scripts/logs-local.sh`: stop services or inspect logs.
- `cd backend/kerosene && JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew test`: run Spring/JUnit tests.
- `cd backend/kerosene && ./gradlew dependencyCheckAnalyze`: generate OWASP dependency reports.
- `cd frontend && flutter pub get && flutter analyze && flutter test`: install Flutter dependencies, lint, and test.
- `cd backend/mpc-sidecar && go test ./...`: run Go sidecar tests.
- `cd backend/vault && mvn package`: build the vault fat JAR.

## Coding Style & Naming Conventions

Use Java 21 for backend services, Dart 3 for Flutter, and Go 1.24 for the sidecar. Keep Java packages under `source.<domain>` and follow existing controller/service/repository boundaries. Use `UpperCamelCase` for Java/Dart types, `lowerCamelCase` for methods and fields, and `snake_case.dart` for Dart files. Run `dart format` and `gofmt`. Prefer existing DTO, exception, and use-case patterns.

## Testing Guidelines

Java tests use JUnit 5 and Spring test support; name files `*Test.java` and place them under `src/test/java`. Flutter tests use `flutter_test`; name files `*_test.dart`. Go tests use standard `*_test.go` files. Add focused tests for wallet, ledger, security, transaction, and payment-link behavior because these areas are financial or security-sensitive. Some Redis-backed tests need the local stack running.

## Commit & Pull Request Guidelines

Recent history mixes Conventional Commit prefixes (`feat:`, `docs:`, `chore:`) with vague messages. Prefer concise Conventional Commit style, for example `feat: add payment link reconciliation guard`. PRs should include a short description, linked issue when available, commands run, config or migration notes, and screenshots for Flutter UI changes.

## Security & Configuration Tips

Never commit `.env`, certificates, keystores, Tor keys, service accounts, generated secrets, or `frontend/build/**`. Start from `backend/kerosene/.env.example`, keep production secrets outside git, and avoid pasting fully materialized Docker Compose configs into public channels because they can expose environment values.
