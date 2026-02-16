# Documentação - Aba de Gráficos Completa

## 📊 Visão Geral

A aba de gráficos foi completamente reestruturada para fornecer uma experiência informativa tanto para usuários iniciantes quanto para profissionais. Inclui visualizações interativas, dados robustos e estatísticas detalhadas.

## 🎯 Componentes Principais

### 1. **Gráfico de Preço Interativo**
- **Localização**: Topo da aba
- **Funcionalidades**:
  - Visualização em linha com preenchimento degradado
  - Pontos interativos que destacam quando tocados
  - Tooltip completo mostrando:
    - Preço de fechamento
    - Preço de abertura
    - Máxima do período
    - Mínima do período
    - Data e hora exata
  - Grid de referência horizontal
  - Eixo Y com labels de preço formatados
  - Eixo X com labels de tempo (variam por período selecionado)

#### Detalhes Técnicos:
```dart
- 320 pixels de altura
- Curvatura suave (curveSmoothness: 0.35)
- Pontos destacáveis com raio de 6px quando tocados
- Área preenchida com gradiente de 25% para 0% de opacidade
```

### 2. **Indicador de Vela Tocada**
- Quando o usuário toca em um ponto do gráfico:
  - Data/hora formatada
  - Preço de fechamento destacado
  - Percentual de variação da vela (abertura vs fechamento)

### 3. **Gráfico de Volume (Avançado)**
Exibição robusta de volume com múltiplas camadas de informação:

#### Sub-componentes:
1. **Gráfico de Barras Principal** (120px)
   - Barras verde para velas de alta (candles bullish)
   - Barras vermelhas para velas de baixa (candles bearish)
   - Background translúcido mostrando 100% da escala
   - Grid horizontal com intervalos de 25%
   - Até 40 períodos exibidos

2. **Cards de Estatísticas de Volume**
   - **Máximo**: Maior volume no período
   - **Médio**: Volume médio do período
   - **Mínimo**: Menor volume no período
   - Cada card mostra ícone, label e valor formatado

### 4. **Estatísticas do Período**
Grid 2x2 exibindo:
- **Máxima**: Maior preço no período
- **Mínima**: Menor preço no período
- **Variação**: Diferença percentual (início vs fim)
- **Touros**: Percentual de velas bullish

## 🎨 Design & Visualização

### Cores Utilizadas:
- **Bullish (Alta)**: `#00FF94` (Verde)
- **Bearish (Baixa)**: `#FF0055` (Vermelho)
- **Trend Color**: Dinâmica baseada na tendência
- **Background**: Transparência com Glass Effect

### Animações:
- Fade-in ao carregar
- Scale suave
- Slide-in do topo
- Highlight de pontos com transição

### Responsividade:
- Adapta-se a diferentes tamanhos de tela
- Cards escaláveis
- Gráficos com proporciona mantida

## 📅 Períodos de Tempo

Os períodos disponíveis são:
- **1H**: 1 hora - Exibe label em HH:mm
- **1D**: 1 dia - Exibe label em MMM dd
- **1W**: 1 semana - Exibe label em MMM dd
- **1M**: 1 mês - Exibe label em MMM dd
- **3M**: 3 meses - Exibe label em MMM
- **1Y**: 1 ano - Exibe label em MMM

## 🔢 Formatação de Dados

### Preços:
```
< 1000: $X.XX
1000-1M: $XXK (com 2 casas decimais)
1M-1B: $XXM (com 2 casas decimais)
> 1B: $XXB (com 2 casas decimais)
```

### Volumes:
```
< 1000: Número inteiro
1000-1M: XXK
1M-1B: XXM
> 1B: XXB
```

## 📱 Estrutura do Código

### Métodos Principais:
1. **`_buildCandlestickChart()`**: Gráfico principal de preço
   - 380px de altura total
   - LineChart com dados OHLC

2. **`_buildAdvancedVolumeChart()`**: Volume completo
   - BarChart com cores dinâmicas
   - 3 cards de estatísticas

3. **`_buildChartStatistics()`**: Estatísticas do período
   - Grid 2x2 com métricas calculadas

4. **Helper Methods**:
   - `_formatPrice()`: Formata preços com sufixos (K, M, B)
   - `_formatLargeNumber()`: Formata números grandes
   - `_formatTimeLabel()`: Formata rótulos de tempo conforme período
   - `_formatDateTime()`: Formata data/hora para tooltip

### Estado:
```dart
int? _touchedCandleIndex; // Rastreia qual vela foi tocada
```

## 💡 Funcionalidades para Profissionais

1. **Tooltip Completo**: Mostra O, H, L, C (Open, High, Low, Close)
2. **Análise de Volume**: Máximo, mínimo e média com cores
3. **Estatísticas**: Range de preço, percentual de variação, análise bullish/bearish
4. **Interatividade**: Toque para ver detalhes específicos de qualquer ponto

## 👥 Funcionalidades para Iniciantes

1. **Cores Intuitivas**: Verde para alta, vermelho para baixa
2. **Labels Claros**: Descrições simples de cada métrica
3. **Ícones Informativos**: Visualmente claros
4. **Formatação Legível**: Números com sufixos (K, M) para melhor compreensão

## 🚀 Recursos Implementados

- ✅ Gráfico interativo com múltiplas layers de dados
- ✅ Tooltip com data, hora e valores OHLC
- ✅ Volume com 3 camadas de informação
- ✅ Estatísticas calculadas em tempo real
- ✅ Formatação dinâmica baseada em magnitude
- ✅ Suporte a múltiplos períodos de tempo
- ✅ Design responsivo e profissional
- ✅ Animações suaves
- ✅ Cores dinâmicas baseadas em tendência

## 📊 Tipos de Dados

### Candle (Vela):
```dart
class Candle {
  final double open;       // Preço de abertura
  final double high;       // Máxima do período
  final double low;        // Mínima do período
  final double close;      // Preço de fechamento
  final double volume;     // Volume do período
  final DateTime time;     // Timestamp
}
```

## 🔧 Personalização

Para personalizar cores, tamanhos ou formatos:

1. **Cores**: Altere constantes `Color(0xFF00FF94)` e `Color(0xFFFF0055)`
2. **Tamanhos**: Modifique `SizedBox(height: XXX)`
3. **Formatos**: Altere métodos `_formatPrice()`, etc.
4. **Precisão**: Mudar `.toStringAsFixed(2)` para mais/menos casas decimais

## 📝 Próximas Melhorias Sugeridas

1. Adicionar suporte a múltiplas moedas com conversão
2. Implementar linhas de suporte/resistência
3. Adicionar indicadores técnicos (RSI, MACD, etc.)
4. Exportar dados em CSV/PDF
5. Adicionar comparação de períodos
6. Alarmes de preço customizáveis

---

**Última atualização**: Fevereiro 2026
**Versão**: 2.0
**Status**: Pronto para produção ✅
