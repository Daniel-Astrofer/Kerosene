![Kerosene Logo](./kerosene-logo.png)

# KEROSENE  
### Plataforma Financeira em Bitcoin — Privacidade, Escalabilidade e Anti-Censura  
**Status:** Pre-Alpha `v1.0.0`

[⬇️ Download APK mais recente](https://github.com/Daniel-Astrofer/Kerosene/releases/latest)

---

## 📱 Screenshots

<p align="center">
  <img src="./screenshots/screen (1).png" width="220" />
  <img src="./screenshots/screen (2).png" width="220" />
  <img src="./screenshots/screen (3).png" width="220" />
</p>

<p align="center">
  <img src="./screenshots/screen (4).png" width="220" />
  <img src="./screenshots/screen (5).png" width="220" />
  <img src="./screenshots/screen (6).png" width="220" />
</p>

---

## Visão Geral

A **Kerosene** é uma plataforma financeira open-source baseada em **Bitcoin**, projetada para permitir **pagamentos, transferências e custódia** com foco em:

- Privacidade por padrão  
- Zero taxas internas  
- Resistência à censura  
- Usabilidade real para usuários e varejistas  

O sistema utiliza **saldo interno off-chain**, permitindo **transferências instantâneas**, utilizando a blockchain **apenas para depósitos e saques**.

---

## Princípios do Projeto

- Sem taxas para transferências internas  
- Arquitetura anti-censura  
- Alta disponibilidade  
- Escalável para milhões de usuários  
- Código aberto e auditável  

---

## Arquitetura de Saldo

- Carteira BTC principal para depósitos on-chain  
- Saldo interno individual por usuário  
- Transferências internas não utilizam blockchain  
- Blockchain usada apenas para:
  - Depósitos
  - Saques

---

## Transferências e Pagamentos

- Transferências internas instantâneas  
- Pagamentos via **QR Code**  
- Pagamentos via **NFC**  
- Cheques digitais com expiração  

---

## Privacidade

### Modo Tor
- Backend acessível via `.onion`
- Comunicação opcional via Tor
- Proteção contra rastreamento e censura

### Modo Fantasma
- Carteiras efêmeras
- Transações temporárias
- Apagamento automático de dados sensíveis

---

## Segurança

- Criptografia ponta a ponta  
- Proteção contra replay  
- Backend stateless  
- Isolamento de chaves  
- Auditoria contínua  

---

## Infraestrutura

- Múltiplos servidores ativos  
- Failover automático  
- Escalabilidade horizontal  
- Relays P2P  
- Multi-cloud  

---

## Roadmap

### MVP
- Saldo interno
- QR Code
- WebSocket
- Infraestrutura redundante

### Fase 2
- Modo Tor
- Modo Fantasma
- Marketplace P2P BTC

### Fase 3
- Relays comunitários
- Incentivos de rede
- Expansão para varejo

---

## Contribuição

Contribuições são bem-vindas.  
Veja `CONTRIBUTING.md` e utilize Pull Requests via branch `develop`.

---

## Licença

Este projeto é distribuído sob licença open-source.  
Consulte
