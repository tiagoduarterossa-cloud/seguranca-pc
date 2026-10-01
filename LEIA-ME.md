# Segurança do PC

App offline para acompanhar vários trabalhos de segurança: checklist de configuração, revisões periódicas e guias para quando algo corre mal. Tudo fica guardado só no iPhone, nunca no site.

## O que tem

- Vários trabalhos, cada um identificado só por um código (PC 01, Cliente A). Nunca nomes reais.
- Checklist por fases, com os passos essenciais separados dos opcionais.
- Revisões mensal, semestral e anual por trabalho, com aviso de atraso.
- 17 guias de resolução de problemas, com pesquisa, e a indicação de quando se resolve sozinho, quando é urgente e quando é caso para um profissional.
- Exportar e importar tudo num ficheiro.
- Estado da app: diagnóstico do modo offline, versão, gravação dos dados, cópias, revisões atrasadas e chave da IA (o teste da chave não gasta crédito).
- Script verificar-pc.ps1 para correr no próprio PC como administrador. Só lê: edição do Windows, TPM, Secure Boot, contas, Defender, Acesso controlado a pastas, firewall, atualizações, BitLocker com PIN e discos. Não altera nada nem mostra nomes ou chaves.
- Assistente com IA (Claude), geral ou sobre um trabalho concreto. Precisa de internet e de uma chave da API da Anthropic, colada uma vez no iPhone.
- O progresso da versão anterior passa automaticamente para o primeiro trabalho.

## Atualizar no GitHub Pages

1. No repositório, substitui index.html e sw.js pelos desta pasta. Os ícones e o manifest podem ficar.
2. Espera um ou dois minutos.
3. No iPhone, abre a app pelo ícone com internet, fecha-a e volta a abri-la. A nova versão aparece.

## Primeira instalação

1. Cria o repositório (sem nome do colega nem do escritório) e carrega todos os ficheiros, mantendo a pasta icons.
2. Settings, Pages, Deploy from a branch, main, / (root).
3. No iPhone, abre o endereço no Safari, Partilhar, Adicionar ao ecrã principal.
4. Abre a app pelo ícone uma vez com internet. A partir daí funciona sem rede.

## Cuidados

- Usa sempre a app pelo ícone. O Safari e a app instalada guardam os dados em sítios separados.
- Exporta depois de cada revisão e guarda o ficheiro fora do iPhone. O ficheiro diz o estado de segurança de vários PCs, trata-o como confidencial.
- Sempre que alterares um ficheiro, sobe a versão em sw.js (seg-pc-v3 para seg-pc-v4, e assim por diante).
- Os avisos das revisões ficam na app Lembretes do iPhone.

## Assistente IA

- A chave cria-se em console.anthropic.com, API keys. Define lá um limite de gasto mensal.
- A chave fica só no localStorage do iPhone, numa entrada separada. Não vai no ficheiro exportado nem no GitHub.
- A página só consegue falar com o próprio site e com api.anthropic.com (Content-Security-Policy).
- O que escreves no assistente sai do iPhone para a Anthropic. Só códigos e descrições genéricas.
- A app bloqueia chaves de recuperação do BitLocker e pede confirmação se detetar email, telefone ou NIF.
- A conversa não é guardada. Fechar a app apaga-a.
- Se o iPhone for perdido, apaga a chave na consola da Anthropic.
