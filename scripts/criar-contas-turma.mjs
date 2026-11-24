// Cria as contas dos estudantes da turma no Supabase (ja confirmadas), a partir de uma lista.
// QUEM RODA: so a pessoa responsavel pelo banco, no proprio computador. NUNCA commitar a chave.
//
// 1) Crie o arquivo turma.csv (fora do GitHub), uma linha por aluno:  RA,Nome Completo
//      2026001,Maria da Silva
//      2026002,Joao Souza
// 2) Rode (a chave service_role esta em Project Settings > API; nao cole em chat nem em arquivo):
//      SUPABASE_URL=https://SEU-PROJETO.supabase.co SUPABASE_SERVICE_ROLE_KEY=... node scripts/criar-contas-turma.mjs turma.csv
//    Opcional: SENHA_PADRAO=MinhaSenha123  (senha igual para todos)  ou  SENHA_COMO_RA=1  (a senha e o proprio RA, minimo 6 digitos)
//    Sem nenhuma das duas, cada aluno recebe uma senha aleatoria.
// 3) O script grava credenciais-turma.csv (e-mail e senha de cada aluno). Imprima/entregue e DEPOIS apague o arquivo.
// O gatilho do banco (script 08) cria a linha em "usuarios" com perfil estudante. Requer Node 18+.
import { readFileSync, writeFileSync } from 'node:fs'
import { randomBytes } from 'node:crypto'

const arquivo = process.argv[2]
const url = (process.env.SUPABASE_URL || '').replace(/\/+$/, '')
const chave = process.env.SUPABASE_SERVICE_ROLE_KEY
if (!arquivo || !url || !chave) {
  console.error('Uso: SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... node scripts/criar-contas-turma.mjs turma.csv')
  process.exit(2)
}
const dominio = process.env.DOMINIO || 'senacminas.edu.br'
const senhaAleatoria = () => 'Hc' + randomBytes(4).toString('hex') + '!'
const linhas = readFileSync(arquivo, 'utf8').replace(/\r/g, '').split('\n').map(l => l.trim()).filter(Boolean)
const saida = ['ra,nome,email,senha,situacao']
let criadas = 0, jaExistiam = 0, erros = 0

for (const linha of linhas) {
  const [ra, ...resto] = linha.split(',')
  const nome = resto.join(',').trim()
  if (!/^\d+$/.test(ra.trim()) || !nome) { console.log('  PULEI (formato RA,Nome): ' + linha); continue }
  const email = `${ra.trim()}@${dominio}`
  const senha = process.env.SENHA_COMO_RA === '1' ? ra.trim() : (process.env.SENHA_PADRAO || senhaAleatoria())
  if (senha.length < 6) { console.log('  PULEI (senha curta, RA com menos de 6 digitos): ' + linha); continue }
  try {
    const r = await fetch(url + '/auth/v1/admin/users', {
      method: 'POST',
      headers: { apikey: chave, Authorization: 'Bearer ' + chave, 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password: senha, email_confirm: true, user_metadata: { nome } }),
    })
    if (r.ok) { criadas++; saida.push(`${ra},"${nome}",${email},${senha},criada`); console.log('  criada   ' + email) }
    else {
      const t = await r.text()
      if (r.status === 422 && /already|exists|registered/i.test(t)) { jaExistiam++; saida.push(`${ra},"${nome}",${email},,ja existia`); console.log('  ja existe ' + email) }
      else { erros++; saida.push(`${ra},"${nome}",${email},,ERRO ${r.status}`); console.log(`  ERRO ${r.status} ${email}: ${t.slice(0, 120)}`) }
    }
  } catch (e) { erros++; console.log('  ERRO de rede ' + email + ': ' + e.message) }
}
writeFileSync('credenciais-turma.csv', saida.join('\n') + '\n')
console.log(`\nCriadas: ${criadas} · ja existiam: ${jaExistiam} · erros: ${erros}`)
console.log('Arquivo credenciais-turma.csv gravado. Entregue as senhas e apague o arquivo depois.')
process.exit(erros ? 1 : 0)
