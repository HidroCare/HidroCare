<template>
  <div class="fundo-painel">
    <!-- CABEÇALHO -->
    <header class="cabecalho-principal">
      <div class="cabecalho-conteudo">
        <div class="logo-painel"><a href="#" @click.prevent="voltar" class="link-sair">HidroCare</a> <span class="divisor-logo">|</span> Gestão</div>
        <div class="usuario-info">
          <span>Professor(a): {{ nomeUsuario }}</span>
          <a href="#" @click.prevent="sair" class="link-sair">Sair</a>
        </div>
      </div>
    </header>

    <main class="painel-container">
      <div class="cartao-formulario">
        <div class="cartao-cabecalho text-align-left">
          <h2>{{ editando ? 'Editar Cenário Clínico' : 'Cadastrar Novo Cenário Clínico' }}</h2>
          <p class="subtitulo-painel">Preencha os dados do caso e monte o gabarito oficial.</p>
        </div>

        <form @submit.prevent="salvarCenario" class="formulario-cenario">
          
          <!-- LINHA 1: Paciente e Título -->
          <div class="linha-formulario">
            <div class="grupo-input flex-1">
              <label for="paciente">Paciente Fictício</label>
              
              <!-- SELECT DINÂMICO LIGADO AO SUPABASE -->
              <select id="paciente" v-model="formulario.paciente_id" class="input-estilizado" required :disabled="carregandoPacientes">
                <option value="" disabled>
                  {{ carregandoPacientes ? 'Carregando pacientes...' : 'Selecione um paciente...' }}
                </option>
                <!-- Renderiza os pacientes vindos do banco de dados -->
                <option v-for="paciente in listaPacientes" :key="paciente.id" :value="paciente.id">
                  {{ paciente.nome }} ({{ paciente.idade }} anos) - {{ paciente.motivo_internacao }}
                </option>
              </select>
            </div>
            
            <div class="grupo-input flex-2">
              <label for="titulo">Título da Atividade</label>
              <input type="text" id="titulo" v-model="formulario.titulo" class="input-estilizado" placeholder="Ex: Controle hídrico rigoroso - 24h" required>
            </div>
          </div>
          
          <!-- LINHA 2: Enunciado -->
          <div class="grupo-input text-align-left">
            <label for="enunciado">Enunciado Clínico</label>
            <textarea id="enunciado" v-model="formulario.enunciado" class="input-estilizado textarea" rows="4" placeholder="Descreva a situação clínica e os dados iniciais do paciente..." required></textarea>
          </div>

          <!-- PUBLICAÇÃO -->
          <div class="grupo-input text-align-left">
            <label class="opcao-publicar">
              <input type="checkbox" v-model="formulario.publicado">
              Publicar para os estudantes (desmarcado = rascunho, só você vê)
            </label>
          </div>

          <!-- SEÇÃO DO GABARITO (A Tabela) -->
          <div class="secao-gabarito text-align-left">
            <h3>Gabarito Obrigatório (Entradas e Saídas)</h3>
            <p v-if="gabaritoBloqueado" class="aviso-gabarito">
              Este cenário já tem {{ totalRespostas }} resposta(s) de estudantes. O gabarito não pode mais ser alterado,
              para não mudar a correção de quem já respondeu. Título, enunciado, paciente e publicação continuam editáveis.
            </p>
            
            <div style="overflow-x: auto;">
              <table class="tabela-dados">
                <thead>
                  <tr>
                    <th>Tipo</th>
                    <th>Horário</th>
                    <th>Descrição do Fluido / Via</th>
                    <th>Valor Esperado (mL)</th>
                    <th>Ação</th>
                  </tr>
                </thead>
                <tbody>
                  <!-- ITENS JÁ ADICIONADOS AO GABARITO -->
                  <tr v-for="(item, index) in gabarito" :key="index">
                    <td>
                      <span class="badge" :class="item.tipo === 'Entrada' ? 'entrada' : 'saida'">
                        {{ item.tipo }}
                      </span>
                    </td>
                    <td>{{ item.horario }}</td>
                    <td>{{ item.descricao }}</td>
                    <td>{{ item.valor }}</td>
                    <td>
                      <button v-if="!gabaritoBloqueado" type="button" @click="removerItemGabarito(index)" class="btn-tabela remover">Remover</button>
                    </td>
                  </tr>

                  <!-- LINHA PARA ADIÇÃO DE NOVO ITEM -->
                  <tr v-if="!gabaritoBloqueado" class="linha-adicao">
                    <td>
                      <select v-model="novoItem.tipo" class="input-estilizado-sm">
                        <option value="Entrada">Entrada</option>
                        <option value="Saída">Saída</option>
                      </select>
                    </td>
                    <td><input type="time" v-model="novoItem.horario" class="input-estilizado-sm"></td>
                    <td><input type="text" v-model="novoItem.descricao" class="input-estilizado-sm" placeholder="Ex: Soro / Diurese"></td>
                    <td><input type="number" v-model="novoItem.valor" class="input-estilizado-sm" placeholder="0"></td>
                    <td>
                      <button type="button" @click="adicionarItemGabarito" class="btn-tabela adicionar">Adicionar</button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- BOTÕES FINAIS -->
          <div class="acoes-formulario">
            <button type="button" @click="voltar" class="btn-voltar">Cancelar</button>
            <button type="submit" class="btn-salvar" :disabled="salvando">{{ salvando ? 'Salvando...' : (editando ? 'Salvar alterações' : 'Salvar Cenário') }}</button>
          </div>
        </form>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'

