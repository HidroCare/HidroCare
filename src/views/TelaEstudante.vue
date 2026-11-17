<template>
  <div class="fundo-painel">
    <!-- CABEÇALHO -->
    <header class="cabecalho-principal">
      <div class="cabecalho-conteudo">
        <div class="logo-painel">HidroCare <span class="divisor-logo">|</span> Área do Estudante</div>
        <div class="usuario-info">
          <span>Estudante: {{ nomeUsuario }}</span>
          <a href="#" @click.prevent="sair" class="link-sair">Sair</a>
        </div>
      </div>
    </header>

    <!-- CONTEÚDO PRINCIPAL -->
    <main class="painel-container">
      <div class="boas-vindas">
        <h2>Cenários Clínicos Disponíveis</h2>
        <p class="subtitulo-painel">Selecione um paciente para iniciar o cálculo do balanço hídrico.</p>
      </div>

      <div class="cards-grid">
        <p v-if="carregando">Buscando cenários no banco de dados...</p>
        
        <!-- CARTÃO DO PACIENTE (Repete para cada cenário vindo do banco) -->
        <div class="card-acao" v-for="cenario in cenarios" :key="cenario.id">
          <div class="card-corpo text-align-left">
            <h3>{{ cenario.titulo }}</h3>
            <p class="mb-2"><strong>Paciente:</strong> {{ cenario.pacientes?.nome }}</p>
            <p>{{ cenario.enunciado }}</p>
            <button @click="iniciarAtividade(cenario.id)" class="btn-acao primario mt-3">
              Iniciar Atividade
            </button>
          </div>
        </div>
        
        <!-- Cartão estático de fallback caso o banco esteja vazio ainda -->
        <div class="card-acao" v-if="!carregando && cenarios.length === 0">
          <div class="card-corpo text-align-left">
            <h3>Nenhum cenário cadastrado</h3>
            <p>Aguarde o professor cadastrar novos casos clínicos.</p>
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

const buscarCenarios = async () => {
  carregando.value = true
  try {
    // O banco só devolve cenários PUBLICADOS para o estudante (regra de acesso do banco)
    const { data, error } = await supabase
      .from('cenarios')
      .select('id, titulo, enunciado, pacientes (nome)')
      .eq('publicado', true)
      .order('created_at', { ascending: false })

    if (error) throw error
    cenarios.value = data || []
  } catch (error) {
    console.error('Erro ao buscar:', error)
  } finally {
    carregando.value = false
  }
}

onMounted(() => {
  buscarCenarios()
})

// Leva o id do cenário escolhido para a tela da atividade
const iniciarAtividade = (id) => router.push({ path: '/atividade', query: { cenario: id } })
const sair = async () => {
  await supabase.auth.signOut()
  router.push('/')
}
</script>

<style scoped>
/* FUNDO E CONTAINERS */
.fundo-painel { min-height: 100vh; }
.painel-container { max-width: 1100px; margin: 30px auto; padding: 0 20px; }

/* CABEÇALHO */
.cabecalho-principal { background-color: #2c3e50; color: #ffffff; padding: 15px 30px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
.cabecalho-conteudo { max-width: 1100px; margin: 0 auto; display: flex; justify-content: space-between; align-items: center; }
.logo-painel { font-size: 20px; font-weight: 600; }
.divisor-logo { color: #94a3b8; margin: 0 5px; }
.usuario-info span { margin-right: 15px; font-size: 14px; color: #cbd5e1; }
.link-sair { color: #ffffff; text-decoration: none; font-size: 14px; font-weight: 500; }
.link-sair:hover { text-decoration: underline; }

/* BOAS VINDAS */
.boas-vindas { margin-bottom: 25px; }
.boas-vindas h2 { color: #1e293b; font-size: 24px; }
.subtitulo-painel { color: #64748b; font-size: 14px; }

/* GRID DE CARTÕES */
.cards-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
.card-acao { background: #ffffff; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.02); border-top: 4px solid #1a56db; transition: transform 0.2s; }
.card-acao:hover { transform: translateY(-3px); }
.card-corpo { padding: 30px; text-align: center; }
.card-corpo h3 { color: #1e293b; margin-bottom: 10px; font-size: 18px; }
.card-corpo p { color: #64748b; font-size: 14px; margin-bottom: 20px; }

/* BOTÕES E UTILITÁRIOS */
.btn-acao { display: inline-block; padding: 10px 20px; border-radius: 6px; font-size: 14px; font-weight: 600; text-decoration: none; cursor: pointer; border: none; }
.btn-acao.primario { background-color: #1a56db; color: #fff; width: 100%; }
.btn-acao.primario:hover { background-color: #1e40af; }

.text-align-left { text-align: left !important; }
.mb-2 { margin-bottom: 8px; }
.mt-3 { margin-top: 15px; }
</style>