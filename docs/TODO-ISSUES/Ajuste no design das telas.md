# Ajuste no design das telas 



## Ajustar

### /home/omega/Kerosene/frontend/lib/features/settings/presentation/screens



``` 
<!-- Segurança - Configurações Avançadas -->
<!DOCTYPE html><html class="dark" lang="pt-BR" style=""><head>
<meta charset="utf-8">
<meta content="width=device-width, initial-scale=1.0" name="viewport">
<title>Segurança - Configurações</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Manrope:wght@300;400;500;700&amp;family=Newsreader:ital,opsz,wght@0,6..72,200..800;1,6..72,200..800&amp;display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet">
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    "colors": {
                        "outline-variant": "#444748",
                        "surface-container-low": "#1c1b1b",
                        "primary-container": "#e2e2e2",
                        "surface-container-lowest": "#0e0e0e",
                        "on-secondary-fixed-variant": "#6b3b00",
                        "inverse-on-surface": "#313030",
                        "surface-container": "#201f1f",
                        "surface-variant": "#353534",
                        "surface-container-highest": "#353534",
                        "inverse-primary": "#5d5f5f",
                        "primary-fixed": "#e2e2e2",
                        "on-surface-variant": "#c4c7c8",
                        "tertiary-fixed-dim": "#40e18d",
                        "on-surface": "#e5e2e1",
                        "surface-tint": "#c6c6c6",
                        "tertiary-fixed": "#63fea7",
                        "on-error-container": "#ffdad6",
                        "on-tertiary-fixed": "#00210f",
                        "on-background": "#e5e2e1",
                        "on-tertiary-fixed-variant": "#00522d",
                        "error-container": "#93000a",
                        "secondary-container": "#e78603",
                        "primary-fixed-dim": "#c6c6c6",
                        "on-secondary-container": "#522c00",
                        "on-primary-container": "#636465",
                        "tertiary": "#ffffff",
                        "surface-bright": "#3a3939",
                        "secondary": "#ffb874",
                        "on-primary-fixed": "#1a1c1c",
                        "on-tertiary": "#00391e",
                        "on-primary": "#2f3131",
                        "secondary-fixed": "#ffdcbf",
                        "background": "#000000", /* Modified to pure black per request */
                        "outline": "#8e9192",
                        "tertiary-container": "#63fea7",
                        "primary": "#ffffff",
                        "on-tertiary-container": "#007442",
                        "surface-container-high": "#141414",
                        "surface-dim": "#0a0a0a",
                        "on-error": "#690005",
                        "inverse-surface": "#e5e2e1",
                        "surface": "#000000",
                        "on-secondary-fixed": "#2d1600",
                        "on-primary-fixed-variant": "#454747",
                        "on-secondary": "#4b2800",
                        "secondary-fixed-dim": "#ffb874",
                        "error": "#ffb4ab"
                    },
                    "borderRadius": {
                        "DEFAULT": "0.25rem",
                        "lg": "0.5rem",
                        "xl": "0.75rem",
                        "full": "9999px"
                    },
                    "spacing": {
                        "gutter": "24px",
                        "stack-gap": "16px",
                        "section-margin": "32px",
                        "container-padding": "24px"
                    },
                    "fontFamily": {
                        "numeric-display": ["Manrope"],
                        "body-md": ["Manrope"],
                        "display-lg": ["Newsreader"],
                        "label-caps": ["Manrope"],
                        "body-lg": ["Manrope"],
                        "headline-md": ["Newsreader"]
                    },
                    "fontSize": {
                        "numeric-display": ["32px", {"lineHeight": "1", "letterSpacing": "-0.01em", "fontWeight": "300"}],
                        "body-md": ["14px", {"lineHeight": "1.5", "fontWeight": "400"}],
                        "display-lg": ["40px", {"lineHeight": "1.1", "letterSpacing": "-0.02em", "fontWeight": "500"}],
                        "label-caps": ["11px", {"lineHeight": "1.2", "letterSpacing": "0.1em", "fontWeight": "700"}],
                        "body-lg": ["16px", {"lineHeight": "1.6", "fontWeight": "400"}],
                        "headline-md": ["32px", {"lineHeight": "1.2", "fontWeight": "500"}]
                    }
                },
            },
        }
    </script>
<style>
        body { background-color: #000000; color: #e5e2e1; -webkit-font-smoothing: antialiased; }
        .material-symbols-outlined {
            font-variation-settings: 'FILL' 0, 'wght' 300, 'GRAD' 0, 'opsz' 24;
        }
        .glass-card {
            background: #0A0A0A;
            border: 1px solid #1A1A1A;
        }
        .custom-switch {
            width: 44px;
            height: 24px;
            background-color: #353534;
            border-radius: 9999px;
            position: relative;
            transition: background-color 0.2s;
        }
        .custom-switch.active {
            background-color: #ffffff;
        }
        .custom-switch .thumb {
            width: 18px;
            height: 18px;
            background-color: #ffffff;
            border-radius: 50%;
            position: absolute;
            top: 3px;
            left: 3px;
            transition: transform 0.2s;
        }
        .custom-switch.active .thumb {
            transform: translateX(20px);
            background-color: #000000;
        }
    </style>
</head>
<body class="font-body-md min-h-screen flex flex-col items-center">
<!-- Top Navigation Bar -->
<header class="w-full top-0 sticky z-50 bg-background/80 backdrop-blur-md border-b border-surface-variant h-16 flex items-center justify-between px-gutter max-w-7xl mx-auto">
<button class="p-2 -ml-2 rounded-full hover:bg-surface-container-high transition-colors active:opacity-80">
<span class="material-symbols-outlined text-primary">arrow_back</span>
</button>

<button class="p-2 -mr-2 rounded-full hover:bg-surface-container-high transition-colors active:opacity-80">

</button>
</header>
<main class="w-full max-w-md px-6 py-8 pb-32 space-y-section-margin">
<!-- Hero Section -->
<section class="space-y-4">
<h2 class="font-headline-md text-headline-md text-primary tracking-tight">Segurança</h2>
<p class="font-body-lg text-body-lg text-on-surface-variant leading-relaxed">
                Proteja sua conta com autenticação, acesso local e controles de recuperação.
            </p>
</section>
<!-- PROTEÇÃO DE ACESSO -->
<section class="space-y-4">
<h3 class="font-label-caps text-label-caps text-on-surface-variant tracking-[0.15em]">PROTEÇÃO DE ACESSO</h3>
<div class="glass-card rounded-xl overflow-hidden">
<!-- Item: Alterar PIN -->
<div class="flex items-center p-4 hover:bg-surface-container-high transition-colors cursor-pointer group">
<div class="w-10 h-10 rounded-full bg-surface-container flex items-center justify-center mr-4 border border-surface-variant">
<span class="material-symbols-outlined text-primary text-[20px]">lock</span>
</div>
<div class="flex-1">
<div class="font-body-md font-medium text-primary">Alterar PIN</div>
<div class="text-[12px] text-on-surface-variant">Atualize seu código de 4 dígitos</div>
</div>
<span class="material-symbols-outlined text-on-surface-variant/40 group-hover:text-primary transition-colors">chevron_right</span>
</div>
<div class="mx-4 border-t border-surface-variant/30"></div>
<!-- Item: Biometria -->
<div class="flex items-center p-4">
<div class="w-10 h-10 rounded-full bg-surface-container flex items-center justify-center mr-4 border border-surface-variant">
<span class="material-symbols-outlined text-primary text-[20px]">fingerprint</span>
</div>
<div class="flex-1">
<div class="font-body-md font-medium text-primary">Biometria</div>
<div class="text-[12px] text-on-surface-variant">Usar digital para entrar no app</div>
</div>
<div class="custom-switch active cursor-pointer" onclick="this.classList.toggle('active')">
<div class="thumb"></div>
</div>
</div>
<div class="mx-4 border-t border-surface-variant/30"></div>
<!-- Item: Autenticação em 2 fatores -->
<div class="flex items-center p-4">
<div class="w-10 h-10 rounded-full bg-surface-container flex items-center justify-center mr-4 border border-surface-variant">
<span class="material-symbols-outlined text-primary text-[20px]" data-weight="fill" style="font-variation-settings: 'FILL' 1;">verified_user</span>
</div>
<div class="flex-1">
<div class="font-body-md font-medium text-primary">Autenticação em 2 fatores</div>
<div class="text-[12px] text-on-surface-variant">Adicionar uma camada extra de segurança</div>
</div>
<div class="custom-switch active cursor-pointer" onclick="this.classList.toggle('active')">
<div class="thumb"></div>
</div>
</div>
</div>
</section>
<!-- SESSÕES E DISPOSITIVOS -->
<section class="space-y-4">
<h3 class="font-label-caps text-label-caps text-on-surface-variant tracking-[0.15em]">SESSÕES E DISPOSITIVOS</h3>
<div class="glass-card rounded-xl overflow-hidden">
<!-- Item: Dispositivos autorizados -->
<div class="flex items-center p-4 hover:bg-surface-container-high transition-colors cursor-pointer group">
<div class="w-10 h-10 rounded-full bg-surface-container flex items-center justify-center mr-4 border border-surface-variant">
<span class="material-symbols-outlined text-primary text-[20px]">phone_iphone</span>
</div>
<div class="flex-1">
<div class="font-body-md font-medium text-primary">Dispositivos autorizados</div>
<div class="text-[12px] text-on-surface-variant">iPhone 11 • Este dispositivo</div>
</div>
<span class="material-symbols-outlined text-on-surface-variant/40 group-hover:text-primary transition-colors">chevron_right</span>
</div>
<div class="mx-4 border-t border-surface-variant/30"></div>
<!-- Item: Sessões ativas -->
<div class="flex items-center p-4 hover:bg-surface-container-high transition-colors cursor-pointer group">
<div class="w-10 h-10 rounded-full bg-surface-container flex items-center justify-center mr-4 border border-surface-variant">
<span class="material-symbols-outlined text-primary text-[20px]">desktop_windows</span>
</div>
<div class="flex-1">
<div class="font-body-md font-medium text-primary">Sessões ativas</div>
<div class="text-[12px] text-on-surface-variant">Gerencie acessos em outros aparelhos</div>
</div>
<span class="material-symbols-outlined text-on-surface-variant/40 group-hover:text-primary transition-colors">chevron_right</span>
</div>
</div>
</section>
<!-- RECUPERAÇÃO -->
<section class="space-y-4">
<h3 class="font-label-caps text-label-caps text-on-surface-variant tracking-[0.15em]">RECUPERAÇÃO</h3>
<div class="glass-card rounded-xl overflow-hidden">
<!-- Item: Recuperação da conta -->
<div class="flex items-center p-4 hover:bg-surface-container-high transition-colors cursor-pointer group">
<div class="w-10 h-10 rounded-full bg-surface-container flex items-center justify-center mr-4 border border-surface-variant">
<span class="material-symbols-outlined text-primary text-[20px]">mail</span>
</div>
<div class="flex-1">
<div class="font-body-md font-medium text-primary">Recuperação da conta</div>
<div class="text-[12px] text-on-surface-variant">E-mail e métodos de recuperação</div>
</div>
<span class="material-symbols-outlined text-on-surface-variant/40 group-hover:text-primary transition-colors">chevron_right</span>
</div>
<div class="mx-4 border-t border-surface-variant/30"></div>
<!-- Item: Backup de segurança -->
<div class="flex items-center p-4 hover:bg-surface-container-high transition-colors cursor-pointer group">
<div class="w-10 h-10 rounded-full bg-surface-container flex items-center justify-center mr-4 border border-surface-variant">
<span class="material-symbols-outlined text-primary text-[20px]">cloud_download</span>
</div>
<div class="flex-1">
<div class="font-body-md font-medium text-primary">Backup de segurança</div>
<div class="text-[12px] text-on-surface-variant">Salvar códigos de recuperação</div>
</div>
<span class="material-symbols-outlined text-on-surface-variant/40 group-hover:text-primary transition-colors">chevron_right</span>
</div>
</div>
</section>
<!-- Footer Actions -->
<footer class="space-y-8 pt-4">
<div class="flex items-start gap-4 px-1">


</div>
<div class="text-center">

</div>
</footer>
</main>
<!-- Fixed Action Button at Bottom -->
<div class="fixed bottom-0 left-0 w-full p-6 bg-gradient-to-t from-black via-black/80 to-transparent flex justify-center z-50">

</div>
<!-- Navigation Bar Anchor (Filtered Out per task rules for task-focused screen) -->
<!-- BottomNavBar would be here if it wasn't suppressed by shell visibility logic -->


</body></html>

<!-- Configurações - Ajuste sua conta -->
<!DOCTYPE html><html lang="pt-BR" style=""><head>
<meta charset="utf-8">
<meta content="width=device-width, initial-scale=1.0" name="viewport">
<title>Ajuste sua conta - Configurações</title>
<!-- Tailwind CSS v3 -->
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<!-- Fonts: Newsreader for Serifs, Inter for UI -->
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&amp;family=Newsreader:opsz,wght@6-72,400;500;600&amp;display=swap" rel="stylesheet">
<script>
    tailwind.config = {
      theme: {
        extend: {
          fontFamily: {
            sans: ['Inter', 'sans-serif'],
            serif: ['Newsreader', 'serif'],
          },
          colors: {
            'ios-black': '#000000',
            'ios-card': '#1C1C1E',
            'ios-text-secondary': '#8E8E93',
            'ios-selected': '#2C2C2E',
          }
        }
      }
    }
  </script>
<style data-purpose="custom-layout">
    body {
      background-color: #000000;
      color: #ffffff;
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
      width: 414px; /* iPhone 11 width */
      height: 896px; /* iPhone 11 height */
      margin: 0 auto;
      overflow-x: hidden;
      position: relative;
    }
    
    /* Hide scrollbar for a cleaner mobile app look */
    ::-webkit-scrollbar {
      display: none;
    }

    .glass-effect {
      background: rgba(255, 255, 255, 0.05);
      backdrop-filter: blur(10px);
    }
    
    .list-item-active {
      background-color: #2C2C2E;
      border: 1px solid rgba(255, 255, 255, 0.1);
      border-radius: 12px;
    }

    /* Fixed button at bottom logic */
    .sticky-footer {
      position: absolute;
      bottom: 20px;
      left: 0;
      right: 0;
      padding: 0 24px;
      background: linear-gradient(to top, rgba(0,0,0,1) 80%, rgba(0,0,0,0));
    }
  </style>
</head>
<body class="font-sans">
<!-- BEGIN: MainHeader -->
<header class="pt-12 px-6 flex items-center justify-between mb-8">
<button aria-label="Voltar" class="w-10 h-10 rounded-full flex items-center justify-center bg-zinc-900">
<svg fill="none" height="20" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" viewBox="0 0 24 24" width="20" xmlns="http://www.w3.org/2000/svg"><path d="m15 18-6-6 6-6"></path></svg>
</button>
<h1 class="text-sm font-medium tracking-wide text-zinc-300"><br></h1>
<div class="w-10"></div> <!-- Spacer for centering -->
</header>
<!-- END: MainHeader -->
<main class="px-6 pb-40">
<!-- BEGIN: HeroSection -->
<section class="mb-10" data-purpose="hero-title">
<h2 class="font-serif text-4xl mb-4 leading-tight">Ajuste sua conta</h2>
<p class="text-zinc-400 text-base leading-relaxed">
        Gerencie segurança, privacidade e preferências da sua experiência bancária.
      </p>
</section>
<!-- END: HeroSection -->
<!-- BEGIN: PreferencesList -->
<section data-purpose="preferences-navigation">
<h3 class="text-xs font-bold tracking-widest text-zinc-500 uppercase mb-4">Preferências</h3>
<div class="space-y-2">
<!-- Perfil -->
<div class="flex items-center p-3 -mx-3 cursor-pointer">
<div class="w-12 h-12 rounded-full flex items-center justify-center bg-zinc-900 text-zinc-300 mr-4">
<svg fill="none" height="20" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" viewBox="0 0 24 24" width="20" xmlns="http://www.w3.org/2000/svg"><path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>
</div>
<div class="flex-1">
<p class="text-white font-medium">Perfil</p>
<p class="text-zinc-500 text-xs">Dados pessoais e informações da conta</p>
</div>
<svg class="text-zinc-600" fill="none" height="18" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" viewBox="0 0 24 24" width="18" xmlns="http://www.w3.org/2000/svg"><path d="m9 18 6-6-6-6"></path></svg>
</div>
<!-- Segurança (Highlighted in image) -->
<div class="flex items-center p-3 -mx-3 cursor-pointer list-item-active">
<div class="w-12 h-12 rounded-full flex items-center justify-center bg-zinc-800 text-zinc-300 mr-4">
<svg fill="none" height="20" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" viewBox="0 0 24 24" width="20" xmlns="http://www.w3.org/2000/svg"><rect height="11" rx="2" ry="2" width="18" x="3" y="11"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg>
</div>
<div class="flex-1">
<p class="text-white font-medium">Segurança</p>
<p class="text-zinc-500 text-xs">Senha, biometria e autenticação em 2 fatores</p>
</div>
<svg class="text-zinc-600" fill="none" height="18" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" viewBox="0 0 24 24" width="18" xmlns="http://www.w3.org/2000/svg"><path d="m9 18 6-6-6-6"></path></svg>
</div>
<!-- Privacidade -->
<div class="flex items-center p-3 -mx-3 cursor-pointer">
<div class="w-12 h-12 rounded-full flex items-center justify-center bg-zinc-900 text-zinc-300 mr-4">
<svg fill="none" height="20" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" viewBox="0 0 24 24" width="20" xmlns="http://www.w3.org/2000/svg"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"></path><circle cx="12" cy="12" r="3"></circle></svg>
</div>
<div class="flex-1">
<p class="text-white font-medium">Privacidade</p>
<p class="text-zinc-500 text-xs">Visibilidade, compartilhamento e permissões</p>
</div>
<svg class="text-zinc-600" fill="none" height="18" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" viewBox="0 0 24 24" width="18" xmlns="http://www.w3.org/2000/svg"><path d="m9 18 6-6-6-6"></path></svg>
</div>
<!-- Notificações -->
<div class="flex items-center p-3 -mx-3 cursor-pointer">
<div class="w-12 h-12 rounded-full flex items-center justify-center bg-zinc-900 text-zinc-300 mr-4">
<svg fill="none" height="20" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" viewBox="0 0 24 24" width="20" xmlns="http://www.w3.org/2000/svg"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"></path><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"></path></svg>
</div>
<div class="flex-1">
<p class="text-white font-medium">Notificações</p>
<p class="text-zinc-500 text-xs">Alertas de transações e comunicações</p>
</div>
<svg class="text-zinc-600" fill="none" height="18" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" viewBox="0 0 24 24" width="18" xmlns="http://www.w3.org/2000/svg"><path d="m9 18 6-6-6-6"></path></svg>
</div>
<!-- Limites -->
<div class="flex items-center p-3 -mx-3 cursor-pointer">
<div class="w-12 h-12 rounded-full flex items-center justify-center bg-zinc-900 text-zinc-300 mr-4">
<svg fill="none" height="20" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" viewBox="0 0 24 24" width="20" xmlns="http://www.w3.org/2000/svg"><path d="m3 16 4 4 4-4"></path><path d="M7 20V4"></path><path d="m21 8-4-4-4 4"></path><path d="M17 4v16"></path></svg>
</div>
<div class="flex-1">
<p class="text-white font-medium">Limites</p>
<p class="text-zinc-500 text-xs">Transferências, pagamentos e saques</p>
</div>
<svg class="text-zinc-600" fill="none" height="18" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" viewBox="0 0 24 24" width="18" xmlns="http://www.w3.org/2000/svg"><path d="m9 18 6-6-6-6"></path></svg>
</div>
<!-- Moeda padrão -->
<div class="flex items-center p-3 -mx-3 cursor-pointer">
<div class="w-12 h-12 rounded-full flex items-center justify-center bg-zinc-900 text-zinc-300 mr-4">
<span class="text-xs font-bold">R$</span>
</div>
<div class="flex-1">
<p class="text-white font-medium">Moeda padrão</p>
<p class="text-zinc-500 text-xs">BRL, BTC e preferências de exibição</p>
</div>
<svg class="text-zinc-600" fill="none" height="18" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" viewBox="0 0 24 24" width="18" xmlns="http://www.w3.org/2000/svg"><path d="m9 18 6-6-6-6"></path></svg>
</div>
<!-- Ajuda e suporte -->
<div class="flex items-center p-3 -mx-3 cursor-pointer">
<div class="w-12 h-12 rounded-full flex items-center justify-center bg-zinc-900 text-zinc-300 mr-4">
<svg fill="none" height="20" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" viewBox="0 0 24 24" width="20" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="10"></circle><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"></path><path d="M12 17h.01"></path></svg>
</div>
<div class="flex-1">
<p class="text-white font-medium">Ajuda e suporte</p>
<p class="text-zinc-500 text-xs">Central de ajuda e contato</p>
</div>
<svg class="text-zinc-600" fill="none" height="18" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" viewBox="0 0 24 24" width="18" xmlns="http://www.w3.org/2000/svg"><path d="m9 18 6-6-6-6"></path></svg>
</div>
</div>
</section>
<!-- END: PreferencesList -->
<!-- BEGIN: FooterLinks -->
<div class="mt-12 text-center" data-purpose="account-actions">
<button class="text-zinc-500 text-sm border-b border-dashed border-zinc-700 pb-0.5"></button>
</div>
<!-- END: FooterLinks -->
</main>
<!-- BEGIN: BottomAction -->
<footer class="sticky-footer">

</footer>
<!-- END: BottomAction -->




</body></html>
```

 ### /home/omega/Kerosene/frontend/lib/features/bitcoin_accounts/presentation/bitcoin_accounts_screen.dart



