<template>
  <div class="fundo-painel">
    
    <header class="cabecalho-principal estudante">
      <div class="cabecalho-conteudo">
        <div class="logo-painel">HidroCare <span class="divisor-logo">|</span> Resultado</div>
        <div class="usuario-info">
          <span>{{ ehProfessor ? 'Professor(a)' : 'Estudante' }}: {{ nomeUsuario }}</span>
          <a href="#" @click.prevent="sair" class="link-sair">Sair</a>
        </div>
      </div>
    </header>

    <main class="painel-container">
      <div v-if="carregando" class="mensagem-carregando">
        <p>Calculando seu resultado no banco de dados...</p>
      </div>

      <div v-if="!carregando && !resultado" class="mensagem-carregando">
        <p>Nenhum resultado encontrado. Volte ao início e faça uma atividade.</p>
        <button @click="voltarAoInicio" class="btn-salvar mt-3">Voltar ao Início</button>
      </div>
      
      <div v-if="!carregando && resultado && ehProfessor && submissao" class="identificacao-aluno text-align-left">
        <strong>Estudante:</strong> {{ submissao.usuarios?.nome || 'Aluno' }}
        &nbsp;·&nbsp; <strong>Cenário:</strong> {{ submissao.cenarios?.titulo || 'Cenário' }}
      </div>

      <div v-if="!carregando && resultado" class="resultado-grid text-align-left">
        <!-- LADO ESQUERDO: BALANÇO -->
        <div class="cartao-balanco">
          <h3>Balanço Hídrico Calculado</h3>
          <!-- Formata o visual (+ ou -) dependendo do valor vindo do banco -->
          <div class="display-balanco" :class="resultado.balanco_ml > 0 ? 'positivo' : (resultado.balanco_ml < 0 ? 'negativo' : 'neutro')">
            {{ resultado.balanco_ml > 0 ? '+' : '' }} {{ resultado.balanco_ml }} ml
          </div>
          
          <span class="badge-status" :class="resultado.balanco_ml > 0 ? 'positivo' : (resultado.balanco_ml < 0 ? 'negativo' : 'neutro')">
            {{ resultado.balanco_ml > 0 ? 'Balanço Positivo' : (resultado.balanco_ml < 0 ? 'Balanço Negativo' : 'Balanço Neutro') }}
          </span>
        </div>

        <!-- LADO DIREITO: CORREÇÃO -->
        <div class="cartao-correcao">
          <h3>Correção Automática</h3>
          
          <div class="caixa-feedback">
            <h4>Desempenho Geral</h4>
            <p class="texto-feedback">
              {{ ehProfessor ? 'O estudante teve' : 'Você teve' }} <strong>{{ resultado.acertos }} {{ resultado.acertos === 1 ? 'acerto' : 'acertos' }}</strong> e <strong>{{ resultado.erros }} {{ resultado.erros === 1 ? 'erro' : 'erros' }}</strong>. 
              Classificação: {{ resultado.classificacao || 'Concluído' }}.
            </p>
          </div>

          <ul class="lista-correcao">
            <!-- Laço de repetição puxando os itens registrados na submissão -->
            <li v-for="reg in registros" :key="reg.id">
              <span>{{ reg.descricao }} ({{ reg.tipo === 'entrada' ? 'Entrada' : 'Saída' }}) - {{ reg.valor_ml }}ml</span>
              
              <span v-if="reg.correto === true" class="status-correto">Correto</span>
              <span v-else-if="reg.correto === false" class="status-incorreto">Incorreto</span>
              <span v-else class="status-neutro">Registrado</span>
            </li>
          </ul>

          <!-- FEEDBACK DO PROFESSOR -->
          <div class="caixa-feedback-professor">
            <h4>Feedback do professor</h4>

            <!-- Professor: escreve, salva, edita e exclui o próprio feedback -->
            <template v-if="ehProfessor">
              <textarea v-model="textoFeedback" rows="4" class="campo-feedback"
                placeholder="Escreva o feedback para este estudante..."></textarea>
              <p v-if="erroFeedback" class="alerta-feedback">{{ erroFeedback }}</p>
              <p v-if="msgFeedback" class="ok-feedback">{{ msgFeedback }}</p>
              <div class="acoes-feedback">
                <button @click="salvarFeedback" class="btn-salvar" :disabled="salvandoFeedback">
                  {{ salvandoFeedback ? 'Salvando...' : (meuFeedback ? 'Atualizar feedback' : 'Enviar feedback') }}
                </button>
                <button v-if="meuFeedback" @click="excluirFeedback" class="btn-excluir-feedback" :disabled="salvandoFeedback">
                  Excluir feedback
                </button>
              </div>
            </template>

            <!-- Estudante: só lê -->
            <template v-else>
              <p v-if="feedbacks.length === 0" class="sem-feedback">O professor ainda não enviou feedback.</p>
              <div v-for="fb in feedbacks" :key="fb.id" class="item-feedback">
                <p>{{ fb.comentario }}</p>
                <small>{{ formatarData(fb.criado_em) }}</small>
              </div>
            </template>
          </div>

          <div class="acoes-formulario" style="justify-content: flex-end;">
            <button @click="voltarAoInicio" class="btn-salvar">Concluir e Voltar</button>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuth, buscarPerfil } from '@/composables/useAuth'

