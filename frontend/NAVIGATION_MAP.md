# 🗺️ Mapa de Navegação do Projeto

## 📂 Onde Encontrar Cada Coisa

### 🎯 Começando

| Preciso de... | Vá para... |
|---------------|------------|
| 📖 Visão geral do projeto | `README.md` |
| 🚀 Começar rapidamente | `QUICK_START.md` |
| 📊 Ver resumo completo | `SUMMARY.md` |
| ✅ Checklist de implementação | `CHECKLIST.md` |
| 🏗️ Entender arquitetura | `README_ARCHITECTURE.md` |
| 📐 Ver diagramas | `ARCHITECTURE_DIAGRAM.md` |

---

## 🔧 Core (Funcionalidades Centrais)

### ⚙️ Configurações
```
lib/core/config/
└── app_config.dart          # URLs da API, timeouts, feature flags
```

**Quando usar**: Configurar API base URL, ambiente (dev/prod), timeouts

---

### 📝 Constantes
```
lib/core/constants/
└── app_constants.dart       # Endpoints, mensagens, validações, durações
```

**Quando usar**: Adicionar endpoints, mensagens de erro, limites de validação

---

### ⚠️ Tratamento de Erros
```
lib/core/errors/
├── exceptions.dart          # Exceções da camada de dados
└── failures.dart            # Falhas da camada de domínio
```

**Quando usar**: 
- `exceptions.dart` - Criar novas exceções para DataSources
- `failures.dart` - Criar novos tipos de falhas para UseCases

---

### 🌐 Rede
```
lib/core/network/
└── api_client.dart          # Cliente HTTP (Dio) com interceptors
```

**Quando usar**: Configurar interceptors, adicionar headers globais

---

### 🛠️ Utilitários
```
lib/core/utils/
├── validators.dart          # Validações (email, senha, CPF, etc.)
└── formatters.dart          # Formatações (data, moeda, telefone, etc.)
```

**Quando usar**:
- `validators.dart` - Validar inputs do usuário
- `formatters.dart` - Formatar dados para exibição

---

## 🎨 Features (Funcionalidades)

### 🔐 Auth (Exemplo Completo)

#### 🧠 Domain (Regras de Negócio)
```
lib/features/auth/domain/
├── entities/
│   └── user.dart                    # Entidade User (objeto puro)
├── repositories/
│   └── auth_repository.dart         # Interface do repositório
└── usecases/
    ├── login_usecase.dart           # Caso de uso de login
    └── signup_usecase.dart          # Caso de uso de cadastro
```

**Quando usar**:
- `entities/` - Criar novas entidades do domínio
- `repositories/` - Definir contratos de repositórios
- `usecases/` - Implementar lógica de negócio

---

#### 💾 Data (Acesso a Dados)
```
lib/features/auth/data/
├── datasources/
│   ├── auth_remote_datasource.dart  # Chamadas à API
│   └── auth_local_datasource.dart   # Cache local
├── models/
│   └── user_model.dart              # DTO com serialização JSON
└── repositories/
    └── auth_repository_impl.dart    # Implementação do repositório
```

**Quando usar**:
- `datasources/` - Fazer chamadas à API ou acessar cache
- `models/` - Criar DTOs com serialização JSON
- `repositories/` - Implementar contratos do domínio

---

#### 🎨 Presentation (Interface)
```
lib/features/auth/presentation/
├── providers/
│   └── auth_provider.dart           # Providers Riverpod
├── screens/
│   └── login_screen.dart            # Tela de login
├── state/
│   └── auth_state.dart              # Estados da feature
└── widgets/
    └── (widgets customizados)       # Widgets específicos
```

**Quando usar**:
- `providers/` - Criar providers Riverpod
- `screens/` - Criar novas telas
- `state/` - Definir estados da feature
- `widgets/` - Criar widgets reutilizáveis da feature

---

## 🔄 Shared (Compartilhado)

```
lib/shared/
├── providers/                       # Providers globais (tema, idioma, etc.)
├── widgets/                         # Widgets reutilizáveis (botões, cards, etc.)
└── models/                          # Modelos compartilhados
```

