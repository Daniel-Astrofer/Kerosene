# Documentation Audit

Auditoria e limpeza das documentacoes Markdown do repositorio Kerosene. A leitura original cobriu os `.md` existentes, controllers Spring, DTOs, configuracoes, scripts e app Flutter.

## Decisao Canonica

A documentacao de produto fica centralizada em `docs/` com estes arquivos:

| Arquivo | Papel |
| --- | --- |
| `docs/API_REFERENCE.md` | Referencia completa da API atual, gerada a partir dos controllers e DTOs. |
| `docs/INFRASTRUCTURE.md` | Infraestrutura atual baseada em compose, scripts e propriedades Spring. |
| `docs/APP.md` | App Flutter mobile/web, rotas, HTTP, auth, Tor relay, realtime e features. |
| `docs/IMPLEMENTATION_NEXT_STEPS.md` | Proximos passos priorizados. |
| `docs/DOCUMENTATION_AUDIT.md` | Registro da auditoria e da limpeza. |
| `docs/README.md` | Indice canonico. |

## Documentacao Removida

Foram apagados os grupos que contradiziam ou duplicavam a fonte canonica atual:

| Grupo | Motivo |
| --- | --- |
| `backend/kerosene/API_REFERENCE.md`, `ARCHITECTURE.md`, `INFRASTRUCTURE.md`, `README.md` | Usavam nomenclatura Hydra v5.0 e contratos desatualizados. |
| `backend/kerosene/docs/*.md` | Duplicavam API, arquitetura, infraestrutura, configuracao e runbooks com cobertura inferior aos novos documentos. |
| `docs-final/*.md` | Consolidacao anterior, util para comparacao, mas nao reconciliada com os controllers e configs atuais. |
| Docs antigas em `docs/` | Substituidas por `API_REFERENCE.md`, `INFRASTRUCTURE.md`, `APP.md` e `IMPLEMENTATION_NEXT_STEPS.md`. |
| `docs/bitcoin-accounts/*.md` | Contratos parciais substituidos pela referencia completa de API e pela documentacao do app. |

## Itens Preservados Fora De `docs/`

Nao foram removidos nesta limpeza:

- `README.md` e `AGENTS.md` na raiz, porque sao contexto de projeto e instrucoes de trabalho.
- `.agent/**`, `.agents/**`, `frontend/.agent/**` e `frontend/.claude/**`, porque sao instrucoes/workflows de agentes, nao documentacao de produto.
- READMEs de assets/builds em `frontend/**`, `backend/kerosene/build/**` e `backend/kerosene/web-admin-build*`, porque sao artefatos de assets ou build output.
- Guias especificos do frontend, como `frontend/FRONTEND_GUIDELINES.md`, quando nao fazem parte da documentacao canonica do produto.

## Validacao Da Referencia Atual

`docs/API_REFERENCE.md` foi checado estaticamente contra os controllers:

- `148` secoes HTTP documentadas.
- `147` pares metodo/path unicos.
- `148` blocos `Headers`.
- `148` blocos `Request body`.
- `148` blocos `Response body`.
- Nenhum endpoint de controller ficou faltando na comparacao estatica.

## Manutencao

Novas documentacoes de produto devem entrar primeiro em um dos arquivos canonicos. Se uma area crescer demais, crie um novo documento em `docs/` e adicione o link em `docs/README.md`, evitando copias paralelas em subpastas de backend ou snapshots finais.
