# 🏗️ Diagrama da Arquitetura - LoC + Riverpod + Camadas

## 📊 Visão Geral da Arquitetura

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PRESENTATION LAYER                           │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐   │
│  │   Screen   │  │   Widget   │  │  Provider  │  │   State    │   │
│  │            │  │            │  │ (Riverpod) │  │            │   │
│  │  UI/UX     │  │ Components │  │  Notifier  │  │  Sealed    │   │
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘   │
│         │               │               │               │           │
│         └───────────────┴───────────────┴───────────────┘           │
│                              ↓                                       │
└─────────────────────────────────────────────────────────────────────┘
                               ↓
┌─────────────────────────────────────────────────────────────────────┐
│                          DOMAIN LAYER                                │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐                    │
│  │  UseCase   │  │ Repository │  │   Entity   │                    │
│  │            │  │ Interface  │  │            │                    │
│  │  Business  │  │  Contract  │  │   Pure     │                    │
│  │   Logic    │  │            │  │  Objects   │                    │
│  └────────────┘  └────────────┘  └────────────┘                    │
│         │               │               ↑                            │
│         └───────────────┘               │                            │
│                 ↓                       │                            │
└─────────────────────────────────────────────────────────────────────┘
                  ↓                       ↑
┌─────────────────────────────────────────────────────────────────────┐
│                           DATA LAYER                                 │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐   │
│  │ Repository │  │ DataSource │  │ DataSource │  │   Model    │   │
│  │    Impl    │  │  (Remote)  │  │  (Local)   │  │   (DTO)    │   │
│  │            │  │    API     │  │   Cache    │  │   JSON     │   │
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘   │
│         │               │               │               │           │
│         └───────────────┴───────────────┴───────────────┘           │
│                              ↓                                       │
└─────────────────────────────────────────────────────────────────────┘
                               ↓
                    ┌──────────────────────┐
                    │   External Sources   │
                    │  • REST API          │
                    │  • Local Storage     │
                    │  • Database          │
                    └──────────────────────┘
```

## 🔄 Fluxo de Dados Detalhado

### 1️⃣ Fluxo de Requisição (User → API)

```
User Interaction (Tap Button)
         ↓
┌─────────────────────────────────────────────────────────┐
│ PRESENTATION                                             │
│                                                          │
│  Screen.onPressed()                                      │
│         ↓                                                │
│  ref.read(provider.notifier).method()                   │
│         ↓                                                │
│  StateNotifier.method()                                  │
│         ↓                                                │
│  state = Loading                                         │
└─────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────┐
│ DOMAIN                                                   │
│                                                          │
│  UseCase.call(params)                                    │
│         ↓                                                │
│  Validate Business Rules                                 │
│         ↓                                                │
│  repository.method(params)                               │
└─────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────┐
│ DATA                                                     │
│                                                          │
│  RepositoryImpl.method()                                 │
│         ↓                                                │
│  try { dataSource.method() }                             │
│         ↓                                                │
│  RemoteDataSource.method()                               │
│         ↓                                                │
│  ApiClient.post/get()                                    │
│         ↓                                                │
│  HTTP Request                                            │
└─────────────────────────────────────────────────────────┘
         ↓
    🌐 API Server
```

### 2️⃣ Fluxo de Resposta (API → User)

```
🌐 API Server
         ↓
┌─────────────────────────────────────────────────────────┐
│ DATA                                                     │
│                                                          │
│  HTTP Response                                           │
│         ↓                                                │
│  Model.fromJson(response.data)                           │
│         ↓                                                │
│  Cache (if needed)                                       │
│         ↓                                                │
│  return Right(model.toEntity())                          │
│                                                          │
│  catch (Exception) {                                     │
│    return Left(Failure)                                  │
│  }                                                       │
└─────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────┐
│ DOMAIN                                                   │
│                                                          │
│  Either<Failure, Entity>                                 │
│         ↓                                                │
│  Return to UseCase                                       │
└─────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────┐
│ PRESENTATION                                             │
│                                                          │
│  result.fold(                                            │
│    (failure) => state = Error(failure.message),          │
│    (entity) => state = Success(entity),                  │
│  )                                                       │
│         ↓                                                │
│  UI Rebuild (Consumer watches state)                     │
│         ↓                                                │
│  Display Result to User                                  │
└─────────────────────────────────────────────────────────┘
         ↓
    👤 User sees result
