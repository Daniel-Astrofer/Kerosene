# ✅ Checklist de Integração - Draggable Market Cards

## 📋 Pré-requisitos

- [x] `draggable_card_3d.dart` criado ✅
- [x] `draggable_card_demo.dart` criado ✅
- [x] `draggable_market_integration.dart` criado ✅
- [x] Documentação técnica pronta ✅

## 🔧 Etapas de Integração

### 1️⃣ **Importar no Market Screen**
```dart
// lib/features/market/presentation/screens/market_screen.dart

// Adicionar este import no topo:
import 'package:kerosene/shared/widgets/draggable_market_integration.dart';
```

### 2️⃣ **Opção A - Usar MarketCardWithDrag (Recomendado)**

Wrappear cards existentes com `MarketCardWithDrag`:

```dart
MarketCardWithDrag(
  onDismiss: () {
    // Remover card da lista
    setState(() => _visibleCards.remove('bitcoin'));
  },
  onRestore: () {
    // Restaurar card
    setState(() => _visibleCards.add('bitcoin'));
  },
  cardContent: _buildBitcoinCard(), // Card existente
)
```

**Vantagens:**
- ✅ Reutiliza cards existentes
- ✅ Mantém UI atual
- ✅ Adiciona funcionalidade drag suavemente
- ✅ Fácil rollback

### 3️⃣ **Opção B - Usar DraggableMarketScreen (Demo Completa)**

Usar como tela de teste/demo:

```dart
// No seu navigator/router:
DraggableMarketScreen()
```

**Vantagens:**
- ✅ Exemplo completo funcionando
- ✅ Mostra melhor prática
- ✅ Pronto para testes
- ✅ Cards de exemplo inclusos

### 4️⃣ **Testar Performance**

**DevTools Profiling:**
```
1. Run app com: flutter run --profile
2. Abrir DevTools (D key)
3. Ir para Performance tab
4. Fazer drag do card por 5+ segundos
5. Verificar frame rate (deve ser 120fps+)
```

**Checkpoint de Performance:**
- [ ] Frame time < 8ms
- [ ] Sem jank durante drag
- [ ] CPU < 50% utilização
- [ ] GPU <80% utilização
- [ ] Memory stable (sem crescimento)

### 5️⃣ **Validar em Dispositivos Reais**

- [ ] Galaxy S22 Ultra (120fps)
- [ ] iPhone 14 Pro (120fps)
- [ ] Android padrão (60fps)
- [ ] iPad (variável)

**Teste de Stress:**
```dart
// Repetir 50+ vezes:
1. Arrastar card 100% para cima
2. Deixar completar animação
3. Restaurar card
4. Repetir
```

### 6️⃣ **Testes de UX**

- [ ] Tooltip aparece corretamente ao toque
- [ ] Snackbar feedback funciona
- [ ] Dismiss placeholder mostra corretamente
- [ ] Restaurar volta ao estado normal
- [ ] Transição suave entre estados

### 7️⃣ **Integração com Dados Reais**

Substituir dados mockados por dados reais:

```dart
// Em _BitcoinCard(), usar Riverpod provider:
final bitcoinPrice = await ref.read(bitcoinPriceProvider);
final bitcoinChange = await ref.read(bitcoinChangeProvider);
```

**Providers a conectar:**
- [ ] `bitcoinPriceProvider`
- [ ] `bitcoinChangeProvider`
- [ ] `ethereumPriceProvider`
- [ ] `ethereumChangeProvider`
- [ ] `marketCapProvider`

### 8️⃣ **Customização Visual**

Ajustar cores/tamanhos conforme tema da app:

```dart
// Cores padrão usadas:
- Verde sucesso: #00FF94
- Azul info: #00D4FF
- Vermelho alerta: #FF0055
- Background: #0F1419
- Card bg: #1A1F3C

// Customizar em MarketCardWithDrag.dart se necessário
```

## 🚀 Deployment Checklist

### Pre-release
- [ ] Todos testes passando
- [ ] Performance validada
- [ ] Sem erros de compilação
- [ ] Build APK/IPA gerado
- [ ] Beta testers aprovam

### Release
- [ ] Versão bumped (pubspec.yaml)
- [ ] CHANGELOG.md atualizado
- [ ] Release notes escritas
- [ ] Deploy para stores

## 📊 Métricas de Sucesso

| Métrica | Target | Status |
|---------|--------|--------|
| Frame Rate | 120fps | 🟡 Pendente teste |
| Frame Time | <8ms | 🟡 Pendente teste |
| Memory | <150MB | 🟡 Pendente teste |
| Jank Count | 0 | 🟡 Pendente teste |
| User Satisfaction | >4.5★ | 🟡 Pendente review |

## 🐛 Troubleshooting

### Problema: Jank ao arrastar
**Solução:** Verificar DevTools Performance, confirmar Matrix4 está sendo usado

### Problema: Cards não restauram
**Solução:** Verificar callback `onRestore` está sendo acionado

### Problema: Performance baixa
**Solução:** Usar `draggable_card_3d_TUNING.md` para otimizações

### Problema: Cores não batem
**Solução:** Ajustar Color values em `draggable_market_integration.dart`

## ✅ Conclusão

Integração concluída quando todos os checkboxes acima estiverem ✅

**Status Atual:** 🟡 Pronto para integração
**Próximo Passo:** Importar em market_screen.dart e testar

---

📝 Atualizado: 12/02/2026
👤 Responsável: Development Team
🔗 Referência: `draggable_market_integration.dart`