const router = useRouter()
const route = useRoute()
const { nomeUsuario } = useAuth()
const salvando = ref(false)

// Modo edição: a tela do professor abre /cadastro-cenario?id=<cenário>
const cenarioId = route.query.id
const editando = !!cenarioId
const totalRespostas = ref(0)
const idsOriginaisGabarito = ref([])
// Com respostas já enviadas o gabarito fica travado (as correções já foram calculadas com ele)
const gabaritoBloqueado = computed(() => editando && totalRespostas.value > 0)

// Variáveis para o carregamento dos pacientes
const listaPacientes = ref([])
const carregandoPacientes = ref(true)

// Dados do formulário principal
const formulario = ref({
  paciente_id: '', // Alterado para armazenar o ID do paciente (chave estrangeira)
  titulo: '',
  enunciado: '',
  publicado: true
})

// Lista que armazena os itens salvos no gabarito (ao editar, vem do banco)
const gabarito = ref(editando ? [] : [
  { tipo: 'Entrada', horario: '08:00', descricao: 'Soro Fisiológico 0.9% IV', valor: 500 }
])

const novoItem = ref({
  tipo: 'Entrada',
  horario: '',
  descricao: '',
  valor: null
})

// 1. AO ABRIR A TELA: carrega os pacientes e, se for edição, o cenário e o gabarito
onMounted(async () => {
  await buscarPacientes()
  if (editando) await carregarCenario()
})

const buscarPacientes = async () => {
  carregandoPacientes.value = true
  try {
    const { data, error } = await supabase
      .from('pacientes')
      .select('id, nome, idade, motivo_internacao')
      .order('nome')

    if (error) throw error
    listaPacientes.value = data
  } catch (error) {
    console.error('Erro ao carregar pacientes:', error)
    alert('Erro ao buscar os pacientes no banco de dados.')
  } finally {
    carregandoPacientes.value = false
  }
}

// Carrega o cenário que será editado (só o professor dono pode editar)
const carregarCenario = async () => {
  const { data: { session } } = await supabase.auth.getSession()
  const user = session?.user
  const { data: cenario } = await supabase
    .from('cenarios')
    .select('id, paciente_id, professor_id, titulo, enunciado, publicado')
    .eq('id', cenarioId)
    .maybeSingle()

  if (!cenario || cenario.professor_id !== user?.id) {
    alert('Cenário não encontrado ou não pertence a você.')
    voltar()
    return
  }

  formulario.value = {
    paciente_id: cenario.paciente_id,
    titulo: cenario.titulo,
    enunciado: cenario.enunciado,
    publicado: cenario.publicado
  }

  const { data: itens } = await supabase
    .from('gabarito_itens')
    .select('id, tipo, horario, descricao, valor_ml')
    .eq('cenario_id', cenarioId)
    .order('horario')

  // o banco guarda "entrada"/"saida"; a tela mostra "Entrada"/"Saída"
  gabarito.value = (itens || []).map(i => ({
    id: i.id,
    tipo: i.tipo === 'entrada' ? 'Entrada' : 'Saída',
    horario: (i.horario || '').slice(0, 5),
    descricao: i.descricao,
    valor: Number(i.valor_ml)
  }))
  idsOriginaisGabarito.value = gabarito.value.map(i => i.id)

  // Quantos estudantes já responderam? (trava o gabarito)
  const { count } = await supabase
    .from('submissoes')
    .select('id', { count: 'exact', head: true })
    .eq('cenario_id', cenarioId)
  totalRespostas.value = count || 0
}

