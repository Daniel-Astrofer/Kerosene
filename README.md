![Logo](./kerosene-logo.png)

# KEROSENE — DOCUMENTAÇÃO TÉCNICA ATUALIZADA (PRE-ALPHA-1.0.0)

[⬇️ Baixar APK mais recente](https://github.com/Daniel-Astrofer/Kerosene/releases/download/latest/app-release.apk)


![img1](./screenshots/screen%20(1).png) ![img2](./screenshots/screen%20(2).png) ![img3](./screenshots/screen%20(3).png) ![img4](./screenshots/screen%20(4).png)

![img5](./screenshots/screen%20(5).png) ![img6](./screenshots/screen%20(6).png) ![img7](./screenshots/screen%20(7).png) ![img8](./screenshots/screen%20(8).png) ![img9](./screenshots/screen%20(9).png)


Plataforma de pagamentos e custódia cripto, de código aberto, com múltiplas carteiras internas, autenticação forte e transações internas sem taxa.

## 1) Visão Geral

A Kerosene é uma plataforma custodial, onde:

*   O usuário controla suas chaves de acesso via passphrase BIP39.
*   A plataforma nunca armazena seeds de carteiras; apenas hashes necessários para débito das transferências.

A conta é protegida por duas camadas independentes:

*   **Passphrase BIP39 de login** (18 palavras) → acesso à conta.
*   **Passphrases BIP39 independentes das carteiras** → acesso aos saldos e autorização de transferências.

O sistema processa:

*   Pagamentos internos sem taxa.
*   Compra e venda P2P de criptomoedas (0.1% por operação).
*   Depósitos e retiradas de BTC com taxa de 1%.
*   Múltiplas carteiras (até 10 por usuário), cada uma com sua própria passphrase.

<div style="page-break-after: always;"></div>

## 2) Cadastro e Autenticação

### 2.1 Fluxo de Criação de Conta

Usuário informa:

*   Nome de usuário (único).
*   Passphrase BIP39 de 18 palavras (para login).

O sistema gera:

*   `totp_secret` exclusivo.
*   Registro temporário no Redis aguardando validação TOTP.

Usuário confirma o código TOTP. Após isso, os dados são persistidos no PostgreSQL.

Usuário envia:

*   Device hash
*   IP atual

Sistema cria:

*   Registro em `users_devices`
*   JWT de sessão para login inicial

### 2.2 Dados armazenados em users_credentials

| Campo | Descrição |
| :--- | :--- |
| `id` | PK |
| `username` | único |
| `passphrase_hash` | hash Argon2id da passphrase de login |
| `totp_secret` | criptografado (AES-256-GCM) |
| `created_at` | data |
| `status` | ativo / bloqueado |

**Importante:** A passphrase original nunca é salva, apenas um hash Argon2id de alta segurança.

### 2.3 Tabela users_devices

| Campo | Descrição |
| :--- | :--- |
| `id` | PK |
| `user_id` | FK para users_credentials |
| `device_hash` | identificador do dispositivo |
| `ip` | último IP |
| `created_at` | data |

JWT sempre vinculado ao `device_hash`.

<div style="page-break-after: always;"></div>

## 3) Estrutura de Carteiras Internas

Cada usuário pode ter até 10 carteiras independentes, cada uma protegida por sua própria passphrase BIP39.

O sistema armazena apenas:

*   Hash da carteira
*   Hash da passphrase da carteira
*   Saldo associado

As carteiras não são derivadas da passphrase de login. São outra camada de segurança.

**Por que isso existe?**

Para impedir que alguém com acesso à conta consiga mover valores sem a segunda passphrase.

<div style="page-break-after: always;"></div>

## 4) Transferências Internas

**Processo:**

1.  Usuário escolhe qual carteira deseja usar.
2.  Sistema solicita a passphrase da carteira.
3.  Passphrase é validada contra o hash salvo no banco.
4.  Transferência é criada e armazenada por 24 horas.

**Campos salvos temporariamente:**

| Campo | Descrição |
| :--- | :--- |
| `tx_id` | PK |
| `from_wallet_hash` | hash da carteira de origem |
| `to_username` | username destino |
| `amount` | valor |
| `created_at` | timestamp |
| `status` | pending, success, canceled |

**Após 24h:**

*   Se não houver contestação → remoção automática do registro.
*   Se houver contestação → análise manual / reversão.

**Taxa**

Transferências internas possuem taxa 0.

<div style="page-break-after: always;"></div>

## 5) Depósitos e Saques (BTC)

### Depósito BTC → Kerosene

*   **Taxa:** 1%
*   Após a confirmação on-chain, o saldo é creditado na carteira interna selecionada.

### Saque BTC → carteira externa

*   **Taxa:** 1%
*   A transação é assinada no cliente e enviada ao servidor para broadcasting.

<div style="page-break-after: always;"></div>

## 6) Home Broker Cripto (P2P)

Usuários negociam criptos entre si. A Kerosene apenas garante matching e liquidação interna.

**Taxas:**

*   Compra: 0.1%
*   Venda: 0.1%

A liquidação é feita usando carteiras internas.

<div style="page-break-after: always;"></div>

## 7) Segurança

*   Passphrases protegidas com Argon2id + salt único.
*   TOTP obrigatório para criação e acesso.
*   JWT vinculado ao `device_hash`.
*   Carteiras com passphrases independentes.
*   Transações expiram em 24h.
*   Nenhuma seed é salva no servidor.
*   Dados sensíveis sempre armazenados com AES-256-GCM.

<div style="page-break-after: always;"></div>

## 8) Modelo de Dados Simplificado

*   **users_credentials**
    *   (id, username, passphrase_hash, totp_secret, created_at)
*   **users_devices**
    *   (id, user_id, device_hash, ip, created_at)
*   **wallets**
    *   (id, user_id, wallet_hash, wallet_passphrase_hash, balance, created_at)
*   **internal_transactions**
    *   (id, from_wallet_hash, to_username, amount, created_at, status)
*   **p2p_orders**
    *   (id, user_id, asset, amount, price, type, status)

<div style="page-break-after: always;"></div>

## 9) Regras de Negócio

*   Username é único.
*   Cada carteira funciona como um “cofre” separado.
*   Transferência só acontece com:
    *   Passphrase da carteira
    *   Username destino
*   Depósitos e saques têm taxa fixa.
*   Transações internas têm taxa zero.
*   KYC é opcional e só usado para saques fiduciários.
*   Contestação de transações só dentro de 24h.
*   Após 24h, a transferência é definitiva.

<div style="page-break-after: always;"></div>

## 10) Arquitetura

*   Backend em ambientes multi-cloud.
*   Dados críticos em PostgreSQL.
*   Redis para cadastros temporários e rate limit.
*   JWT para sessões.
*   API stateless REST.
*   Logs sem PII.
*   Possibilidade futura de relays P2P.
