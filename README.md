![Kerosene Logo](./kerosene-logo.png)

# KEROSENE

### Plataforma Financeira em Bitcoin — Privacidade, Escalabilidade e Anti-Censura

**Status:** Pre-Alpha `v1.0.0`

[⬇️ Download APK mais recente](https://github.com/Daniel-Astrofer/Kerosene/releases/latest)

[📋 Project Board / Issues](https://github.com/users/Daniel-Astrofer/projects/2)

[🧪 Testar API (Scalar)](https://registry.scalar.com/@default-team-qjzm1/apis/openapi-definition/latest#tag/auth)

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

## Visão Geral Técnica

A **Kerosene** é uma plataforma financeira **open-source**, orientada a **custódia, pagamentos e transferências em Bitcoin**, projetada para operar de forma **anti-censura**, **privada** e **altamente escalável**.

A arquitetura separa claramente:

* **Liquidação on-chain (Bitcoin)** para depósitos e saques
* **Liquidação off-chain** para transferências internas instantâneas

---

## Stack Tecnológica

### Backend

* **Java 21**
* **Spring Boot / Spring WebFlux**
* **Gradle** (build e gerenciamento de dependências)
* **PostgreSQL** (persistência relacional)
* **Redis** (cache, sessões, rate-limit e eventos temporários)
* **WebSocket** (comunicação em tempo real)
* **API REST documentada via Scalar / OpenAPI**

### Frontend Mobile

* **Flutter**
* **Dart**
* Aplicação multiplataforma focada em **Android (APK disponível)**

---

## Arquitetura de Saldo

* Carteira BTC principal (hot/warm wallet) para depósitos
* Saldo interno individualizado por usuário
* Transferências internas **não utilizam blockchain**
* Blockchain utilizada apenas para:

  * Depósitos on-chain
  * Saques on-chain

Esse modelo permite:

* Transferências instantâneas
* Zero taxas internas
* Redução de custos operacionais

---

## Funcionalidades Principais

* Transferências internas instantâneas
* Pagamentos via **QR Code**
* Pagamentos via **NFC**
* Cheques digitais com expiração
* Comunicação em tempo real via WebSocket

---

## Privacidade e Anti-Censura

### Modo Tor

* Backend acessível via endereço `.onion`
* Comunicação opcional via rede Tor
* Mitigação de rastreamento e bloqueios geográficos

### Modo Fantasma

* Carteiras efêmeras
* Dados temporários
* Limpeza automática de informações sensíveis

---

## Segurança

* Criptografia ponta a ponta
* Proteção contra replay attacks
* Backend stateless
* Isolamento de chaves privadas
* Auditoria contínua de código

---

## Infraestrutura

* Arquitetura distribuída
* Escalabilidade horizontal
* Failover automático
* Relays P2P
* Ambiente multi-cloud

---

## Roadmap

### MVP

* Saldo interno
* QR Code
* WebSocket
* Infraestrutura redundante

### Fase 2

* Modo Tor
* Modo Fantasma
* Marketplace P2P BTC

### Fase 3

* Relays comunitários
* Incentivos de rede
* Expansão para varejo

---

## Contribuição

Contribuições são bem-vindas.
Utilize **Pull Requests** a partir da branch `develop`.

---

## Licença

Projeto distribuído sob licença open-source.
Consulte o arquivo de licença para mais informações.
