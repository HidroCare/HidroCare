<template>
  <div class="fundo-painel">
    
    <!-- Cabeçalho da página do estudante -->
    <header class="cabecalho-principal estudante">
      <div class="cabecalho-conteudo">
        <div class="logo-painel">HidroCare <span class="divisor-logo">|</span> Atividade</div>
        <div class="usuario-info">
          <span>Estudante: Larissa Prado</span>
          <a href="#" @click.prevent="sair" class="link-sair">Sair</a>
        </div>
      </div>
    </header>

    <main class="painel-container">
      
      <!-- Bloco dinâmico com os dados do paciente escolhido pelo estudante -->
      <div class="bloco-paciente text-align-left">
        <div class="linha-formulario mb-2">
          <div class="flex-1">
            <label for="selecionar-paciente" class="form-label fw-bold text-primary">Selecione o Paciente:</label>
            <select id="selecionar-paciente" v-model="pacienteSelecionado" class="input-estilizado">
              <option value="joao">João Silva - Pós-operatório (6h)</option>
              <option value="maria">Maria Souza - UTI Cardiológica</option>
            </select>
          </div>
        </div>
        
        <hr class="my-3">

        <h3>Detalhes do Caso Clínico</h3>
        <p>Masculino, 45 anos, 70kg. Paciente em pós-operatório de cirurgia abdominal. Recebeu 500mL de SF e apresentou diurese de 450mL nas últimas 6h. Registre o balanço conforme o enunciado.</p>
      </div>

      <div class="cartao-formulario">
        <div class="cartao-cabecalho text-align-left">
          <h2>Registros de Entradas e Saídas</h2>
          <p class="subtitulo-painel">Adicione os volumes referentes ao período de acompanhamento do paciente selecionado.</p>
        </div>

        <div style="overflow-x: auto;">
          <table class="tabela-dados">
            <thead>
              <tr>
                <th>Tipo</th>
                <th>Horário</th>
                <th>Descrição</th>
                <th>Valor (mL)</th>
                <th>Ação</th>
              </tr>
            </thead>
            <tbody>
              <!-- ITENS JÁ ADICIONADOS PELO ESTUDANTE -->
              <tr v-for="(registro, index) in registros" :key="index">
                <td>
                  <span class="badge" :class="registro.tipo === 'Entrada' ? 'entrada' : 'saida'">
                    {{ registro.tipo }}
                  </span>
                </td>
                <td>{{ registro.horario }}</td>
                <td>{{ registro.descricao }}</td>
                <td>{{ registro.valor }}</td>
                <td>
                  <button type="button" @click="removerRegistro(index)" class="btn-tabela remover">Remover</button>
                </td>
              </tr>
              
              <!-- LINHA PARA ADIÇÃO DE NOVO REGISTRO -->
              <tr class="linha-adicao">
                <td>
                  <select v-model="novoRegistro.tipo" class="input-estilizado-sm">
                    <option value="Entrada">Entrada</option>
                    <option value="Saída">Saída</option>
                  </select>
                </td>
                <td><input type="time" v-model="novoRegistro.horario" class="input-estilizado-sm"></td>
                <td><input type="text" v-model="novoRegistro.descricao" class="input-estilizado-sm" placeholder="Descrição do fluido"></td>
                <td><input type="number" v-model="novoRegistro.valor" class="input-estilizado-sm" placeholder="0"></td>
                <td>
                  <button type="button" @click="adicionarRegistro" class="btn-tabela adicionar">Adicionar registro</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Alerta de validação (RN04) -->
        <p v-if="erroValidacao" class="alerta-validacao text-align-left">
          Informe um horário, uma descrição e um valor numérico positivo em mL.
        </p>

        <!-- Ações do Formulário e Aviso de Bloqueio (RN05) -->
        <div class="acoes-formulario alinhar-inicio text-align-left">
          <button @click="submeterAtividade" class="btn-salvar">Submeter registros</button>
          <span class="texto-aviso-bloqueio">Após o envio, a edição será bloqueada pelo sistema (RN05).</span>
        </div>
      </div>

    </main>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()

const pacienteSelecionado = ref('joao')
const erroValidacao = ref(false)

// Lista de registros da atividade (Já inicia com um de exemplo, como no seu HTML)
const registros = ref([
  { tipo: 'Entrada', horario: '08:00', descricao: 'Soro Fisiológico 0.9% IV', valor: 500 }
])

// Objeto reativo para a linha de digitação
const novoRegistro = ref({
  tipo: 'Entrada',
  horario: '',
  descricao: '',
  valor: null
})

