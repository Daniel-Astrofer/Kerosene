![Logo](./kerosene-logo.png)

# KEROSENE — DOCUMENTAÇÃO TÉCNICA ATUALIZADA (PRE-ALPHA-1.0.0)

[⬇️ Baixar APK mais recente](https://github.com/Daniel-Astrofer/Kerosene/releases/download/latest/app-release.apk)


![img1](./screenshots/screen%20(1).png) ![img2](./screenshots/screen%20(2).png) ![img3](./screenshots/screen%20(3).png) ![img4](./screenshots/screen%20(4).png)

![img5](./screenshots/screen%20(5).png) ![img6](./screenshots/screen%20(6).png) ![img7](./screenshots/screen%20(7).png) ![img8](./screenshots/screen%20(8).png) ![img9](./screenshots/screen%20(9).png)


Plataforma de pagamentos e custódia cripto, de código aberto, com múltiplas carteiras internas, autenticação forte e transações internas sem taxa.

# Kerosene — Documentação de Produto e Arquitetura (Atualizada)

## 1. Visão Geral

A **Kerosene** é uma plataforma financeira em **Bitcoin** focada em **privacidade**, **ausência de taxas internas**, **anti-censura** e **usabilidade para usuários e varejistas**.

O sistema opera com **saldo interno off-chain**, permitindo **transferências instantâneas sem taxas**, utilizando a **blockchain apenas para depósitos e saques**.

A Kerosene **não armazena histórico detalhado de transações** dos usuários e oferece modos avançados de privacidade como **Modo Tor** e **Modo Fantasma**.

---

## 2. Princípios Fundamentais

- Sem taxas para transferências internas  
- Privacidade por padrão  
- Anti-censura e alta disponibilidade  
- Escalabilidade para milhões de usuários  
- Simplicidade para varejistas  
- Custódia técnica com isolamento e segurança máxima  

---

## 3. Gestão de Saldo

### 3.1 Arquitetura de Saldo Interno

- Uma carteira BTC principal (seed de 24 palavras, alta entropia) recebe depósitos **on-chain**
- Cada usuário possui um **saldo interno** mantido fora da blockchain
- Transferências internas atualizam **apenas saldos (off-chain)**
- A blockchain é usada somente para:
  - Depósitos
  - Saques

---

### 3.2 Taxas

- **Zero taxa** para transferências internas
- **Taxa de rede** aplicada apenas em saques externos
- **Taxação progressiva automática** para movimentações acima de **100k/mês**, destinada a:
  - Reinvestimento na plataforma
  - Desenvolvimento local

---

## 4. Transferências e Pagamentos

### 4.1 Tipos de Transferência

- Transferência interna instantânea  
- Pagamentos via **QR Code**  
- Pagamentos via **NFC**  
- **Cheques digitais** com expiração  

---

### 4.2 Varejistas

- Recebimento instantâneo sem taxa  
- Liquidação imediata em saldo interno  
- QR dinâmico para cobrança  
- Integração simples, sem hardware especial  

---

## 5. Rede P2P de Compra e Venda de BTC

- Marketplace P2P interno  
- Compra e venda direta entre usuários  
- Liquidação via saldo interno  
- Matching automático  
- Proteções antifraude  
- Compatível com **Modo Tor**

---

## 6. WebSocket e Tempo Real

### 6.1 Uso de WebSocket

WebSocket é utilizado para:
- Atualização de saldo em tempo real  
- Cotações  
- Notificações  

---

### 6.2 Estratégia Híbrida

- WebSocket em redes normais  
- HTTPS como fallback  
- HTTPS preferencial quando o **Tor** estiver ativo  

---

## 7. Modo Tor

- Backend acessível via endereços **.onion**
- Comunicação via Tor opcional no aplicativo
- Proteção contra censura e rastreamento
- Botão ligar/desligar no app

---

## 8. Modo Fantasma

- Transações temporárias  
- Carteiras efêmeras  
- Apagamento automático de dados sensíveis  
- Ideal para pagamentos rápidos e privados  

---

## 9. Segurança

- Criptografia ponta a ponta  
- Proteção contra replay  
- Chaves protegidas (HSM ou hardware wallet)  
- Backend **stateless**  
- Auditoria interna contínua  

---

## 10. Infraestrutura

- Mínimo de **3 servidores ativos**  
- Failover automático  
- Escalabilidade horizontal  
- Relays P2P  
- Multi-cloud  

---

## 11. Aplicativo Mobile

- Modo Tor  
- Modo Fantasma  
- QR Code  
- NFC  
- WebSocket  
- P2P BTC  
- Interface clara focada em privacidade  

---

## 12. O que a Kerosene NÃO é

- Não é um banco tradicional  
- Não armazena histórico detalhado de transações  
- Não cobra taxas internas  
- Não depende de um único servidor  

---

## 13. Roadmap

### MVP
- Saldo interno  
- QR Code  
- WebSocket  
- Infraestrutura redundante  

### Fase 2
- Modo Tor  
- Modo Fantasma  
- P2P BTC  

### Fase 3
- Relays comunitários  
- Incentivos de rede  
- Expansão para varejo em larga escala  

