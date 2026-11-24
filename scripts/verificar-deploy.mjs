// Teste rapido pos-deploy. Uso:
//   node scripts/verificar-deploy.mjs https://SEU-SITE.netlify.app
// Opcional (testa tambem a conexao com o Supabase):
//   VITE_SUPABASE_URL=... VITE_SUPABASE_ANON_KEY=... node scripts/verificar-deploy.mjs https://SEU-SITE.netlify.app
// Requer Node 18+. Nao grava nada em lugar nenhum.
const base = (process.argv[2] || '').replace(/\/+$/, '')
if (!/^https?:\/\//.test(base)) {
  console.error('Informe o endereco: node scripts/verificar-deploy.mjs https://SEU-SITE.netlify.app')
  process.exit(2)
}
let falhas = 0
const ok = (m) => console.log('  OK     ' + m)
const ruim = (m) => { falhas++; console.log('  FALHA  ' + m) }
const aviso = (m) => console.log('  AVISO  ' + m)
const pega = async (url, opt) => {
  try { const r = await fetch(url, opt); return { r, t: await r.text() } }
  catch (e) { return { erro: e.message } }
}

console.log('1) Pagina inicial')
const home = await pega(base + '/')
if (home.erro) { ruim('nao abriu: ' + home.erro); process.exit(1) }
home.r.status === 200 ? ok('responde 200') : ruim('status ' + home.r.status)
;/<title>HidroCare<\/title>/.test(home.t) ? ok('titulo HidroCare') : ruim('titulo diferente de HidroCare (index.html antigo?)')
;/id="app"/.test(home.t) ? ok('contem a div #app') : ruim('nao parece o index.html do Vue')

console.log('2) Rotas internas (F5 nao pode dar 404)')
for (const rota of ['/tela-professor', '/tela-estudante', '/cadastro-cenario']) {
  const x = await pega(base + rota)
  if (x.erro) ruim(rota + ': ' + x.erro)
  else if (x.r.status === 200 && /id="app"/.test(x.t)) ok(rota + ' devolve o app')
  else ruim(rota + ' status ' + x.r.status + ' (redirecionamento /* ausente?)')
}

console.log('3) Arquivos publicos que NAO podem vazar')
for (const arq of ['/.env', '/.env.local', '/package.json', '/.git/config']) {
  const x = await pega(base + arq)
  if (x.erro) { ok(arq + ' inacessivel'); continue }
  const vazou = /VITE_SUPABASE|SUPABASE_ANON_KEY|"dependencies"|\[core\]/.test(x.t)
  vazou ? ruim(arq + ' EXPOE CONTEUDO') : ok(arq + ' sem conteudo sensivel (status ' + x.r.status + ')')
}

console.log('4) Pacote JavaScript')
const js = (home.t.match(/src="(\/assets\/[^"]+\.js)"/) || [])[1]
if (!js) ruim('script principal nao encontrado no HTML')
else {
  const b = await pega(base + js)
  if (b.erro || b.r.status !== 200) ruim('nao carregou ' + js)
  else {
    ok('carrega ' + js)
    const url = process.env.VITE_SUPABASE_URL
    if (/https:\/\/[a-z0-9]+\.supabase\.co/.test(b.t)) ok('endereco do Supabase esta embutido (variavel VITE_ lida no build)')
    else ruim('endereco do Supabase NAO esta no pacote: variaveis do Netlify faltando ou build feito antes de cadastra-las (refazer o deploy)')
    if (/service_role/.test(b.t)) ruim('apareceu "service_role" no pacote: chave proibida!')
    else ok('sem referencia a service_role')
    if (url && !b.t.includes(url)) aviso('o endereco do pacote e diferente de VITE_SUPABASE_URL informado')
  }
}

console.log('5) Supabase (opcional)')
const su = process.env.VITE_SUPABASE_URL, ch = process.env.VITE_SUPABASE_ANON_KEY
if (!su || !ch) aviso('pulado (defina VITE_SUPABASE_URL e VITE_SUPABASE_ANON_KEY para testar)')
else {
  const s = await pega(su.replace(/\/+$/, '') + '/auth/v1/settings', { headers: { apikey: ch } })
  s.erro ? ruim('Supabase inacessivel: ' + s.erro) : s.r.status === 200 ? ok('Auth do Supabase responde') : ruim('Auth respondeu ' + s.r.status + ' (chave anon errada?)')
  const t = await pega(su.replace(/\/+$/, '') + '/rest/v1/gabarito_itens?select=id&limit=1', { headers: { apikey: ch } })
  if (t.erro) ruim('REST inacessivel')
  else if (t.r.status === 200 && t.t.trim() !== '[]') ruim('gabarito legivel SEM login: politicas de acesso quebradas!')
  else ok('gabarito nao e legivel sem login (status ' + t.r.status + ')')
}

console.log(falhas ? `\n${falhas} FALHA(S). Corrija antes de usar o site.` : '\nTudo certo nesta verificacao automatica. Falta o teste manual com login (roteiro, secao 5).')
process.exit(falhas ? 1 : 0)