const router = useRouter()
const route = useRoute()
const { nomeUsuario } = useAuth()

const carregando = ref(true)
const resultado = ref(null)
const registros = ref([])
const submissao = ref(null)
const ehProfessor = ref(false)
const usuarioId = ref(null)

// Feedback
const feedbacks = ref([])
const textoFeedback = ref('')
const salvandoFeedback = ref(false)
const erroFeedback = ref('')
const msgFeedback = ref('')
// o feedback que ESTE professor já escreveu (só ele pode editar ou excluir)
const meuFeedback = computed(() => feedbacks.value.find(f => f.professor_id === usuarioId.value) || null)

onMounted(async () => {
  const { data: { session } } = await supabase.auth.getSession()
  const user = session?.user

  if (user) {
    usuarioId.value = user.id
    // perfil vem do banco (tabela usuarios), não de dados digitados no cadastro
    const perfil = await buscarPerfil(user.id)
    ehProfessor.value = perfil?.perfil === 'professor'
    await buscarResultado(user.id)
  } else {
    router.push('/')
  }
})

const buscarResultado = async (estudanteId) => {
  carregando.value = true
  try {
    let submissaoId = route.query.id // enviado pela tela anterior (ex: /resultado?id=123)

    // Se não tiver ID na URL, busca a ÚLTIMA submissão deste estudante
    if (!submissaoId) {
      const { data: ultimaSubmissao } = await supabase
        .from('submissoes')
        .select('id')
        .eq('estudante_id', estudanteId)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle()

      if (ultimaSubmissao) submissaoId = ultimaSubmissao.id
    }

    if (submissaoId) {
      // 1. Resultado ligado à submissão (calculado pelo banco)
      const { data: resData } = await supabase
        .from('resultados')
        .select('*')
        .eq('submissao_id', submissaoId)
        .maybeSingle()

      resultado.value = resData

      // 2. Itens que o estudante digitou (com "correto" já marcado pelo banco)
      const { data: regData } = await supabase
        .from('registros')
        .select('*')
        .eq('submissao_id', submissaoId)

      registros.value = regData || []

      // 3. Quem respondeu e qual cenário (o professor vê isso no topo)
      const { data: subData } = await supabase
        .from('submissoes')
        .select('id, usuarios (nome), cenarios (titulo)')
        .eq('id', submissaoId)
        .maybeSingle()
      submissao.value = subData

      // 4. Feedbacks dessa submissão
      await carregarFeedbacks(submissaoId)
    }
  } catch (error) {
    console.error('Erro ao buscar o resultado:', error)
  } finally {
    carregando.value = false
  }
}

