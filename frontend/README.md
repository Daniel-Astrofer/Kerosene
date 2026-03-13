# 🎨 Kerosene - Arquitetura LoC + Riverpod + Camadas

## ✅ Estrutura Criada com Sucesso!

```
lib/
├── 📱 main.dart                          # Ponto de entrada da aplicação
│
├── 🔧 core/                              # Núcleo da aplicação
│   ├── config/
│   │   └── app_config.dart              # Configurações centralizadas
│   ├── constants/                        # Constantes da aplicação
│   ├── errors/
│   │   ├── exceptions.dart              # Exceções customizadas
│   │   └── failures.dart                # Classes de falhas
│   ├── network/
│   │   └── api_client.dart              # Cliente HTTP (Dio)
│   ├── theme/                           # Temas e estilos
│   └── utils/                           # Utilitários gerais
│
├── 🎯 features/                          # Features (LoC)
│   └── auth/                            # Feature de autenticação (exemplo)
│       ├── 💾 data/                     # Camada de dados
│       │   ├── datasources/
│       │   │   ├── auth_local_datasource.dart
│       │   │   └── auth_remote_datasource.dart
│       │   ├── models/
│       │   │   └── user_model.dart
│       │   └── repositories/
│       │       └── auth_repository_impl.dart
│       │
│       ├── 🧠 domain/                   # Camada de domínio
│       │   ├── entities/
│       │   │   └── user.dart
│       │   ├── repositories/
│       │   │   └── auth_repository.dart
│       │   └── usecases/
│       │       ├── login_usecase.dart
│       │       └── signup_usecase.dart
│       │
│       └── 🎨 presentation/             # Camada de apresentação
│           ├── providers/
│           │   └── auth_provider.dart
│           ├── screens/
│           │   └── login_screen.dart
│           ├── state/
│           │   └── auth_state.dart
│           └── widgets/
│
└── 🔄 shared/                           # Componentes compartilhados
    ├── providers/                       # Providers globais
    ├── widgets/                         # Widgets reutilizáveis
    └── models/                          # Modelos compartilhados
```

## 📋 Arquivos Criados

### Core (Núcleo)
- ✅ `core/config/app_config.dart` - Configurações da aplicação
- ✅ `core/errors/exceptions.dart` - Exceções customizadas
- ✅ `core/errors/failures.dart` - Classes de falhas
- ✅ `core/network/api_client.dart` - Cliente HTTP com Dio

### Feature: Auth (Exemplo Completo)
#### Domain Layer
- ✅ `domain/entities/user.dart` - Entidade User
- ✅ `domain/repositories/auth_repository.dart` - Interface do repositório
- ✅ `domain/usecases/login_usecase.dart` - Caso de uso de login
- ✅ `domain/usecases/signup_usecase.dart` - Caso de uso de cadastro

#### Data Layer
- ✅ `data/models/user_model.dart` - Model com serialização JSON
- ✅ `data/datasources/auth_remote_datasource.dart` - DataSource remoto (API)
- ✅ `data/datasources/auth_local_datasource.dart` - DataSource local (cache)
- ✅ `data/repositories/auth_repository_impl.dart` - Implementação do repositório

#### Presentation Layer
- ✅ `presentation/state/auth_state.dart` - Estados de autenticação
- ✅ `presentation/providers/auth_provider.dart` - Providers Riverpod
- ✅ `presentation/screens/login_screen.dart` - Tela de login

### Documentação
- ✅ `README_ARCHITECTURE.md` - Documentação completa da arquitetura
- ✅ `QUICK_START.md` - Guia rápido de uso

## 🚀 Próximos Passos

### 1. Instalar Dependências

Adicione ao `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.0
  
  # Functional Programming
  dartz: ^0.10.1
  
  # HTTP Client
  dio: ^5.4.0
  
  # Local Storage
  shared_preferences: ^2.2.2
```

Execute:
```bash
flutter pub get
```

### 2. Configurar API Base URL

Edite `lib/core/config/app_config.dart`:
```dart
static const String apiBaseUrl = 'https://sua-api.com';
```

### 3. Criar Novas Features

Para cada nova feature, siga a estrutura:
```
features/[nome_feature]/
├── data/
├── domain/
└── presentation/
```

### 4. Executar a Aplicação

```bash
flutter run
```

## 🎯 Princípios da Arquitetura

### LoC (Logic over Components)
- ✅ Lógica separada dos componentes visuais
- ✅ Features independentes e auto-contidas
- ✅ Facilita testes e manutenção

### Riverpod
- ✅ Gerenciamento de estado reativo
- ✅ Injeção de dependências automática
- ✅ Type-safe e testável

### Arquitetura em Camadas
- ✅ **Domain**: Regras de negócio puras
- ✅ **Data**: Acesso e manipulação de dados
- ✅ **Presentation**: UI e gerenciamento de estado

## 📊 Fluxo de Dados

```
┌─────────────────────────────────────────────────────────┐
│                      PRESENTATION                        │
│  ┌──────────┐    ┌──────────┐    ┌──────────────────┐  │
│  │  Screen  │ -> │ Provider │ -> │ StateNotifier    │  │
│  └──────────┘    └──────────┘    └──────────────────┘  │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                        DOMAIN                            │
│  ┌──────────┐    ┌────────────┐    ┌────────────────┐  │
│  │ UseCase  │ -> │ Repository │ <- │    Entity      │  │
│  └──────────┘    │ Interface  │    └────────────────┘  │
│                  └────────────┘                          │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                         DATA                             │
│  ┌────────────┐    ┌────────────┐    ┌──────────────┐  │
│  │ Repository │ -> │ DataSource │ -> │    Model     │  │
│  │    Impl    │    │  (API/DB)  │    │ (DTO/JSON)   │  │
│  └────────────┘    └────────────┘    └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## 🧪 Testabilidade

Cada camada pode ser testada independentemente:

```dart
// Domain - Teste unitário puro
test('should validate email correctly', () {
  final result = useCase(email: 'invalid');
  expect(result.isLeft(), true);
});

// Data - Teste com mocks
test('should return user from API', () async {
  when(mockDataSource.login()).thenAnswer((_) async => tUserModel);
  final result = await repository.login();
  expect(result, Right(tUser));
});

// Presentation - Teste de widget
testWidgets('should show error message', (tester) async {
  await tester.pumpWidget(LoginScreen());
  expect(find.text('Error'), findsOneWidget);
});
```

## 📚 Documentação

- 📖 [README_ARCHITECTURE.md](README_ARCHITECTURE.md) - Arquitetura detalhada
- 🚀 [QUICK_START.md](QUICK_START.md) - Guia rápido de uso

## 💡 Dicas

1. **Sempre comece pela camada de domínio** - Defina suas entidades e regras de negócio primeiro
2. **Use Either<Failure, Success>** - Para tratamento de erros funcional
3. **Mantenha as camadas independentes** - Domain não deve conhecer Data ou Presentation
4. **Teste cada camada separadamente** - Facilita debugging e manutenção
5. **Use const constructors** - Para melhor performance

## 🎉 Pronto para Começar!

A estrutura está completa e pronta para uso. Comece criando suas próprias features seguindo o exemplo da feature `auth`.

Boa codificação! 🚀
