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
            
            <h4 class="titulo-resultados">Resultados dos Alunos</h4>
            <ul v-if="cenario.submissoes && cenario.submissoes.length > 0" class="lista-alunos">
              <li v-for="sub in cenario.submissoes" :key="sub.id" class="item-aluno">
                <span class="nome-aluno">{{ sub.usuarios?.nome || 'Aluno Oculto' }}</span>
                <div style="display: flex; align-items: center; gap: 10px;">
                  <span class="nota-aluno">
                    {{ sub.resultados[0] ? sub.resultados[0].balanco_ml + 'ml' : 'Pendente' }}
                  </span>
                  <!-- BOTÃO QUE MANDA O PROFESSOR PARA A TELA DE RESULTADO DO ALUNO -->
                  <button @click="verDetalhesAluno(sub.id)" class="btn-acao primario" style="padding: 4px 10px; font-size: 12px;">
                    Ver Correção
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
const { user, nomeUsuario, isProfessor } = useAuth()

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
          resultados (balanco_ml)
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
</style>