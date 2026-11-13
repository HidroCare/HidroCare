<template>
  <div class="fundo-painel">
    
    <header class="cabecalho-principal estudante">
      <div class="cabecalho-conteudo">
        <div class="logo-painel">HidroCare <span class="divisor-logo">|</span> Resultado</div>
        <div class="usuario-info">
          <span>Estudante: {{ nomeUsuario }}</span>
          <a href="#" @click.prevent="sair" class="link-sair">Sair</a>
        </div>
      </div>
    </header>

    <main class="painel-container">
      <div v-if="carregando" class="mensagem-carregando">
        <p>Calculando seu resultado no banco de dados...</p>
      </div>

      <div v-else-if="!resultado" class="mensagem-carregando">
        <p>Nenhum resultado encontrado. Volte ao início e faça uma atividade.</p>
        <button @click="voltarAoInicio" class="btn-salvar mt-3">Voltar ao Início</button>
      </div>
      
      <div v-else class="resultado-grid text-align-left">
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
              Você teve <strong>{{ resultado.acertos }} acertos</strong> e <strong>{{ resultado.erros }} erros</strong>. 
              Classificação: {{ resultado.classificacao || 'Concluído' }}.
            </p>
          </div>

          <ul class="lista-correcao">
            <!-- Laço de repetição puxando os itens registrados na submissão -->
            <li v-for="reg in registros" :key="reg.id">
              <span>{{ reg.descricao }} ({{ reg.tipo }}) - {{ reg.valor_ml }}ml</span>
              
              <span v-if="reg.correto === true" class="status-correto">Correto</span>
              <span v-else-if="reg.correto === false" class="status-incorreto">Incorreto</span>
              <span v-else class="status-neutro">Registrado</span>
            </li>
          </ul>

          <div class="acoes-formulario" style="justify-content: flex-end;">
            <button @click="voltarAoInicio" class="btn-salvar">Concluir e Voltar</button>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'

const router = useRouter()
const route = useRoute()

const nomeUsuario = ref('Carregando...') 
const carregando = ref(true)
const resultado = ref(null)
const registros = ref([])
const perfilUsuario= ref('')

onMounted(async () => {
  const {data: {user}}= await supabase.auth.getUser()

  if(user){
    nomeUsuario.value = user.user_metadata?.nome || 'Usuário'
    perfilUsuario.value =user.user_metadata?.perfilUsuario
    await buscarResultado(user.id)
  }else{
    router.push('/')
  }
})

const buscarResultado = async (estudanteId) => {
  carregando.value = true
  try {
    let submissaoId = route.query.id // Caso a tela anterior envie o ID na URL (ex: /resultado?id=123)
    
    // Se não tiver ID na URL, busca automaticamente a ÚLTIMA submissão deste estudante
    if (!submissaoId) {
      const { data: ultimaSubmissao } = await supabase
        .from('submissoes')
        .select('id')
        .eq('estudante_id', estudanteId)
        .order('created_at', { ascending: false })
        .limit(1)
        .single()
        
      if (ultimaSubmissao) submissaoId = ultimaSubmissao.id
    }

    if (submissaoId) {
      // 1. Puxa a tabela Resultados ligada à submissão
      const { data: resData } = await supabase
        .from('resultados')
        .select('*')
        .eq('submissao_id', submissaoId)
        .single()
      
      resultado.value = resData

      // 2. Puxa os itens que ele digitou (tabela Registros)
      const { data: regData } = await supabase
        .from('registros')
        .select('*')
        .eq('submissao_id', submissaoId)
      
      registros.value = regData || []
    }
  } catch (error) {
    console.error('Erro ao buscar o resultado:', error)
  } finally {
    carregando.value = false
  }
}

const sair = async () => {
  await supabase.auth.signOut()
  router.push('/')
}
const voltarAoInicio = () => {
  if (perfilUsuario.value === 'professor') {
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
</style>