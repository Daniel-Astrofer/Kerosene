# Guia Visual - Aba de Gráficos

## 📸 Layout da Aba

```
┌─────────────────────────────────────┐
│  Bitcoin | 42,500.00 USD ↑ 5.23%    │  ← Header com preço atual
│  ⚪ LIVE                              │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  USD  EUR  BRL  GBP  JPY            │  ← Seletor de moeda
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  📈 Gráfico de Preço      │ 90 velas │
│                                     │
│     ╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲   │         │
│    ╱  ╲╱  ╲╱  ╲╱  ╲╱  ╲  │ $42.5K  │  ← Interactive chart
│   ╱    ╱    ╱    ╱    ╱  │ $41.2K  │
│  ╱    ╱    ╱    ╱    ╱   │         │
│                                     │
│  Toque em um ponto para ver:        │
│  • Preço de fechamento              │
│  • Abertura, máxima, mínima         │
│  • Data e hora exata                │
│  • Percentual de variação           │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  📊 Volume (24h)        │ 30 períodos│
│                                     │
│  ┃┃┃┃┃  ┃┃┃  ┃┃┃┃   ┃┃┃┃┃  ┃┃┃  │ ← Volume em cores
│  100%  50%  75%  90%  60%        │
│                                     │
│  ┌──────────┬──────────┬──────────┐│
│  │ 📈 Máx  │ ⚖️ Médio │ 📉 Mín  ││
│  │ 5.2M    │ 3.8M    │ 2.1M    ││
│  └──────────┴──────────┴──────────┘│
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  📊 Estatísticas do Período         │
│                                     │
│  ┌──────────────┬──────────────┐   │
│  │ 📈 Máxima    │ 📉 Mínima    │   │
│  │ $45,300.00   │ $39,800.00   │   │
│  ├──────────────┼──────────────┤   │
│  │ 📊 Variação  │ 📈 Touros    │   │
│  │ +6.35%       │ 72.5%        │   │
│  └──────────────┴──────────────┘   │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  1H  1D  1W  1M  3M  1Y            │  ← Seletor de período
└─────────────────────────────────────┘
```

## 🎨 Cores por Estado

### Estado Bullish (Alta)
- **Cor Principal**: `#00FF94` (Verde vibrante)
- **Uso**: Barras de volume, tendência positiva
- **Opacidade**: 70% para barras, 25% para área de preenchimento

### Estado Bearish (Baixa)
- **Cor Principal**: `#FF0055` (Vermelho/Rosa)
- **Uso**: Barras de volume, tendência negativa
- **Opacidade**: 70% para barras, 25% para área de preenchimento

### Cores de UI
- **Texto Primário**: Branco (FFFFFF)
- **Texto Secundário**: Branco 50% (FFFFFF80)
- **Grid**: Branco 3% (FFFFFF08)
- **Border**: Branco 10-30% (FFFFFF1A-4D)

## 📊 Exemplo de Tooltip

```
Quando o usuário toca o gráfico:

┌─────────────────────┐
│ Fechamento: $42,560 │  ← Preço atual da vela
│ Abertura: $41,800   │
│ Alta: $42,890       │
│ Baixa: $41,200      │
│ Data/Hora: 12/02 14:32 │
└─────────────────────┘
```

## 📱 Responsividade

### iPhone (375px)
- Gráfico: 320px de altura
- Cards: Stack vertical
- Volume stats: 3 cards em linha (comprimidos)

### iPad (768px)
- Gráfico: 380px de altura
- Cards: 2x2 grid
- Volume stats: 3 cards em linha (espaçado)

### Desktop (1920px)
- Gráfico: 450px de altura
- Cards: Maximizados
- Volume stats: 3 cards em linha (muito espaçado)

## 🔢 Exemplos de Formatação

### Preços
```
$0.45 → $0.45
$123.56 → $123.56
$1,234.56 → $1.23K
$45,300.00 → $45.30K
$1,234,567.00 → $1.23M
$1,000,000,000 → $1.00B
```

### Volumes
```
500 → 500
5,000 → 5K
50,000 → 50K
500,000 → 500K
5,000,000 → 5M
500,000,000 → 500M
5,000,000,000 → 5B
```

### Tempo (por período)
```
1H:  14:30, 15:45, 16:20
1D:  Feb 12, Feb 13, Feb 14
1W:  Feb 12, Feb 19, Feb 26
1M:  Jan 15, Feb 15, Mar 15
3M:  Feb, Mar, Apr
1Y:  Feb, May, Aug
```

## 🎯 Casos de Uso

### Para Iniciantes
1. Ver a tendência geral com as cores (verde = subida, vermelho = queda)
2. Comparar máxima e mínima do período
3. Entender o volume comparativo
4. Ver o percentual de variação

### Para Profissionais
1. Analisar OHLC (Open, High, Low, Close) de cada vela
2. Correlacionar preço com volume
3. Identificar pontos de suporte/resistência
4. Calcular volatilidade (diferença entre máxima e mínima)
5. Análise de touros vs ursos (bullish vs bearish candles)

## 🚀 Interações Disponíveis

### Touch (Mobile)
```dart
- Toque simples: Mostra tooltip com OHLC + data
- Arrasto: Navegação suave pelo gráfico (futura melhoria)
- Double-tap: Zoom (futura melhoria)
```

### Click (Desktop)
```dart
- Click simples: Mostra tooltip com OHLC + data
- Hover: Preview rápido
- Scroll: Zoom (futura melhoria)
```

## 📊 Indicadores Calculados

### Já Implementados
- ✅ **O (Open)**: Preço de abertura
- ✅ **H (High)**: Máxima do período
- ✅ **L (Low)**: Mínima do período
- ✅ **C (Close)**: Preço de fechamento
- ✅ **V (Volume)**: Volume do período
- ✅ **Bullish %**: Percentual de velas em alta
- ✅ **Bearish %**: Percentual de velas em baixa
- ✅ **Period Change %**: Variação total do período

### Sugeridos para Futuro
- 📌 **RSI (Relative Strength Index)**
- 📌 **MACD (Moving Average Convergence Divergence)**
- 📌 **Bollinger Bands**
- 📌 **Moving Average (SMA, EMA)**
- 📌 **Suporte/Resistência**

## 🎨 Paleta de Cores Completa

```javascript
// Primárias
$green-bullish: #00FF94   // Verde vibrante
$red-bearish:  #FF0055   // Vermelho/Rosa
$blue-accent:  #00D4FF   // Azul ciano

// Neutras
$white-primary:    #FFFFFF    // Branco puro
$white-secondary:  #FFFFFF80  // Branco 50%
$white-tertiary:   #FFFFFF40  // Branco 25%
$white-quaternary: #FFFFFF20  // Branco 12%

// Fundos
$bg-dark: #0F1419      // Fundo escuro principal
$bg-glass: #1A1F3C    // Fundo glass effect

// Status
$status-live:     #00FF94  // Conectado
$status-offline:  #FFA500  // Desconectado
```

## 📈 Animações

### Entrada
- Fade-in: 800ms
- Scale: 0.95 → 1.0 (900ms)
- Slide: top (400ms)

### Hover/Toque
- Point highlight: 200ms
- Color transition: 300ms
- Scale: 1.0 → 1.1 (100ms)

### Saída
- Fade-out: 300ms

---

**Versão**: 2.0  
**Data**: Fevereiro 2026  
**Status**: Produção ✅
