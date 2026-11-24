<template>
  <div class="fundo-painel">
    <header class="cabecalho-principal">
      <div class="cabecalho-conteudo">
        <div class="logo-painel">HidroCare <span class="divisor-logo">|</span> Painel do Professor</div>
        <div class="usuario-info">
          <span>Professor(a): {{ nomeUsuario }}</span>
          <a href="#" @click.prevent="sair" class="link-sair">Sair</a>
        </div>
      </div>
    </header>

    <main class="painel-container">
      <div class="boas-vindas" style="display: flex; justify-content: space-between; align-items: center;">
        <div>
          <h2>Meus Cenários</h2>
          <p class="subtitulo-painel">Gerencie os casos clínicos e acompanhe os alunos.</p>
        </div>
        <button @click="criarNovo" class="btn-acao primario">+ Novo Cenário</button>
      </div>

      <div v-if="carregando" style="text-align: center; margin-top: 30px;">
        <p>Buscando seus cenários e resultados de alunos...</p>
      </div>

      <div v-else class="cards-grid">
        <div class="card-acao" v-for="cenario in cenarios" :key="cenario.id">
          <div class="card-corpo text-align-left">
            <h3>{{ cenario.pacientes?.nome }}</h3>
            <p class="mb-2"><strong>Atividade:</strong> {{ cenario.titulo }}</p>
            <p class="mb-2">
              <strong>Status:</strong> 
              <span :style="{color: cenario.publicado ? '#16a34a' : '#d97706'}">
                {{ cenario.publicado ? 'Publicado' : 'Rascunho' }}
              </span>
            </p>
            
            <hr class="linha-divisoria">
            
            <div class="acoes-cenario">
              <button @click="editarCenario(cenario.id)" class="btn-acao secundario">Editar</button>
              <button @click="excluirCenario(cenario)" class="btn-acao perigo">Excluir</button>
            </div>

            <h4 class="titulo-resultados">Resultados dos Alunos</h4>
            <ul v-if="cenario.submissoes && cenario.submissoes.length > 0" class="lista-alunos">
              <li v-for="sub in cenario.submissoes" :key="sub.id" class="item-aluno">
                <span class="nome-aluno">{{ sub.usuarios?.nome || 'Aluno Oculto' }}</span>
                <div style="display: flex; align-items: center; gap: 10px;">
                  <span class="nota-aluno">
                    {{ balancoDe(sub) }}
                  </span>
                  <span v-if="temFeedback(sub)" class="tag-feedback">Feedback enviado</span>
                  <span v-else class="tag-sem-feedback">Sem feedback</span>
                  <!-- BOTÃO QUE MANDA O PROFESSOR PARA A TELA DE RESULTADO DO ALUNO -->
                  <button @click="verDetalhesAluno(sub.id)" class="btn-acao primario" style="padding: 4px 10px; font-size: 12px;">
                    Corrigir e dar feedback
                  </button>
                </div>
              </li>
            </ul>
            <p v-else class="sem-resultados">Nenhum aluno respondeu ainda.</p>

          </div>
        </div>
        
        <div class="card-acao" v-if="cenarios.length === 0">
          <div class="card-corpo text-align-center">
            <p>Você ainda não criou nenhum cenário.</p>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'

const router = useRouter()
const cenarios = ref([])
const carregando = ref(true)

import { useAuth } from '@/composables/useAuth'
const { nomeUsuario } = useAuth()

const buscarCenariosDoProfessor = async (professorId) => {
  carregando.value = true
  try {
    // Busca relacional super poderosa: Pega Cenários + Paciente + Submissões + Usuário que submeteu + Resultado da submissão
    const { data, error } = await supabase
      .from('cenarios')
      .select(`
        id, 
        titulo, 
        publicado,
        pacientes (nome),
        submissoes (
          id,
          enviada_em,
          usuarios (nome),
          resultados (balanco_ml),
          feedbacks (id)
        )
      `)
      .eq('professor_id', professorId)
      .order('created_at', { ascending: false })

    if (error) throw error
    cenarios.value = data || []
  } catch (error) {
    console.error("Erro ao buscar cenários do professor:", error)
  } finally {
    carregando.value = false
  }
}

// Ao abrir a tela, busca os cenários do professor que está logado
onMounted(async () => {
  const { data: { session } } = await supabase.auth.getSession()
  const user = session?.user
  if (user) await buscarCenariosDoProfessor(user.id)
  else carregando.value = false
})

// resultados chega como objeto (1 por submissão); aceita lista também, por segurança
const balancoDe = (sub) => {
  const r = Array.isArray(sub.resultados) ? sub.resultados[0] : sub.resultados
  return r ? r.balanco_ml + 'ml' : 'Pendente'
}

// A submissão tem feedback se existir ao menos uma linha em feedbacks
const temFeedback = (sub) => Array.isArray(sub.feedbacks) && sub.feedbacks.length > 0

