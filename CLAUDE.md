# Regras deste repositório

PWA offline (index.html, sw.js, manifest.webmanifest, icons/) publicada no GitHub Pages a partir da branch main, pasta raiz.

- Sempre que alterares qualquer ficheiro servido pela app, sobe a versão de CACHE em sw.js (seg-pc-v3 para seg-pc-v4, etc.). Sem isto o iPhone continua a mostrar a versão antiga.
- Se adicionares um ficheiro novo que a app precise offline, junta-o também à lista ASSETS em sw.js.
- A app não pode conter nomes, dados pessoais, emails, chaves de API nem tokens. Trabalhos identificados só por códigos.
- Os dados ficam só no localStorage do dispositivo. Nada de analytics nem CDNs. A única ligação externa permitida é o assistente à api.anthropic.com, travada pela Content-Security-Policy no index.html.
- A chave da API é colada pelo utilizador no iPhone e guardada em localStorage (seg-pc-ai-key), separada do estado. Nunca a escrevas no código nem a incluas na exportação.
- Os níveis de proteção vivem em ITEM_LEVEL no index.html e na função Need do verificar-pc.ps1. Se mudares um, muda o outro.
- verificar-pc.ps1 é gravado em UTF-8 com BOM (o PowerShell 5.1 precisa disso para os acentos) e só pode ler, nunca alterar o sistema.