// Funções da Tabela do Gabarito
const adicionarItemGabarito = () => {
  if (!novoItem.value.horario || !novoItem.value.descricao || !novoItem.value.valor) {
    alert("Preencha o horário, descrição e valor antes de adicionar ao gabarito.")
    return
  }
  gabarito.value.push({ ...novoItem.value })
  novoItem.value.horario = ''
  novoItem.value.descricao = ''
  novoItem.value.valor = null
}

const removerItemGabarito = (index) => {
  gabarito.value.splice(index, 1)
}

// Funções de navegação e Logout
const voltar = () => router.push('/tela-professor')

const sair = async () => {
  const { error } = await supabase.auth.signOut()
  if (error) {
    console.error("Erro ao sair:", error)
  } else {
    router.push('/')
  }
}

// O banco usa "entrada"/"saida" em minúsculas e sem acento
const paraBanco = (item, idCenario) => ({
  cenario_id: idCenario,
  tipo: item.tipo === 'Entrada' ? 'entrada' : 'saida',
  descricao: item.descricao,
  valor_ml: Number(item.valor),
  horario: item.horario
})

// CRIAR: cenário primeiro, depois os itens do gabarito
const criarCenario = async (user) => {
  const { data: cenario, error: erroCenario } = await supabase
    .from('cenarios')
    .insert({
      paciente_id: formulario.value.paciente_id,
      professor_id: user.id,
      titulo: formulario.value.titulo,
      enunciado: formulario.value.enunciado,
      publicado: formulario.value.publicado
    })
    .select('id')
    .single()
  if (erroCenario) throw erroCenario

  const { error: erroGabarito } = await supabase
    .from('gabarito_itens')
    .insert(gabarito.value.map(item => paraBanco(item, cenario.id)))

  if (erroGabarito) {
    // não deixa um cenário sem gabarito
    await supabase.from('cenarios').delete().eq('id', cenario.id)
    throw erroGabarito
  }
}

// EDITAR: atualiza o cenário e sincroniza o gabarito (itens novos entram, removidos saem)
const atualizarCenario = async () => {
  const { data: atualizado, error: erroCenario } = await supabase
    .from('cenarios')
    .update({
      paciente_id: formulario.value.paciente_id,
      titulo: formulario.value.titulo,
      enunciado: formulario.value.enunciado,
      publicado: formulario.value.publicado
    })
    .eq('id', cenarioId)
    .select('id')
  if (erroCenario) throw erroCenario
  if (!atualizado || atualizado.length === 0) throw new Error('Sem permissão para alterar este cenário.')

  if (gabaritoBloqueado.value) return

  // 1º insere os novos (se falhar, nada foi apagado); 2º apaga os removidos
  const novos = gabarito.value.filter(item => !item.id)
  if (novos.length > 0) {
    const { error } = await supabase.from('gabarito_itens').insert(novos.map(item => paraBanco(item, cenarioId)))
    if (error) throw error
  }

  const removidos = idsOriginaisGabarito.value.filter(id => !gabarito.value.some(item => item.id === id))
  if (removidos.length > 0) {
    const { error } = await supabase.from('gabarito_itens').delete().in('id', removidos)
    if (error) throw error
  }
}

// Botão do formulário
const salvarCenario = async () => {
  if (gabarito.value.length === 0) {
    alert("Adicione pelo menos um item no gabarito antes de salvar o cenário!")
    return
  }

  salvando.value = true
  try {
    if (editando) {
      await atualizarCenario()
    } else {
      const { data: { session } } = await supabase.auth.getSession()
  const user = session?.user
      await criarCenario(user)
    }
    alert(editando ? 'Cenário atualizado!' : 'Cenário salvo com sucesso!')
    voltar()
  } catch (error) {
    console.error('Erro ao salvar o cenário:', error)
    alert('Não foi possível salvar o cenário: ' + error.message)
  } finally {
    salvando.value = false
  }
}
</script>

