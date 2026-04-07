# APK Android

Documento do artefato Android existente no repositorio local em 2026-04-07.

## Artefato Atual

```text
frontend/build/app/outputs/flutter-apk/app-release.apk
```

Metadados do `output-metadata.json`:

| Campo | Valor |
| --- | --- |
| Tipo | `APK` |
| Variante | `release` |
| Output | `app-release.apk` |
| Application ID | `com.teste.kersosene` |
| Version name | `1.0.0` |
| Version code | `1` |
| Min SDK for dexing | `24` |

Metadados do arquivo:

| Campo | Valor |
| --- | --- |
| Tamanho | `51,369,097` bytes, aproximadamente `49M` |
| Modificado em | `2026-04-04 05:20:51 -0300` |
| SHA-1 | `94a0ded8109812bdcafc82cdba9202ebe71c1f66` |
| SHA-256 | `80158a61b982eb4db95cd010d63ca3d5b52d3e2215c8d9df046a6609db960582` |

## Publicacao no GitHub

Nao versionar APK dentro do Git. O diretorio `frontend/build/` esta ignorado e deve continuar assim.

Fluxo recomendado:

1. Criar uma GitHub Release, por exemplo `android-v1.0.0-pre-alpha`.
2. Anexar `frontend/build/app/outputs/flutter-apk/app-release.apk` como asset.
3. Colar no release notes:

```text
Kerosene Android APK
Application ID: com.teste.kersosene
Version: 1.0.0 (1)
Variant: release
SHA-1: 94a0ded8109812bdcafc82cdba9202ebe71c1f66
SHA-256: 80158a61b982eb4db95cd010d63ca3d5b52d3e2215c8d9df046a6609db960582
```

## Rebuild Local

Comandos esperados para rebuild:

```bash
cd frontend
flutter pub get
flutter build apk --release
```

Estado real desta sessao:

- `frontend/pubspec.yaml`, `frontend/pubspec.lock` e `frontend/analysis_options.yaml` nao estavam presentes no working tree local, embora existam no indice Git.
- `flutter --version` falhou no sandbox porque o Flutter tentou escrever no cache do SDK em `/home/omega/flutter/bin/cache/engine.stamp`.
- Portanto, o APK documentado acima e o artefato ja existente em `frontend/build`, nao um rebuild novo desta execucao.

Se o working tree local estiver no mesmo estado, restaure os manifests antes do rebuild:

```bash
git restore frontend/pubspec.yaml frontend/pubspec.lock frontend/analysis_options.yaml
```

Para ambiente CI, prefira gerar o APK em pipeline e anexar automaticamente em GitHub Releases, mantendo `frontend/build/**` fora do repositorio.