const carregarFeedbacks = async (submissaoId) => {
  const { data } = await supabase
    .from('feedbacks')
    .select('id, professor_id, comentario, criado_em')
    .eq('submissao_id', submissaoId)
    .order('criado_em', { ascending: false })
  feedbacks.value = data || []
  textoFeedback.value = meuFeedback.value ? meuFeedback.value.comentario : ''
}

// Cria o feedback ou atualiza o que o próprio professor já tinha escrito
const salvarFeedback = async () => {
  erroFeedback.value = ''
  msgFeedback.value = ''
  const comentario = textoFeedback.value.trim()
  if (!comentario) {
    erroFeedback.value = 'Escreva o feedback antes de enviar.'
    return
  }

  salvandoFeedback.value = true
  const resposta = meuFeedback.value
    ? await supabase.from('feedbacks').update({ comentario }).eq('id', meuFeedback.value.id).select('id')
    : await supabase.from('feedbacks').insert({
        submissao_id: route.query.id || submissao.value?.id,
        professor_id: usuarioId.value,
        comentario
      }).select('id')
  salvandoFeedback.value = false

  if (resposta.error || !resposta.data || resposta.data.length === 0) {
    console.error('Erro ao salvar o feedback:', resposta.error)
    erroFeedback.value = 'Não foi possível salvar o feedback.'
    return
  }
  msgFeedback.value = 'Feedback salvo! O estudante já pode ver.'
  await carregarFeedbacks(route.query.id || submissao.value?.id)
}

const excluirFeedback = async () => {
  if (!confirm('Excluir o seu feedback desta resposta?')) return
  erroFeedback.value = ''
  msgFeedback.value = ''
  const { data, error } = await supabase.from('feedbacks').delete().eq('id', meuFeedback.value.id).select('id')
  if (error || !data || data.length === 0) {
    erroFeedback.value = 'Não foi possível excluir o feedback.'
    return
  }
  msgFeedback.value = 'Feedback excluído.'
  await carregarFeedbacks(route.query.id || submissao.value?.id)
}

const formatarData = (iso) => iso ? new Date(iso).toLocaleDateString('pt-BR') : ''

const sair = async () => {
  await supabase.auth.signOut()
  router.push('/')
}
const voltarAoInicio = () => {
  if (ehProfessor.value) {
    router.push('/tela-professor') // Se for professor, volta pro painel de gestão
  } else {
    router.push('/tela-estudante') // Se for aluno, volta pra lista de atividades
  }
}
</script>

