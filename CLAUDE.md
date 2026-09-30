# Regras deste repositório

PWA offline (index.html, sw.js, manifest.webmanifest, icons/) publicada no GitHub Pages a partir da branch main, pasta raiz.

- Sempre que alterares qualquer ficheiro servido pela app, sobe a versão de CACHE em sw.js (seg-pc-v3 para seg-pc-v4, etc.). Sem isto o iPhone continua a mostrar a versão antiga.
- Se adicionares um ficheiro novo que a app precise offline, junta-o também à lista ASSETS em sw.js.
- A app não pode conter nomes, dados pessoais, emails, chaves de API nem tokens. Trabalhos identificados só por códigos.
- Os dados ficam só no localStorage do dispositivo. Nada de pedidos a servidores externos, analytics ou CDNs.