**Quando usar**:
- `providers/` - Providers usados em múltiplas features
- `widgets/` - Widgets usados em múltiplas features
- `models/` - Modelos compartilhados entre features

---

## 📱 Main

```
lib/
└── main.dart                        # Ponto de entrada da aplicação
```

**Quando usar**: Configurar ProviderScope, rotas, tema global

---

## 🎯 Fluxo de Trabalho

### 1️⃣ Criar Nova Feature

```
1. Crie a estrutura:
   features/[nome_feature]/
   ├── domain/
   ├── data/
   └── presentation/

2. Implemente nesta ordem:
   Domain → Data → Presentation
```

### 2️⃣ Adicionar Novo Endpoint

```
1. Adicione constante:
   core/constants/app_constants.dart

2. Crie DataSource:
   features/[feature]/data/datasources/

3. Use no Repository:
   features/[feature]/data/repositories/
```

### 3️⃣ Criar Nova Tela

```
1. Crie o arquivo:
   features/[feature]/presentation/screens/

2. Defina estados:
   features/[feature]/presentation/state/

3. Crie provider:
   features/[feature]/presentation/providers/

4. Adicione rota:
   lib/main.dart
```

### 4️⃣ Adicionar Validação

```
1. Adicione em:
   core/utils/validators.dart

2. Use no UseCase:
   features/[feature]/domain/usecases/
```

### 5️⃣ Formatar Dados

```
1. Adicione em:
   core/utils/formatters.dart

2. Use na UI:
   features/[feature]/presentation/screens/
```

---

## 🔍 Encontrar Exemplos

### Exemplo Completo de Feature
👉 `lib/features/auth/`

### Exemplo de UseCase
👉 `lib/features/auth/domain/usecases/login_usecase.dart`

### Exemplo de Repository
👉 `lib/features/auth/data/repositories/auth_repository_impl.dart`

### Exemplo de Provider
👉 `lib/features/auth/presentation/providers/auth_provider.dart`

### Exemplo de Screen
👉 `lib/features/auth/presentation/screens/login_screen.dart`

### Exemplo de State
👉 `lib/features/auth/presentation/state/auth_state.dart`

---

## 🆘 Resolução de Problemas

### Erro de Compilação
1. Execute: `flutter clean`
2. Execute: `flutter pub get`
3. Reinicie o IDE

### Provider não encontrado
1. Verifique se está dentro de `ProviderScope`
2. Verifique imports
3. Verifique se o provider foi criado

### Erro de serialização JSON
1. Verifique `fromJson` no Model
2. Verifique nomes dos campos
3. Verifique tipos de dados

### Estado não atualiza
1. Verifique se está usando `ref.watch()`
2. Verifique se `state =` está sendo chamado
3. Verifique se o widget é `ConsumerWidget`

---

## 📚 Referências Rápidas

### Criar Entidade
```dart
class Product {
  final String id;
  final String name;
  const Product({required this.id, required this.name});
}
```

### Criar Model
```dart
class ProductModel extends Product {
  const ProductModel({required super.id, required super.name});
  
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(id: json['id'], name: json['name']);
  }
  
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
```

### Criar UseCase
```dart
class GetProductUseCase {
  final ProductRepository repository;
  const GetProductUseCase(this.repository);
  
  Future<Either<Failure, Product>> call(String id) async {
    return await repository.getProduct(id);
  }
}
```

### Criar Provider
```dart
final productProvider = StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  final useCase = ref.watch(getProductUseCaseProvider);
  return ProductNotifier(useCase);
});
```

### Usar Provider na UI
```dart
class ProductScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productProvider);
    // ...
  }
}
```

---

## 🎓 Dicas de Navegação

### VS Code
- `Ctrl + P` - Buscar arquivo
- `Ctrl + Shift + F` - Buscar em todos os arquivos
- `F12` - Ir para definição
- `Alt + ←` - Voltar

### Android Studio
- `Ctrl + Shift + N` - Buscar arquivo
- `Ctrl + Shift + F` - Buscar em todos os arquivos
- `Ctrl + B` - Ir para definição
- `Ctrl + Alt + ←` - Voltar

---

**Última atualização**: 10/12/2025  
**Versão**: 1.0.0
