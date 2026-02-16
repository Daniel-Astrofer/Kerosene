# 🧪 Guia de Teste - Aba de Gráficos

## ✅ Checklist de Funcionalidades

### Gráfico de Preço
- [ ] Gráfico carrega corretamente
- [ ] Curva é suave e contínua
- [ ] Eixo Y mostra valores formatados
- [ ] Eixo X mostra timestamps apropriados
- [ ] Grid horizontal é visível mas sutil
- [ ] Gradiente de preenchimento aparece embaixo da linha

### Interatividade
- [ ] Toque no gráfico mostra tooltip
- [ ] Tooltip exibe: Fechamento, Abertura, Alta, Baixa, Data/Hora
- [ ] Ponto tocado fica destacado (branco com borda)
- [ ] Tooltip desaparece ao deixar de tocar
- [ ] Tooltip segue o dedo do usuário

### Volume
- [ ] Gráfico de barras carrega
- [ ] Barras verdes para velas bullish
- [ ] Barras vermelhas para velas bearish
- [ ] Três cards de estatísticas aparecem abaixo
- [ ] Card "Máximo" mostra maior volume
- [ ] Card "Médio" mostra volume médio
- [ ] Card "Mínimo" mostra menor volume

### Estatísticas
- [ ] Grid 2x2 de estatísticas aparece
- [ ] "Máxima" mostra preço mais alto do período
- [ ] "Mínima" mostra preço mais baixo do período
- [ ] "Variação" calcula diferença corretamente
- [ ] "Touros" calcula percentual de velas bullish

### Período de Tempo
- [ ] Botão 1H funciona
- [ ] Botão 1D funciona
- [ ] Botão 1W funciona
- [ ] Botão 1M funciona
- [ ] Botão 3M funciona
- [ ] Botão 1Y funciona
- [ ] Dados carregam ao trocar período
- [ ] Rótulos de tempo mudam por período:
  - [ ] 1H: HH:mm
  - [ ] 1D: MMM dd
  - [ ] 1W: MMM dd
  - [ ] 1M: MMM dd
  - [ ] 3M: MMM
  - [ ] 1Y: MMM

### Moedas
- [ ] USD carrega corretamente
- [ ] EUR carrega corretamente
- [ ] BRL carrega corretamente
- [ ] GBP carrega corretamente
- [ ] JPY carrega corretamente
- [ ] Gráfico atualiza ao trocar moeda

### Formatação
- [ ] Preços < 1000 mostram "$X.XX"
- [ ] Preços 1K-1M mostram "$XXK"
- [ ] Preços 1M-1B mostram "$XXM"
- [ ] Preços > 1B mostram "$XXB"
- [ ] Volumes > 1000 mostram sufixos (K, M, B)

### Animações
- [ ] Tela faz fade-in ao carregar
- [ ] Gráfico faz scale-in suave
- [ ] Slide-in vindo do topo
- [ ] Transições são suaves (não quebradas)

### Desempenho
- [ ] Sem lag ao tocar no gráfico
- [ ] Smooth 60fps durante animações
- [ ] Carregamento < 2 segundos
- [ ] Sem memory leaks após longa interação

## 🧪 Cenários de Teste

### Cenário 1: Usuário Iniciante
1. Abre a aba de mercado
2. Vê Bitcoin com preço e tendência (cor)
3. Identifica se está em alta (verde) ou baixa (vermelho)
4. Vê o volume em cores intuitivas
5. Compreende as estatísticas principais

**Esperado**: Experiência clara e sem necessidade de conhecimento técnico

### Cenário 2: Profissional Analista
1. Abre período 1H
2. Toca no gráfico para ver dados OHLC
3. Compara com diferentes períodos
4. Analisa correlação preço-volume
5. Calcula volatilidade (max - min)
6. Identifica suporte/resistência visual

**Esperado**: Dados completos e precisos para análise técnica

### Cenário 3: Carregamento
1. App abre a tela de mercado
2. Gráfico carrega com skeleton/spinner
3. Dados aparecem após 1-2 segundos
4. Transição é suave
5. Sem erro se conexão falhar

**Esperado**: Carregamento gracioso com feedback visual

### Cenário 4: Interação Mobile
1. Toque no gráfico
2. Tooltip aparece (não sai da tela)
3. Arrasto horizontal (se implementado)
4. Zoom (se implementado)
5. Performance não degrada

**Esperado**: Responsividade e fluidez

### Cenário 5: Troca de Moeda
1. Usuário em USD
2. Muda para EUR
3. Gráfico recarrega com novos dados
4. Valores se atualizam
5. Tooltip mostra valor correto

**Esperado**: Atualização seamless com novos dados