<style scoped>
.fundo-painel { min-height: 100vh; background-color: #f4f6f9; }
.cabecalho-principal { background-color: #2c3e50; color: #ffffff; padding: 15px 30px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
.cabecalho-conteudo { max-width: 1100px; margin: 0 auto; display: flex; justify-content: space-between; align-items: center; }
.logo-painel { font-size: 20px; font-weight: 600; }
.divisor-logo { color: #94a3b8; margin: 0 5px; }
.usuario-info { display: flex; align-items: center; gap: 15px; font-size: 14px; color: #cbd5e1; }
.link-sair { color: #ffffff; text-decoration: none; font-weight: 500; }
.link-sair:hover { text-decoration: underline; }

.painel-container { max-width: 1100px; margin: 30px auto; padding: 0 20px; }
.mensagem-carregando { text-align: center; margin-top: 50px; font-size: 18px; color: #64748b; }

.resultado-grid { display: grid; grid-template-columns: 1fr 2fr; gap: 20px; }
@media (max-width: 768px) { .resultado-grid { grid-template-columns: 1fr; } }

.cartao-balanco { background: #ffffff; border: 1px solid #e2e8f0; border-top: 4px solid #94a3b8; border-radius: 8px; padding: 30px; text-align: center; }
.cartao-balanco h3 { color: #475569; font-size: 16px; margin-bottom: 20px; }

.display-balanco { font-size: 42px; font-weight: 700; margin-bottom: 15px; }
.display-balanco.positivo { color: #16a34a; }
.display-balanco.negativo { color: #dc2626; }
.display-balanco.neutro { color: #475569; }

.badge-status { display: inline-block; padding: 6px 16px; border-radius: 20px; font-size: 14px; font-weight: 600; }
.badge-status.positivo { background-color: #dcfce7; color: #166534; }
.badge-status.negativo { background-color: #fee2e2; color: #991b1b; }
.badge-status.neutro { background-color: #f1f5f9; color: #475569; }

.cartao-correcao { background: #ffffff; border-radius: 8px; padding: 30px; box-shadow: 0 4px 6px rgba(0,0,0,0.02); }
.cartao-correcao h3 { color: #1e293b; font-size: 18px; margin-bottom: 20px; }

.lista-correcao { list-style: none; margin-bottom: 25px; }
.lista-correcao li { display: flex; justify-content: space-between; align-items: center; padding: 12px 0; border-bottom: 1px solid #f1f5f9; font-size: 14px; }

.status-correto { background-color: #dcfce7; color: #166534; padding: 4px 10px; border-radius: 4px; font-size: 12px; font-weight: 600; }
.status-incorreto { background-color: #fee2e2; color: #991b1b; padding: 4px 10px; border-radius: 4px; font-size: 12px; font-weight: 600; }
.status-neutro { background-color: #f1f5f9; color: #475569; padding: 4px 10px; border-radius: 4px; font-size: 12px; font-weight: 600; }

.caixa-feedback { background-color: #f8fafc; border-left: 4px solid #3b82f6; padding: 15px; border-radius: 0 6px 6px 0; margin-bottom: 20px; }
.caixa-feedback h4 { font-size: 14px; color: #1e293b; margin-bottom: 5px; }
.texto-feedback { font-size: 13px; color: #475569; }

.acoes-formulario { margin-top: 25px; display: flex; align-items: center; gap: 15px; }
.btn-salvar { background-color: #1a56db; color: white; border: none; padding: 10px 20px; border-radius: 6px; cursor: pointer; text-decoration: none; font-weight: bold;}
.btn-salvar:hover { background-color: #1e40af; }
.mt-3 { margin-top: 15px; }
.text-align-left { text-align: left !important; }

/* IDENTIFICAÇÃO E FEEDBACK */
.identificacao-aluno { background: #eef4fa; border: 1px solid #d5e3f3; border-radius: 6px; padding: 10px 14px; margin-bottom: 15px; font-size: 14px; color: #1e293b; }
.caixa-feedback-professor { margin-top: 20px; padding: 16px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; }
.caixa-feedback-professor h4 { color: #1e293b; margin-bottom: 10px; }
.campo-feedback { width: 100%; padding: 10px 12px; border: 1px solid #d1d5db; border-radius: 6px; font-size: 14px; resize: vertical; }
.acoes-feedback { display: flex; gap: 10px; margin-top: 10px; align-items: center; }
.btn-excluir-feedback { background: #fee2e2; color: #b91c1c; border: none; border-radius: 6px; padding: 10px 16px; font-weight: 600; cursor: pointer; }
.alerta-feedback { color: #dc2626; font-size: 13px; margin-top: 8px; }
.ok-feedback { color: #166534; font-size: 13px; margin-top: 8px; }
.sem-feedback { color: #94a3b8; font-style: italic; font-size: 14px; }
.item-feedback { background: #ffffff; border-left: 4px solid #1a56db; padding: 10px 12px; margin-bottom: 8px; font-size: 14px; color: #1e293b; }
.item-feedback small { color: #94a3b8; }
</style>