// Redefine a senha de UM aluno que esqueceu (sem depender de e-mail, que tem limite de 2 por hora).
// QUEM RODA: so o responsavel pelo banco, no proprio computador. NUNCA commitar a chave service_role.
// Uso:
//   SUPABASE_URL=https://SEU-PROJETO.supabase.co SUPABASE_SERVICE_ROLE_KEY=... node scripts/redefinir-senha.mjs RA@senacminas.edu.br NovaSenha123
// Requer Node 18+. Entregue a senha nova ao aluno em mao.
const [email, senha] = [process.argv[2], process.argv[3]]
const url = (process.env.SUPABASE_URL || '').replace(/\/+$/, '')
const chave = process.env.SUPABASE_SERVICE_ROLE_KEY
if (!email || !senha || !url || !chave) {
  console.error('Uso: SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... node scripts/redefinir-senha.mjs email senha-nova')
  process.exit(2)
}
if (senha.length < 6) { console.error('Use uma senha com 6 caracteres ou mais (minimo do Supabase).'); process.exit(2) }
const h = { apikey: chave, Authorization: 'Bearer ' + chave, 'Content-Type': 'application/json' }
try {
  // procura o usuario pelo e-mail (percorre as paginas da lista)
  let achado = null
  for (let pagina = 1; pagina <= 20 && !achado; pagina++) {
    const r = await fetch(`${url}/auth/v1/admin/users?page=${pagina}&per_page=100`, { headers: h })
    if (!r.ok) { console.error('ERRO ao listar usuarios: ' + r.status); process.exit(1) }
    const lista = (await r.json()).users || []
    achado = lista.find(u => (u.email || '').toLowerCase() === email.toLowerCase())
    if (lista.length < 100) break
  }
  if (!achado) { console.error('Nao achei ninguem com o e-mail ' + email); process.exit(1) }
  const r2 = await fetch(`${url}/auth/v1/admin/users/${achado.id}`, { method: 'PUT', headers: h, body: JSON.stringify({ password: senha }) })
  if (!r2.ok) { console.error('ERRO ao trocar a senha: ' + r2.status + ' ' + (await r2.text()).slice(0, 120)); process.exit(1) }
  console.log('Senha redefinida para ' + email + '. Avise o aluno em mao.')
} catch (e) { console.error('ERRO de rede: ' + e.message); process.exit(1) }