```
<!DOCTYPE html>

<html lang="pt-br"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Carteira Interna - Gerenciamento Completo</title>
<!-- Tailwind CSS CDN -->
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<!-- Google Fonts -->
<link href="https://fonts.googleapis.com" rel="preconnect"/>
<link crossorigin="" href="https://fonts.gstatic.com" rel="preconnect"/>
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500&amp;family=Inter:wght@400;500;600&amp;family=Newsreader:opsz,wght@6-72,400;500&amp;display=swap" rel="stylesheet"/>
<script>
    tailwind.config = {
      theme: {
        extend: {
          fontFamily: {
            'newsreader': ['Newsreader', 'serif'],
            'inter': ['Inter', 'sans-serif'],
            'mono': ['IBM Plex Mono', 'monospace'],
          },
          colors: {
            'app-black': '#000000',
            'card-dark': '#1A1A1A',
            'accent-orange': '#E28C44',
            'muted-text': '#8E8E93',
          }
        }
      }
    }
  </script>
<style data-purpose="custom-layout">
    body {
      background-color: #000000;
      color: #FFFFFF;
      font-family: 'Inter', sans-serif;
      /* Mimic iPhone 11 aspect ratio and scaling for preview */
      max-width: 414px;
      margin: 0 auto;
      min-height: 100vh;
      overflow-x: hidden;
    }

    /* Custom gradient for the main card */
    .card-gradient {
      background: linear-gradient(135deg, #222222 0%, #111111 100%);
      position: relative;
      overflow: hidden;
    }
    
    .card-gradient::after {
      content: "";
      position: absolute;
      top: -20%;
      right: -10%;
      width: 150px;
      height: 150px;
      background: radial-gradient(circle, rgba(255,255,255,0.05) 0%, rgba(0,0,0,0) 70%);
      border-radius: 50%;
    }

    .hide-scrollbar::-webkit-scrollbar {
      display: none;
    }
  </style>
</head>
<body class="hide-scrollbar">
<!-- BEGIN: MainHeader -->
<header class="flex items-center justify-between px-6 py-6 sticky top-0 bg-black z-50">
<button class="text-white hover:opacity-70 transition-opacity" data-purpose="back-button">
<svg fill="none" height="24" stroke="currentColor" stroke-width="2" viewbox="0 0 24 24" width="24" xmlns="http://www.w3.org/2000/svg">
<path d="M10 19l-7-7m0 0l7-7m-7 7h18" stroke-linecap="round" stroke-linejoin="round"></path>
</svg>
</button>
<h1 class="text-2xl font-newsreader font-normal text-white">Carteira Interna</h1>
<div class="w-6"></div> <!-- Spacer to center title -->
</header>
<!-- END: MainHeader -->
<main class="px-5 space-y-8">
<!-- BEGIN: InvestmentCard -->
<section data-purpose="main-wallet-display">
<div class="card-gradient rounded-[32px] p-8 border border-white/10 shadow-2xl">
<div class="flex flex-col space-y-6">
<span class="text-[10px] tracking-[0.2em] font-medium text-muted-text uppercase">Investimento</span>
<div class="space-y-1">
<h2 class="text-[26px] font-newsreader text-white leading-tight">Otavio S. Souza</h2>
<span class="text-accent-orange text-xs font-semibold tracking-wider">ONCHAIN</span>
</div>
<div class="flex items-center justify-between pt-4">
<span class="font-mono text-muted-text text-sm tracking-tighter">bc1q...z2n0</span>
<button class="bg-white/10 p-2.5 rounded-xl hover:bg-white/20 transition-colors">
<svg fill="none" height="18" stroke="white" stroke-width="2" viewbox="0 0 24 24" width="18" xmlns="http://www.w3.org/2000/svg">
<rect height="13" rx="2" ry="2" width="13" x="9" y="9"></rect>
<path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
</svg>
</button>
</div>
</div>
</div>
<!-- Pagination Dots -->
<div class="flex justify-center space-x-1.5 mt-4">
<div class="w-1.5 h-1.5 rounded-full bg-muted-text/30"></div>
<div class="w-1.5 h-1.5 rounded-full bg-white"></div>
<div class="w-1.5 h-1.5 rounded-full bg-muted-text/30"></div>
</div>
</section>
<!-- END: InvestmentCard -->
<!-- BEGIN: CreateWalletAction -->
<section class="flex flex-col items-center justify-center space-y-2" data-purpose="action-buttons">
<button class="w-14 h-14 bg-white rounded-full flex items-center justify-center shadow-lg active:scale-95 transition-transform">
<svg fill="none" height="28" stroke="black" stroke-width="2.5" viewbox="0 0 24 24" width="28" xmlns="http://www.w3.org/2000/svg">
<path d="M12 4.5v15m7.5-7.5h-15" stroke-linecap="round" stroke-linejoin="round"></path>
</svg>
</button>
<span class="text-xs font-medium text-white/90">Criar carteira</span>
</section>
<!-- END: CreateWalletAction -->
<!-- BEGIN: ManagementList -->
<section class="space-y-3" data-purpose="management-settings">
<!-- Status -->
<div class="flex items-center justify-between bg-card-dark p-4 px-5 rounded-2xl border border-white/5 cursor-pointer">
<div class="flex items-center space-x-4">
<svg class="text-white" fill="none" height="20" stroke="currentColor" stroke-width="1.5" viewbox="0 0 24 24" width="20" xmlns="http://www.w3.org/2000/svg">
<path d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" stroke-linecap="round" stroke-linejoin="round"></path>
</svg>
<span class="text-sm font-medium text-white/90">Status da carteira</span>
</div>
<svg class="text-muted-text" fill="none" height="20" stroke="currentColor" stroke-width="2" viewbox="0 0 24 24" width="20" xmlns="http://www.w3.org/2000/svg">
<path d="M19 9l-7 7-7-7" stroke-linecap="round" stroke-linejoin="round"></path>
</svg>
</div>
<!-- Address -->
<div class="flex items-center justify-between bg-card-dark p-4 px-5 rounded-2xl border border-white/5 cursor-pointer">
<div class="flex items-center space-x-4">
<svg class="text-white" fill="none" height="20" stroke="currentColor" stroke-width="1.5" viewbox="0 0 24 24" width="20" xmlns="http://www.w3.org/2000/svg">
<path d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" stroke-linecap="round" stroke-linejoin="round"></path>
</svg>
<span class="text-sm font-medium text-white/90">Endereço de recebimento</span>
</div>
<svg class="text-muted-text" fill="none" height="20" stroke="currentColor" stroke-width="2" viewbox="0 0 24 24" width="20" xmlns="http://www.w3.org/2000/svg">
<path d="M19 9l-7 7-7-7" stroke-linecap="round" stroke-linejoin="round"></path>
</svg>
</div>
<!-- Name -->
<div class="flex items-center justify-between bg-card-dark p-4 px-5 rounded-2xl border border-white/5 cursor-pointer">
<div class="flex items-center space-x-4">
<svg class="text-white" fill="none" height="20" stroke="currentColor" stroke-width="1.5" viewbox="0 0 24 24" width="20" xmlns="http://www.w3.org/2000/svg">
<path d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" stroke-linecap="round" stroke-linejoin="round"></path>
</svg>
<span class="text-sm font-medium text-white/90">Nome da carteira</span>
</div>
<svg class="text-muted-text" fill="none" height="20" stroke="currentColor" stroke-width="2" viewbox="0 0 24 24" width="20" xmlns="http://www.w3.org/2000/svg">
<path d="M19 9l-7 7-7-7" stroke-linecap="round" stroke-linejoin="round"></path>
</svg>
</div>
<!-- Settings -->
<div class="flex items-center justify-between bg-card-dark p-4 px-5 rounded-2xl border border-white/5 cursor-pointer">
<div class="flex items-center space-x-4">
<svg class="text-white" fill="none" height="20" stroke="currentColor" stroke-width="1.5" viewbox="0 0 24 24" width="20" xmlns="http://www.w3.org/2000/svg">
<path d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" stroke-linecap="round" stroke-linejoin="round"></path>
<path d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" stroke-linecap="round" stroke-linejoin="round"></path>
</svg>
<span class="text-sm font-medium text-white/90">Preferências da carteira</span>
</div>
<svg class="text-muted-text" fill="none" height="20" stroke="currentColor" stroke-width="2" viewbox="0 0 24 24" width="20" xmlns="http://www.w3.org/2000/svg">
<path d="M19 9l-7 7-7-7" stroke-linecap="round" stroke-linejoin="round"></path>
</svg>
</div>
</section>
<!-- END: ManagementList -->
<!-- BEGIN: HistorySection -->
<section class="pb-10" data-purpose="transaction-history">
<div class="flex items-center justify-between mb-6">
<h3 class="text-2xl font-newsreader text-white">Histórico</h3>
<button class="flex items-center space-x-2 text-muted-text hover:text-white transition-colors">
<svg fill="none" height="16" stroke="currentColor" stroke-width="2" viewbox="0 0 24 24" width="16" xmlns="http://www.w3.org/2000/svg">
<path d="M3 4h13M3 8h9m-9 4h6m4 0l4-4m0 0l4 4m-4-4v12" stroke-linecap="round" stroke-linejoin="round"></path>
</svg>
<span class="text-[10px] uppercase font-bold tracking-widest">Filtrar</span>
</button>
</div>
<div class="space-y-4">
<!-- Transaction Item 1 -->
<div class="bg-card-dark p-5 rounded-3xl border border-white/5 relative" data-purpose="transaction-item">
<div class="flex items-start justify-between mb-4">
<div class="flex items-center space-x-4">
<div class="w-12 h-12 rounded-xl bg-white/5 flex items-center justify-center">
<svg fill="none" height="24" stroke="white" stroke-width="1.5" viewbox="0 0 24 24" width="24" xmlns="http://www.w3.org/2000/svg">
<path d="M21 16.04l-9 5.15-9-5.15V7.96l9-5.15 9 5.15v8.08zM12 21.19V11.81m0 0l-9-5.15m9 5.15l9-5.15M3 7.96l9 5.15 9-5.15"></path>
</svg>
</div>
<div class="flex flex-col">
<span class="text-sm font-semibold text-white">Onchain</span>
<span class="font-mono text-[10px] text-muted-text truncate w-32">bc1qxy2kgdygjrsqtzq2n1</span>
</div>
</div>
<div class="text-right flex flex-col">
<span class="text-[10px] text-muted-text">22/11/2025</span>
<span class="text-[10px] text-muted-text">09:15</span>
</div>
</div>
<div class="flex flex-col space-y-2">
<span class="font-mono text-xl font-medium text-white">-R$1.450,75</span>
<div class="inline-flex items-center space-x-1 bg-accent-orange/10 px-2.5 py-1 rounded-full w-fit">
<svg fill="none" height="10" stroke="#E28C44" stroke-width="2" viewbox="0 0 24 24" width="10" xmlns="http://www.w3.org/2000/svg">
<circle cx="12" cy="12" r="10"></circle>
<polyline points="12 6 12 12 16 14"></polyline>
</svg>
<span class="text-[9px] font-bold uppercase text-accent-orange tracking-widest">Pendente</span>
</div>
</div>
</div>
<!-- Transaction Item 2 -->
<div class="bg-card-dark p-5 rounded-3xl border border-white/5 opacity-80" data-purpose="transaction-item">
<div class="flex items-start justify-between mb-4">
<div class="flex items-center space-x-4">
<div class="w-12 h-12 rounded-xl bg-white/5 flex items-center justify-center">
<svg fill="none" height="24" stroke="white" stroke-width="1.5" viewbox="0 0 24 24" width="24" xmlns="http://www.w3.org/2000/svg">
<path d="M21 16.04l-9 5.15-9-5.15V7.96l9-5.15 9 5.15v8.08zM12 21.19V11.81m0 0l-9-5.15m9 5.15l9-5.15M3 7.96l9 5.15 9-5.15"></path>
</svg>
</div>
<div class="flex flex-col">
<span class="text-sm font-semibold text-white">Onchain</span>
<span class="font-mono text-[10px] text-muted-text truncate w-32">bc1qxy2kgdygjrsqtzq2n1</span>
</div>
</div>
<div class="text-right flex flex-col">
<span class="text-[10px] text-muted-text">22/11/2025</span>
<span class="text-[10px] text-muted-text">09:15</span>
</div>
</div>
<div class="flex flex-col space-y-2">
<span class="font-mono text-xl font-medium text-white">-R$1.450,75</span>
<div class="inline-flex items-center space-x-1 bg-accent-orange/10 px-2.5 py-1 rounded-full w-fit">
<svg fill="none" height="10" stroke="#E28C44" stroke-width="2" viewbox="0 0 24 24" width="10" xmlns="http://www.w3.org/2000/svg">
<circle cx="12" cy="12" r="10"></circle>
<polyline points="12 6 12 12 16 14"></polyline>
</svg>
<span class="text-[9px] font-bold uppercase text-accent-orange tracking-widest">Pendente</span>
</div>
</div>
</div>
</div>
</section>
<!-- END: HistorySection -->
</main>
</body></html>
```