<style scoped>
/* FUNDO E CABEÇALHO */
.fundo-painel { min-height: 100vh; background-color: #f4f6f9; }
.cabecalho-principal { background-color: #2c3e50; color: #ffffff; padding: 15px 30px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
.cabecalho-conteudo { max-width: 1100px; margin: 0 auto; display: flex; justify-content: space-between; align-items: center; }
.logo-painel { font-size: 20px; font-weight: 600; }
.divisor-logo { color: #94a3b8; margin: 0 5px; }
.usuario-info { display: flex; align-items: center; gap: 15px; font-size: 14px; color: #cbd5e1; }
.link-sair { color: #ffffff; text-decoration: none; font-weight: 500; }
.link-sair:hover { text-decoration: underline; }

/* CONTAINER E CARTÃO */
.painel-container { max-width: 1100px; margin: 30px auto; padding: 0 20px; }
.cartao-formulario { background: #ffffff; padding: 30px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.02); }
.cartao-cabecalho { margin-bottom: 25px; }
.cartao-cabecalho h2 { color: #1e293b; font-size: 20px; margin-bottom: 5px; }
.subtitulo-painel { color: #64748b; font-size: 14px; }

/* ESTRUTURA DO FORMULÁRIO */
.linha-formulario { display: flex; gap: 20px; flex-wrap: wrap; margin-bottom: 20px; }
.flex-1 { flex: 1; min-width: 250px; }
.flex-2 { flex: 2; min-width: 250px; }
.grupo-input { margin-bottom: 20px; text-align: left; }
.grupo-input label { display: block; margin-bottom: 8px; color: #374151; font-weight: 500; font-size: 14px; }

/* INPUTS ESTILIZADOS */
.input-estilizado { width: 100%; padding: 10px 12px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 14px; outline: none; background-color: #ffffff; transition: border-color 0.2s, box-shadow 0.2s; }
.input-estilizado:focus { border-color: #1a56db; box-shadow: 0 0 0 3px rgba(26, 86, 219, 0.15); }
.textarea { resize: vertical; }

.input-estilizado-sm { width: 100%; padding: 8px 10px; border: 1px solid #cbd5e1; border-radius: 4px; font-size: 13px; outline: none; background-color: #ffffff; }
.input-estilizado-sm:focus { border-color: #1a56db; box-shadow: 0 0 0 2px rgba(26, 86, 219, 0.15); }

/* SEÇÃO DO GABARITO (TABELA) */
.secao-gabarito { margin-top: 30px; border-top: 1px solid #e2e8f0; padding-top: 25px; }
.secao-gabarito h3 { color: #1e293b; font-size: 18px; margin-bottom: 15px; }

.tabela-dados { width: 100%; border-collapse: collapse; font-size: 14px; }
.tabela-dados th, .tabela-dados td { padding: 12px; text-align: left; border-bottom: 1px solid #e2e8f0; }
.tabela-dados th { background-color: #f8fafc; color: #475569; font-weight: 600; }

.badge { padding: 4px 10px; border-radius: 4px; font-size: 12px; font-weight: 600; }
.badge.entrada { background-color: #e0f2fe; color: #0369a1; }
.badge.saida { background-color: #fef3c7; color: #92400e; }

.btn-tabela { padding: 6px 12px; border-radius: 4px; font-size: 12px; border: none; cursor: pointer; font-weight: 600; }
.btn-tabela.remover { background-color: #fee2e2; color: #991b1b; }
.btn-tabela.remover:hover { background-color: #fecaca; }
.btn-tabela.adicionar { background-color: #dbeafe; color: #1e40af; }
.btn-tabela.adicionar:hover { background-color: #bfdbfe; }

/* BOTÕES FINAIS */
.acoes-formulario { margin-top: 30px; display: flex; justify-content: flex-end; align-items: center; gap: 15px; }
.btn-salvar { background-color: #16a34a; color: #fff; padding: 10px 20px; border-radius: 6px; border: none; font-weight: 600; cursor: pointer; }
.btn-salvar:hover { background-color: #15803d; }
.btn-voltar { color: #64748b; text-decoration: none; font-size: 14px; font-weight: 500; cursor: pointer; background: none; border: none; }
.btn-voltar:hover { text-decoration: underline; }

.text-align-left { text-align: left !important; }

/* EDIÇÃO */
.opcao-publicar { display: flex; align-items: center; gap: 8px; font-size: 14px; color: #374151; cursor: pointer; }
.aviso-gabarito { background: #fff7e6; border: 1px solid #fcd9a0; color: #8a5a00; padding: 10px 12px; border-radius: 6px; font-size: 13px; margin: 10px 0; }
</style>
