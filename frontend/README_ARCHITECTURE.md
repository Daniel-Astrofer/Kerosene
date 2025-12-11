# 🏗️ Arquitetura do Projeto - LoC + Riverpod + Camadas

Este projeto segue uma arquitetura **LoC (Logic over Components)** combinada com **Riverpod** para gerenciamento de estado e uma **arquitetura em camadas** para separação de responsabilidades.

## 📁 Estrutura de Pastas

```
lib/
├── core/                      # Núcleo da aplicação
│   ├── config/               # Configurações gerais (API URLs, env vars, etc.)
│   ├── constants/            # Constantes da aplicação
│   ├── errors/               # Classes de erro e exceções customizadas
│   ├── network/              # Cliente HTTP (Dio, interceptors, etc.)
│   ├── theme/                # Temas, cores, tipografia
│   └── utils/                # Utilitários gerais (formatters, validators, etc.)
│
├── features/                  # Features da aplicação (LoC)
│   └── [feature_name]/       # Cada feature tem sua própria pasta
│       ├── data/             # Camada de dados
│       │   ├── datasources/  # Fontes de dados (API, local storage)
│       │   ├── models/       # Modelos de dados (DTOs) com serialização
│       │   └── repositories/ # Implementação dos repositórios
│       │
│       ├── domain/           # Camada de domínio (regras de negócio)
│       │   ├── entities/     # Entidades do domínio (objetos puros)
│       │   ├── repositories/ # Interfaces/contratos dos repositórios
│       │   └── usecases/     # Casos de uso (lógica de negócio)
│       │
│       └── presentation/     # Camada de apresentação
│           ├── providers/    # Riverpod providers (StateNotifier, etc.)
│           ├── screens/      # Telas da feature
│           ├── widgets/      # Widgets específicos da feature
│           └── state/        # Classes de estado (se necessário)
│
├── shared/                    # Componentes compartilhados entre features
│   ├── providers/            # Providers globais (auth, theme, etc.)
│   ├── widgets/              # Widgets reutilizáveis
│   └── models/               # Modelos compartilhados
│
└── main.dart                 # Ponto de entrada da aplicação
```

## 🎯 Princípios da Arquitetura

### 1. **LoC (Logic over Components)**
- A lógica de negócio está separada dos componentes visuais
- Cada feature é independente e auto-contida
- Facilita testes e manutenção

### 2. **Arquitetura em Camadas**

#### **Camada de Domínio (Domain)**
- **Responsabilidade**: Regras de negócio puras
- **Contém**: Entidades, interfaces de repositórios, casos de uso
- **Não depende**: De nenhuma outra camada
- **Exemplo**: `User` entity, `AuthRepository` interface, `LoginUseCase`

#### **Camada de Dados (Data)**
- **Responsabilidade**: Acesso e manipulação de dados
- **Contém**: Implementações de repositórios, datasources, models
- **Depende**: Da camada de domínio
- **Exemplo**: `AuthRepositoryImpl`, `AuthRemoteDataSource`, `UserModel`

#### **Camada de Apresentação (Presentation)**
- **Responsabilidade**: Interface do usuário e gerenciamento de estado
- **Contém**: Screens, widgets, providers, states
- **Depende**: Das camadas de domínio e dados
- **Exemplo**: `LoginScreen`, `AuthProvider`, `AuthState`

### 3. **Riverpod para Gerenciamento de Estado**
- **Providers**: Gerenciam estado e dependências
- **StateNotifier**: Para estados complexos
- **FutureProvider/StreamProvider**: Para operações assíncronas
- **Injeção de dependências**: Automática via Riverpod

## 📝 Exemplo de Feature: Auth

```
features/auth/
├── data/
│   ├── datasources/
│   │   ├── auth_remote_datasource.dart      # API calls
│   │   └── auth_local_datasource.dart       # Local storage
│   ├── models/
│   │   └── user_model.dart                  # DTO com JSON serialization
│   └── repositories/
│       └── auth_repository_impl.dart        # Implementação do repositório
│
├── domain/
│   ├── entities/
│   │   └── user.dart                        # Entidade pura
│   ├── repositories/
│   │   └── auth_repository.dart             # Interface/contrato
│   └── usecases/
│       ├── login_usecase.dart               # Caso de uso de login
│       └── signup_usecase.dart              # Caso de uso de signup
│
└── presentation/
    ├── providers/
    │   └── auth_provider.dart               # Riverpod provider
    ├── screens/
    │   ├── login_screen.dart                # Tela de login
    │   └── signup_screen.dart               # Tela de cadastro
    ├── widgets/
    │   └── auth_button.dart                 # Widget customizado
    └── state/
        └── auth_state.dart                  # Estado da autenticação
```

## 🔄 Fluxo de Dados

```
UI (Screen/Widget)
    ↓
Provider (Riverpod)
    ↓
UseCase (Domain)
    ↓
Repository Interface (Domain)
    ↓
Repository Implementation (Data)
    ↓
DataSource (Data)
    ↓
API/Local Storage
```

## 🧪 Testabilidade

Cada camada pode ser testada independentemente:
- **Domain**: Testes unitários puros
- **Data**: Testes de integração com mocks
- **Presentation**: Testes de widgets e providers

## 📦 Dependências Recomendadas

```yaml
dependencies:
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  dio: ^5.4.0
  
dev_dependencies:
  build_runner: ^2.4.6
  riverpod_generator: ^2.3.0
  freezed: ^2.4.5
  json_serializable: ^6.7.1
  mockito: ^5.4.2
```

## 🚀 Começando

1. **Criar uma nova feature**:
   - Crie a estrutura de pastas em `features/[feature_name]`
   - Implemente as camadas de baixo para cima (domain → data → presentation)

2. **Adicionar um novo caso de uso**:
   - Crie a entidade em `domain/entities`
   - Defina o repositório em `domain/repositories`
   - Implemente o usecase em `domain/usecases`
   - Implemente o repositório em `data/repositories`
   - Crie o provider em `presentation/providers`
   - Construa a UI em `presentation/screens`

## 📚 Recursos

- [Riverpod Documentation](https://riverpod.dev/)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
