<template>
  <div class="fundo-painel">
    <!-- CABEÇALHO -->
    <header class="cabecalho-principal">
      <div class="cabecalho-conteudo">
        <div class="logo-painel">HidroCare <span class="divisor-logo">|</span> Painel do Professor</div>
        <div class="usuario-info">
          <a href="#" @click.prevent="sair" class="link-sair">Sair</a>
        </div>
      </div>
    </header>

    <!-- CONTEÚDO PRINCIPAL -->
    <main class="painel-container">
      <div class="boas-vindas" style="display: flex; justify-content: space-between; align-items: center;">
        <div>
          <h2>Meus Cenários</h2>
          <p class="subtitulo-painel">Gerencie os casos clínicos para os seus alunos.</p>
        </div>
        <button @click="criarNovo" class="btn-acao primario">+ Novo Cenário</button>
      </div>

      <div class="cards-grid">
        <!-- CARTÃO DO CENÁRIO -->
        <div class="card-acao">
          <div class="card-corpo text-align-left">
            <h3>João Silva (UTI - 04)</h3>
            <p class="mb-2"><strong>Status:</strong> Ativo para alunos</p>
            <p>Paciente pós-operatório cardíaco.</p>
            <button class="btn-acao mt-3" style="background-color: #e2e8f0; color: #1e293b; width: 100%;">
              Ver Resultados dos Alunos
            </button>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router'

const router = useRouter()

const criarNovo = () => router.push('/cadastro-cenario')
const sair = () => router.push('/')
</script>

<style scoped>
.fundo-painel { min-height: 100vh; }
.cabecalho-principal { background-color: #2c3e50; color: #ffffff; padding: 15px 30px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
.cabecalho-conteudo { max-width: 1100px; margin: 0 auto; display: flex; justify-content: space-between; align-items: center; }
.logo-painel { font-size: 20px; font-weight: 600; }
.divisor-logo { color: #94a3b8; margin: 0 5px; }
.usuario-info span { margin-right: 15px; font-size: 14px; color: #cbd5e1; }
.link-sair { color: #ffffff; text-decoration: none; font-size: 14px; font-weight: 500; }
.link-sair:hover { text-decoration: underline; }

.painel-container { max-width: 1100px; margin: 30px auto; padding: 0 20px; }

.boas-vindas { margin-bottom: 25px; }
.boas-vindas h2 { color: #1e293b; font-size: 24px; }
.subtitulo-painel { color: #64748b; font-size: 14px; }

.cards-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }

.card-acao { background: #ffffff; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.02); border-top: 4px solid #1a56db; transition: transform 0.2s; }
.card-acao:hover { transform: translateY(-3px); }

.card-corpo { padding: 30px; text-align: center; }
.card-corpo h3 { color: #1e293b; margin-bottom: 10px; font-size: 18px; }
.card-corpo p { color: #64748b; font-size: 14px; margin-bottom: 20px; }

.btn-acao { display: inline-block; padding: 10px 20px; border-radius: 6px; font-size: 14px; font-weight: 600; text-decoration: none; cursor: pointer; border: none; }
.btn-acao.primario { background-color: #1a56db; color: #fff; }
.btn-acao.primario:hover { background-color: #1e40af; }

.text-align-left { text-align: left !important; }
.mb-2 { margin-bottom: 8px; }
.mt-3 { margin-top: 15px; }
</style>