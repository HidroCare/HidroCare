<template>
  <div class="fundo-painel">
    <!-- CABEÇALHO (Adaptado para o padrão Vue) -->
    <header class="cabecalho-principal">
      <div class="cabecalho-conteudo">
        <div class="logo-painel">HidroCare <span class="divisor-logo">|</span> Gestão</div>
        <div class="usuario-info">
          <span>Professor(a)</span>
          <a href="#" @click.prevent="sair" class="link-sair">Sair</a>
        </div>
      </div>
    </header>

    <main class="painel-container">
      <div class="cartao-formulario">
        <div class="cartao-cabecalho text-align-left">
          <h2>Cadastrar Novo Cenário Clínico</h2>
          <p class="subtitulo-painel">Preencha os dados do caso e monte o gabarito oficial.</p>
        </div>

        <form @submit.prevent="salvarCenario" class="formulario-cenario">
          
          <!-- LINHA 1: Paciente e Título -->
          <div class="linha-formulario">
            <div class="grupo-input flex-1">
              <label for="paciente">Paciente Fictício</label>
              <select id="paciente" v-model="formulario.paciente" class="input-estilizado" required>
                <option value="" disabled>Selecione um paciente...</option>
                <option value="João Silva">João Silva - Pós-operatório</option>
                <option value="Maria Souza">Maria Souza - UTI Cardiológica</option>
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

          <!-- SEÇÃO DO GABARITO (A Tabela) -->
          <div class="secao-gabarito text-align-left">
            <h3>Gabarito Obrigatório (Entradas e Saídas)</h3>
            
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
                      <button type="button" @click="removerItemGabarito(index)" class="btn-tabela remover">Remover</button>
                    </td>
                  </tr>

                  <!-- LINHA PARA ADIÇÃO DE NOVO ITEM -->
                  <tr class="linha-adicao">
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
            <button type="submit" class="btn-salvar">Publicar Cenário</button>
          </div>
        </form>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()

// Dados do formulário principal
const formulario = ref({
  paciente: '',
  titulo: '',
  enunciado: ''
})

// Lista que armazena os itens salvos no gabarito
const gabarito = ref([
  // Já deixei um item de exemplo, igual ao seu HTML!
  { tipo: 'Entrada', horario: '08:00', descricao: 'Soro Fisiológico 0.9% IV', valor: 500 }
])

// Objeto temporário para segurar os dados da linha que está sendo digitada
const novoItem = ref({
  tipo: 'Entrada',
  horario: '',
  descricao: '',
  valor: null
})

// Função para adicionar a linha digitada na tabela de cima
const adicionarItemGabarito = () => {
  // Pequena validação para não adicionar linha vazia
  if (!novoItem.value.horario || !novoItem.value.descricao || !novoItem.value.valor) {
    alert("Preencha o horário, descrição e valor antes de adicionar ao gabarito.")
    return
  }

  // Copia o item para a lista do gabarito
  gabarito.value.push({ ...novoItem.value })

  // Limpa os campos da linha de adição
  novoItem.value.horario = ''
  novoItem.value.descricao = ''
  novoItem.value.valor = null
}

// Função para remover um item da tabela
const removerItemGabarito = (index) => {
  gabarito.value.splice(index, 1)
}

// Funções de navegação
const voltar = () => router.push('/tela-professor')
const sair = () => router.push('/')

// Função de salvar o cenário completo
const salvarCenario = () => {
  if (gabarito.value.length === 0) {
    alert("Adicione pelo menos um item no gabarito antes de publicar o cenário!")
    return
  }
  
  console.log("Dados prontos para o Supabase:", {
    ...formulario.value,
    gabarito: gabarito.value
  })
  
  alert("Cenário e Gabarito prontos para serem salvos no banco de dados!")
  voltar()
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
</style>