## 🔍 Testes de Precisão de Dados

### Volume
```
Teste: Verificar se soma de volumes é lógica
Método: 
1. Anotar volume máximo
2. Anotar volume mínimo
3. Calcular média manualmente
4. Comparar com card "Médio"

Esperado: Valores muito próximos (diferença < 5%)
```

### Preço
```
Teste: Verificar se máxima/mínima são corretas
Método:
1. Verificar todos os preços no gráfico
2. Encontrar maior valor
3. Encontrar menor valor
4. Comparar com cards

Esperado: Máxima = maior valor, Mínima = menor valor
```

### Variação
```
Teste: Verificar cálculo de variação
Método:
1. Anotar primeiro preço de abertura
2. Anotar último preço de fechamento
3. Calcular: ((Close - Open) / Open) * 100
4. Comparar com card "Variação"

Esperado: Percentual correto com 2 casas decimais
```

## 📊 Testes de Dados Esperados

### Bitcoin Histórico (Exemplos)
```
Período 1D (1 dia):
- Candles: ~1 vela por hora = 24 velas
- X-axis labels: 6 rótulos aproximadamente
- Volume range: 5K-50M dependendo do dia

Período 1W (1 semana):
- Candles: ~1 vela por dia = 7 velas
- X-axis labels: Datas do mês
- Volume range: maior variedade

Período 1M (1 mês):
- Candles: ~30 velas
- X-axis labels: Datas principais
- Volume range: histórico mensal

Período 1Y (1 ano):
- Candles: ~365 velas
- X-axis labels: Meses
- Volume range: máximo histórico anual
```

## 🎨 Testes Visuais

### Cores Bullish
```
Verde esperado: #00FF94
Teste:
1. Abrir período com alta predominante
2. Verificar se barras são verdes
3. Verificar intensidade/opacidade
```

### Cores Bearish
```
Vermelho esperado: #FF0055
Teste:
1. Abrir período com baixa predominante
2. Verificar se barras são vermelhas
3. Verificar intensidade/opacidade
```

### Contraste
```
Teste:
1. Verificar se texto é legível sobre fundo
2. Verificar se labels são visíveis
3. Testar em modo claro (se aplicável)
```

## 🚨 Testes de Erro

### Sem Dados
```
Cenário: API retorna vazio
Esperado: Mensagem "Sem dados disponíveis"
Resultado: ___________
```

### Conexão Perdida
```
Cenário: WebSocket desconecta
Esperado: Status muda para "OFFLINE"
Resultado: ___________
```

### Dados Inválidos
```
Cenário: API retorna formato incorreto
Esperado: Erro tratado graciosamente
Resultado: ___________
```

## 📋 Relatório de Teste

```
Data do Teste: ___/___/_____
Testador: ___________________
Dispositivo: ________________
OS/Versão: __________________

Funcionalidades Testadas:    [ ] OK [ ] Falha [ ] Parcial
Interatividade:              [ ] OK [ ] Falha [ ] Parcial
Formatação:                  [ ] OK [ ] Falha [ ] Parcial
Desempenho:                  [ ] OK [ ] Falha [ ] Parcial
Animações:                   [ ] OK [ ] Falha [ ] Parcial

Bugs Encontrados:
- ________________________________
- ________________________________
- ________________________________

Sugestões:
- ________________________________
- ________________________________

Assinado: _______________________
```

## 🔧 Troubleshooting

### Gráfico não carrega
- [ ] Verificar conexão de internet
- [ ] Verificar se API está respondendo
- [ ] Verificar console para erros
- [ ] Forçar hot reload

### Tooltip não aparece
- [ ] Verificar se `_touchedCandleIndex` está sendo atualizado
- [ ] Verificar se dados estão corretos
- [ ] Testar em diferentes dispositivos

### Volume não mostra cores corretas
- [ ] Verificar lógica `candle.close >= candle.open`
- [ ] Verificar cores definidas
- [ ] Verificar opacidade

### Rótulos de tempo incorretos
- [ ] Verificar `_formatTimeLabel()` por período
- [ ] Verificar timezone do dispositivo
- [ ] Verificar formato de data

## ✨ Resultado Final Esperado

A aba de gráficos deve ser:
- ✅ Completa com dados OHLCV
- ✅ Intuitiva para iniciantes
- ✅ Profissional para traders
- ✅ Responsiva em todos os dispositivos
- ✅ Rápida e performática
- ✅ Visualmente atrativa
- ✅ Interativa e dinâmica
- ✅ Pronta para produção

---

**Status**: Pronto para testes  
**Versão**: 2.0  
**Data**: Fevereiro 2026
