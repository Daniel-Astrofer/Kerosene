# 🚀 Guia Rápido - Como Usar a Arquitetura

## 📋 Pré-requisitos

Adicione as seguintes dependências ao `pubspec.yaml`:

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

## 🏗️ Como Criar uma Nova Feature

### 1. Criar a Estrutura de Pastas

```
features/
└── [nome_da_feature]/
    ├── data/
    │   ├── datasources/
    │   ├── models/
    │   └── repositories/
    ├── domain/
    │   ├── entities/
    │   ├── repositories/
    │   └── usecases/
    └── presentation/
        ├── providers/
        ├── screens/
        ├── widgets/
        └── state/
```

### 2. Implementar de Baixo para Cima

#### **Passo 1: Domain Layer (Regras de Negócio)**

1. **Criar Entidade** (`domain/entities/`)
```dart
class Product {
  final String id;
  final String name;
  final double price;

  const Product({
    required this.id,
    required this.name,
    required this.price,
  });
}
```

2. **Criar Interface do Repositório** (`domain/repositories/`)
```dart
abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getProducts();
  Future<Either<Failure, Product>> getProductById(String id);
}
```

3. **Criar UseCase** (`domain/usecases/`)
```dart
class GetProductsUseCase {
  final ProductRepository repository;

  const GetProductsUseCase(this.repository);

  Future<Either<Failure, List<Product>>> call() async {
    return await repository.getProducts();
  }
}
```

#### **Passo 2: Data Layer (Acesso a Dados)**

1. **Criar Model** (`data/models/`)
```dart
class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.price,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      price: json['price'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
    };
  }

  Product toEntity() => Product(id: id, name: name, price: price);
}
```

2. **Criar DataSource** (`data/datasources/`)
```dart
abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts();
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final ApiClient apiClient;

  const ProductRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<ProductModel>> getProducts() async {
    final response = await apiClient.get('/products');
    final List<dynamic> data = response.data;
    return data.map((json) => ProductModel.fromJson(json)).toList();
  }
}
```

3. **Implementar Repositório** (`data/repositories/`)
```dart
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;

  const ProductRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      final products = await remoteDataSource.getProducts();
      return Right(products.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
```

#### **Passo 3: Presentation Layer (UI e Estado)**

1. **Criar Estado** (`presentation/state/`)
```dart
sealed class ProductState {}

class ProductInitial extends ProductState {}
class ProductLoading extends ProductState {}
class ProductLoaded extends ProductState {
  final List<Product> products;
  ProductLoaded(this.products);
}
class ProductError extends ProductState {
  final String message;
  ProductError(this.message);
}
```

2. **Criar Provider** (`presentation/providers/`)
```dart
// DataSource Provider
final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProductRemoteDataSourceImpl(apiClient);
});

// Repository Provider
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final remoteDataSource = ref.watch(productRemoteDataSourceProvider);
  return ProductRepositoryImpl(remoteDataSource);
});

// UseCase Provider
final getProductsUseCaseProvider = Provider<GetProductsUseCase>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return GetProductsUseCase(repository);
});

// StateNotifier
class ProductNotifier extends StateNotifier<ProductState> {
  final GetProductsUseCase getProductsUseCase;

  ProductNotifier(this.getProductsUseCase) : super(ProductInitial());

  Future<void> loadProducts() async {
    state = ProductLoading();
    final result = await getProductsUseCase();
    result.fold(
      (failure) => state = ProductError(failure.message),
      (products) => state = ProductLoaded(products),
    );
  }
}

// State Provider
final productProvider = StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  final useCase = ref.watch(getProductsUseCaseProvider);
  return ProductNotifier(useCase);
});
```

3. **Criar Screen** (`presentation/screens/`)
```dart
class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(productProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: switch (productState) {
        ProductInitial() => const Center(child: Text('Press button to load')),
        ProductLoading() => const Center(child: CircularProgressIndicator()),
        ProductLoaded(products: final products) => ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text('\$${product.price}'),
              );
            },
          ),
        ProductError(message: final message) => Center(
            child: Text('Error: $message'),
          ),
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(productProvider.notifier).loadProducts(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
```

## 🎯 Boas Práticas

### 1. **Separação de Responsabilidades**
- ✅ Domain: Apenas regras de negócio
- ✅ Data: Apenas acesso a dados
- ✅ Presentation: Apenas UI e estado

### 2. **Injeção de Dependências**
- ✅ Use Riverpod Providers
- ✅ Nunca instancie diretamente
- ✅ Sempre injete via construtor

### 3. **Tratamento de Erros**
- ✅ Use `Either<Failure, Success>` do Dartz
- ✅ Crie exceções específicas na camada de dados
- ✅ Converta exceções em Failures no repositório

### 4. **Testes**
```dart
// Domain - Teste unitário puro
test('should return user when login is successful', () async {
  // Arrange
  when(mockRepository.login(email: any, password: any))
      .thenAnswer((_) async => Right(tUser));
  
  // Act
  final result = await useCase(email: 'test@test.com', password: '123456');
  
  // Assert
  expect(result, Right(tUser));
});
```

## 📊 Fluxo de Dados Completo

```
User Action (UI)
    ↓
Provider.notifier.method()
    ↓
UseCase.call()
    ↓
Repository Interface
    ↓
Repository Implementation
    ↓
DataSource (API/Local)
    ↓
Model → Entity
    ↓
Either<Failure, Entity>
    ↓
State Update
    ↓
UI Rebuild
```

## 🔧 Comandos Úteis

```bash
# Rodar a aplicação
flutter run

# Rodar testes
flutter test

# Análise de código
flutter analyze

# Formatar código
flutter format .

# Limpar build
flutter clean
```

## 📚 Recursos Adicionais

- [Riverpod Docs](https://riverpod.dev/)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Dartz Package](https://pub.dev/packages/dartz)
- [Dio Package](https://pub.dev/packages/dio)