// Abre o formulário do cenário em modo edição
const editarCenario = (id) => router.push({ path: '/cadastro-cenario', query: { id } })

// Exclui o cenário. Atenção: o banco apaga junto o gabarito, as respostas, os resultados
// e os feedbacks desse cenário (ON DELETE CASCADE). Por isso o aviso muda se já há respostas.
const excluirCenario = async (cenario) => {
  const respostas = cenario.submissoes ? cenario.submissoes.length : 0
  const aviso = respostas > 0
    ? `O cenário "${cenario.titulo}" já tem ${respostas} resposta(s) de estudantes. Excluir apagará também as respostas, os resultados e os feedbacks. Isso não pode ser desfeito. Excluir mesmo assim?`
    : `Excluir o cenário "${cenario.titulo}"? Isso não pode ser desfeito.`
  if (!confirm(aviso)) return

  const { data, error } = await supabase
    .from('cenarios')
    .delete()
    .eq('id', cenario.id)
    .select('id')

  if (error || !data || data.length === 0) {
    console.error('Erro ao excluir o cenário:', error)
    alert('Não foi possível excluir o cenário.')
    return
  }
  cenarios.value = cenarios.value.filter(c => c.id !== cenario.id)
}

const criarNovo = () => router.push('/cadastro-cenario')

const sair = async () => {
  await supabase.auth.signOut()
  router.push('/')
}
// Direciona o professor para ver a correção detalhada do aluno
const verDetalhesAluno = (submissaoId) => {
  router.push(`/resultado?id=${submissaoId}`)
}
</script>

<style scoped>
.fundo-painel { min-height: 100vh; background-color: #f4f6f9; }
.cabecalho-principal { background-color: #2c3e50; color: #ffffff; padding: 15px 30px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
.cabecalho-conteudo { max-width: 1100px; margin: 0 auto; display: flex; justify-content: space-between; align-items: center; }
.logo-painel { font-size: 20px; font-weight: 600; }
.divisor-logo { color: #94a3b8; margin: 0 5px; }
.usuario-info { display: flex; align-items: center; gap: 15px; font-size: 14px; color: #cbd5e1; }
.link-sair { color: #ffffff; text-decoration: none; font-size: 14px; font-weight: 500; }
.link-sair:hover { text-decoration: underline; }

.painel-container { max-width: 1100px; margin: 30px auto; padding: 0 20px; }

.boas-vindas { margin-bottom: 25px; }
.boas-vindas h2 { color: #1e293b; font-size: 24px; }
.subtitulo-painel { color: #64748b; font-size: 14px; }

.cards-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 20px; }

.card-acao { background: #ffffff; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.02); border-top: 4px solid #1a56db; transition: transform 0.2s; }
.card-acao:hover { transform: translateY(-3px); }

.card-corpo { padding: 30px; }
.card-corpo h3 { color: #1e293b; margin-bottom: 10px; font-size: 18px; }
.card-corpo p { color: #64748b; font-size: 14px; margin-bottom: 10px; }

.linha-divisoria { border: none; border-top: 1px solid #e2e8f0; margin: 20px 0; }
.titulo-resultados { font-size: 14px; color: #1e293b; margin-bottom: 10px; }

.lista-alunos { list-style: none; padding: 0; margin: 0; }
.item-aluno { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px dashed #f1f5f9; font-size: 13px; }
.item-aluno:last-child { border-bottom: none; }
.nome-aluno { color: #475569; font-weight: 500; }
.nota-aluno { color: #1a56db; font-weight: bold; }
.sem-resultados { font-size: 13px; color: #94a3b8; font-style: italic; }

.btn-acao { display: inline-block; padding: 10px 20px; border-radius: 6px; font-size: 14px; font-weight: 600; text-decoration: none; cursor: pointer; border: none; }
.btn-acao.primario { background-color: #1a56db; color: #fff; }
.btn-acao.primario:hover { background-color: #1e40af; }

.text-align-left { text-align: left !important; }
.text-align-center { text-align: center !important; }
.mb-2 { margin-bottom: 8px; }

.acoes-cenario { display: flex; gap: 10px; margin-bottom: 18px; }
.btn-acao.secundario { background-color: #e2e8f0; color: #1e293b; padding: 6px 14px; font-size: 13px; }
.btn-acao.secundario:hover { background-color: #cbd5e1; }
.btn-acao.perigo { background-color: #fee2e2; color: #b91c1c; padding: 6px 14px; font-size: 13px; }
.btn-acao.perigo:hover { background-color: #fecaca; }
.tag-feedback { font-size: 11px; color: #166534; background: #dcfce7; padding: 2px 8px; border-radius: 10px; }
.tag-sem-feedback { font-size: 11px; color: #92400e; background: #fef3c7; padding: 2px 8px; border-radius: 10px; }
</style>