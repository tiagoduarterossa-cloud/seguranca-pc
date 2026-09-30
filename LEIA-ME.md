# Segurança do PC

App offline para acompanhar vários trabalhos de segurança: checklist de configuração, revisões periódicas e guias para quando algo corre mal. Tudo fica guardado só no iPhone, nunca no site.

## O que tem

- Vários trabalhos, cada um identificado só por um código (PC 01, Cliente A). Nunca nomes reais.
- Checklist por fases, com os passos essenciais separados dos opcionais.
- Revisões mensal, semestral e anual por trabalho, com aviso de atraso.
- 17 guias de resolução de problemas, com pesquisa, e a indicação de quando se resolve sozinho, quando é urgente e quando é caso para um profissional.
- Exportar e importar tudo num ficheiro.
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