```

## 🎯 Exemplo Concreto: Login Flow

```
1. User taps "Login" button
         ↓
2. LoginScreen calls:
   ref.read(authProvider.notifier).login(email, password)
         ↓
3. AuthNotifier sets:
   state = AuthLoading()
         ↓
4. AuthNotifier calls:
   loginUseCase(email: email, password: password)
         ↓
5. LoginUseCase validates:
   - Email not empty
   - Password length >= 6
         ↓
6. LoginUseCase calls:
   authRepository.login(email, password)
         ↓
7. AuthRepositoryImpl calls:
   remoteDataSource.login(email, password)
         ↓
8. AuthRemoteDataSource:
   - Makes HTTP POST to /auth/login
   - Receives response
   - Parses to UserModel
   - Saves token
         ↓
9. AuthRepositoryImpl:
   - Caches user with localDataSource
   - Converts UserModel to User entity
   - Returns Right(user)
         ↓
10. LoginUseCase returns:
    Either<Failure, User>
         ↓
11. AuthNotifier updates state:
    state = AuthAuthenticated(user)
         ↓
12. LoginScreen (Consumer) rebuilds:
    - Shows success message
    - Navigates to home
         ↓
13. User sees home screen
```

## 📦 Injeção de Dependências com Riverpod

```
┌─────────────────────────────────────────────────────────┐
│                    DEPENDENCY GRAPH                      │
│                                                          │
│  sharedPreferencesProvider                               │
│            ↓                                             │
│  authLocalDataSourceProvider                             │
│            ↓                                             │
│            ├──→ authRepositoryProvider ←──┐              │
│            │                              │              │
│  apiClientProvider                        │              │
│            ↓                              │              │
│  authRemoteDataSourceProvider ────────────┘              │
│                                           ↓              │
│                              ┌────────────────────────┐  │
│                              │  loginUseCaseProvider  │  │
│                              │  signupUseCaseProvider │  │
│                              └────────────────────────┘  │
│                                           ↓              │
│                              ┌────────────────────────┐  │
│                              │    authProvider        │  │
│                              │  (StateNotifier)       │  │
│                              └────────────────────────┘  │
│                                           ↓              │
│                                      UI Widgets          │
└─────────────────────────────────────────────────────────┘
```

## 🧪 Testabilidade

### Domain Layer (100% testável)
```dart
test('should return failure when email is empty', () {
  // Arrange
  final useCase = LoginUseCase(mockRepository);
  
  // Act
  final result = await useCase(email: '', password: '123456');
  
  // Assert
  expect(result.isLeft(), true);
});
```

### Data Layer (Testável com mocks)
```dart
test('should return user when API call is successful', () {
  // Arrange
  when(mockDataSource.login()).thenAnswer((_) async => tUserModel);
  
  // Act
  final result = await repository.login(email: 'test@test.com', password: '123456');
  
  // Assert
  expect(result, Right(tUser));
  verify(mockDataSource.login());
});
```

### Presentation Layer (Testável com ProviderContainer)
```dart
testWidgets('should show loading indicator when state is loading', (tester) async {
  // Arrange
  final container = ProviderContainer(
    overrides: [authProvider.overrideWith((ref) => MockAuthNotifier())],
  );
  
  // Act
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: LoginScreen()),
  );
  
  // Assert
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

## 🎨 Benefícios da Arquitetura

### ✅ Separação de Responsabilidades
- Cada camada tem uma responsabilidade clara
- Fácil de entender e manter

### ✅ Testabilidade
- Cada camada pode ser testada independentemente
- Fácil criar mocks e stubs

### ✅ Escalabilidade
- Adicionar novas features é simples
- Código organizado e modular

### ✅ Manutenibilidade
- Mudanças em uma camada não afetam outras
- Fácil refatorar e melhorar

### ✅ Reutilização
- UseCases podem ser reutilizados
- Widgets e providers compartilhados

### ✅ Independência de Framework
- Domain não depende de Flutter
- Fácil migrar para outras plataformas

---

**Criado em**: 10/12/2025  
**Arquitetura**: LoC + Riverpod + Clean Architecture
