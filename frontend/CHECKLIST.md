# ✅ Checklist de Implementação

## 📦 1. Configuração Inicial

- [ ] Adicionar dependências ao `pubspec.yaml`:
  ```yaml
  dependencies:
    flutter_riverpod: ^2.4.0
    dartz: ^0.10.1
    dio: ^5.4.0
    shared_preferences: ^2.2.2
    intl: ^0.18.0
  ```

- [ ] Executar `flutter pub get`

- [ ] Configurar `API_BASE_URL` em `lib/core/config/app_config.dart`

- [ ] Verificar se o `main.dart` está configurado corretamente

## 🎨 2. Criar Nova Feature

### Exemplo: Feature "Products"

#### Domain Layer (Começar aqui!)

- [ ] **Criar Entidade** (`features/products/domain/entities/product.dart`)
  ```dart
  class Product {
    final String id;
    final String name;
    final double price;
    // ... outros campos
  }
  ```

- [ ] **Criar Interface do Repositório** (`features/products/domain/repositories/product_repository.dart`)
  ```dart
  abstract class ProductRepository {
    Future<Either<Failure, List<Product>>> getProducts();
    Future<Either<Failure, Product>> getProductById(String id);
  }
  ```

- [ ] **Criar UseCases** (`features/products/domain/usecases/`)
  - [ ] `get_products_usecase.dart`
  - [ ] `get_product_by_id_usecase.dart`
  - [ ] Outros casos de uso necessários

#### Data Layer

- [ ] **Criar Model** (`features/products/data/models/product_model.dart`)
  ```dart
  class ProductModel extends Product {
    factory ProductModel.fromJson(Map<String, dynamic> json) { }
    Map<String, dynamic> toJson() { }
    Product toEntity() { }
  }
  ```

- [ ] **Criar Remote DataSource** (`features/products/data/datasources/product_remote_datasource.dart`)
  - [ ] Implementar chamadas à API
  - [ ] Tratar erros e exceções

- [ ] **Criar Local DataSource** (se necessário)
  - [ ] Implementar cache local
  - [ ] Usar SharedPreferences ou Hive

- [ ] **Implementar Repositório** (`features/products/data/repositories/product_repository_impl.dart`)
  - [ ] Coordenar DataSources
  - [ ] Converter Exceptions em Failures
  - [ ] Retornar Either<Failure, Entity>

#### Presentation Layer

- [ ] **Criar Estados** (`features/products/presentation/state/product_state.dart`)
  ```dart
  sealed class ProductState {}
  class ProductInitial extends ProductState {}
  class ProductLoading extends ProductState {}
  class ProductLoaded extends ProductState { final List<Product> products; }
  class ProductError extends ProductState { final String message; }
  ```

- [ ] **Criar Providers** (`features/products/presentation/providers/product_provider.dart`)
  - [ ] Provider do DataSource
  - [ ] Provider do Repository
  - [ ] Provider dos UseCases
  - [ ] StateNotifierProvider

- [ ] **Criar Screens** (`features/products/presentation/screens/`)
  - [ ] Lista de produtos
  - [ ] Detalhes do produto
  - [ ] Outras telas necessárias

- [ ] **Criar Widgets** (`features/products/presentation/widgets/`)
  - [ ] Widgets reutilizáveis da feature

## 🧪 3. Testes

### Testes Unitários (Domain)

- [ ] Testar entidades
- [ ] Testar casos de uso
- [ ] Testar validações

### Testes de Integração (Data)

- [ ] Testar DataSources com mocks
- [ ] Testar Repository
- [ ] Testar conversão Model ↔ Entity

### Testes de Widget (Presentation)

- [ ] Testar Screens
- [ ] Testar Widgets
- [ ] Testar StateNotifier

## 🎯 4. Boas Práticas

### Código

- [ ] Usar `const` constructors sempre que possível
- [ ] Adicionar documentação (///) em classes e métodos públicos
- [ ] Seguir convenções de nomenclatura do Dart
- [ ] Usar sealed classes para estados
- [ ] Implementar `==` e `hashCode` em entidades

### Arquitetura

- [ ] Domain não depende de nada
- [ ] Data depende apenas de Domain
- [ ] Presentation depende de Domain e Data
- [ ] Usar Either<Failure, Success> para retornos
- [ ] Separar lógica de negócio da UI

### Performance

- [ ] Usar `const` widgets
- [ ] Implementar lazy loading quando necessário
- [ ] Cachear dados quando apropriado
- [ ] Otimizar rebuilds com Riverpod

## 📝 5. Documentação

- [ ] Atualizar README.md com informações da feature
- [ ] Documentar endpoints da API
- [ ] Criar diagramas se necessário
- [ ] Documentar decisões arquiteturais importantes

## 🚀 6. Deploy

- [ ] Configurar variáveis de ambiente
- [ ] Testar em diferentes plataformas (iOS, Android, Web)
- [ ] Configurar CI/CD
- [ ] Preparar build de produção

## 📊 7. Monitoramento

- [ ] Implementar analytics (se necessário)
- [ ] Configurar crash reporting
- [ ] Adicionar logging apropriado
- [ ] Monitorar performance

## 🔄 8. Manutenção

- [ ] Revisar e refatorar código regularmente
- [ ] Atualizar dependências
- [ ] Corrigir bugs reportados
- [ ] Adicionar novos testes conforme necessário

---

## 💡 Dicas Rápidas

### Ordem de Implementação Recomendada

1. **Domain** → Define o que sua aplicação faz
2. **Data** → Define como os dados são obtidos
3. **Presentation** → Define como é apresentado ao usuário

### Comandos Úteis

```bash
# Rodar aplicação
flutter run

# Rodar testes
flutter test

# Análise de código
flutter analyze

# Formatar código
flutter format .

# Gerar código (se usar build_runner)
flutter pub run build_runner build --delete-conflicting-outputs

# Limpar build
flutter clean
```

### Atalhos do VS Code

- `Ctrl + .` → Quick Fix
- `F2` → Rename
- `Ctrl + Shift + R` → Refactor
- `Ctrl + Space` → Autocomplete

---

## ✨ Exemplo Completo

Veja a feature `auth` como exemplo completo de implementação:
- ✅ Domain: Entidades, Repositórios, UseCases
- ✅ Data: Models, DataSources, Repository Implementation
- ✅ Presentation: States, Providers, Screens

Use como referência para criar suas próprias features!

---

**Última atualização**: 10/12/2025