// Função para jogar o item digitado para a tabela acima
const adicionarRegistro = () => {
  // Validação simples simulando a RN04
  if (!novoRegistro.value.horario || !novoRegistro.value.descricao || !novoRegistro.value.valor || novoRegistro.value.valor <= 0) {
    erroValidacao.value = true
    return
  }
  
  erroValidacao.value = false
  
  // Adiciona à lista
  registros.value.push({ ...novoRegistro.value })
  
  // Limpa os campos
  novoRegistro.value.horario = ''
  novoRegistro.value.descricao = ''
  novoRegistro.value.valor = null
}

const removerRegistro = (index) => {
  registros.value.splice(index, 1)
}

const submeterAtividade = () => {
  if (registros.value.length === 0) {
    alert("Adicione pelo menos um registro antes de submeter!")
    return
  }
  router.push('/resultado')
}

const sair = () => router.push('/')
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

/* CONTAINER E BLOCO DO PACIENTE */
.painel-container { max-width: 1100px; margin: 30px auto; padding: 0 20px; }
.bloco-paciente { background: #f0f9ff; border: 1px solid #bae6fd; padding: 20px; border-radius: 8px; margin-bottom: 25px; }
.bloco-paciente h3 { color: #0369a1; font-size: 16px; margin-bottom: 8px; }
.bloco-paciente p { color: #334155; font-size: 14px; line-height: 1.5; }

/* UTILITÁRIOS E ALINHAMENTOS DO HTML */
.text-align-left { text-align: left !important; }
.mb-2 { margin-bottom: 10px; }
.my-3 { margin-top: 15px; margin-bottom: 15px; border: 0; border-top: 1px solid #bae6fd; }
.flex-1 { flex: 1; min-width: 250px; }
.form-label { display: block; margin-bottom: 8px; font-size: 14px; }
.fw-bold { font-weight: bold; }
.text-primary { color: #0369a1; }

/* FORMULÁRIO E TABELA */
.cartao-formulario { background: #ffffff; padding: 30px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.02); }
.cartao-cabecalho { margin-bottom: 25px; }
.cartao-cabecalho h2 { color: #1e293b; font-size: 20px; margin-bottom: 5px; }
.subtitulo-painel { color: #64748b; font-size: 14px; }

.tabela-dados { width: 100%; border-collapse: collapse; font-size: 14px; margin-bottom: 15px;}
.tabela-dados th, .tabela-dados td { padding: 12px; text-align: left; border-bottom: 1px solid #e2e8f0; }
.tabela-dados th { background-color: #f8fafc; color: #475569; font-weight: 600; }

/* BADGES E INPUTS */
.badge { padding: 4px 10px; border-radius: 4px; font-size: 12px; font-weight: 600; }
.badge.entrada { background-color: #e0f2fe; color: #0369a1; }
.badge.saida { background-color: #fef3c7; color: #92400e; }

.input-estilizado { width: 100%; max-width: 400px; padding: 10px 12px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 14px; outline: none; background-color: #ffffff; }
.input-estilizado:focus { border-color: #1a56db; box-shadow: 0 0 0 3px rgba(26, 86, 219, 0.15); }

.input-estilizado-sm { width: 100%; padding: 8px 10px; border: 1px solid #cbd5e1; border-radius: 4px; font-size: 13px; outline: none; background-color: #ffffff; }
.input-estilizado-sm:focus { border-color: #1a56db; box-shadow: 0 0 0 2px rgba(26, 86, 219, 0.15); }

/* BOTÕES DA TABELA */
.btn-tabela { padding: 6px 12px; border-radius: 4px; font-size: 12px; border: none; cursor: pointer; font-weight: 600; }
.btn-tabela.remover { background-color: #fee2e2; color: #991b1b; }
.btn-tabela.remover:hover { background-color: #fecaca; }
.btn-tabela.adicionar { background-color: #dbeafe; color: #1e40af; }
.btn-tabela.adicionar:hover { background-color: #bfdbfe; }

/* AÇÕES DO FORMULÁRIO E AVISOS */
.alerta-validacao { color: #dc2626; font-size: 13px; font-weight: 500; margin-top: 10px; margin-bottom: 10px; }

.acoes-formulario { margin-top: 25px; display: flex; align-items: center; gap: 15px; }
.alinhar-inicio { justify-content: flex-start; } /* Traz o botão e o texto para a esquerda */
.texto-aviso-bloqueio { font-size: 13px; color: #64748b; font-style: italic; }

.btn-salvar { background-color: #1a56db; color: #fff; padding: 10px 20px; border-radius: 6px; border: none; font-weight: 600; cursor: pointer; text-decoration: none; }
.btn-salvar:hover { background-color: #1e40af; }
</style>