<template>
  <div class="fundo-painel">
    <main class="painel-container">
      
      <div class="resultado-grid text-align-left">
        <!-- LADO ESQUERDO: BALANÇO -->
        <div class="cartao-balanco">
          <h3>Balanço Hídrico Final</h3>
          <div class="display-balanco positivo">+ 300 ml</div>
          <span class="badge-status positivo">Balanço Positivo</span>
        </div>

        <!-- LADO DIREITO: CORREÇÃO -->
        <div class="cartao-correcao">
          <h3>Correção Automática</h3>
          
          <div class="caixa-feedback">
            <h4>Feedback do Sistema</h4>
            <p class="texto-feedback">Seus cálculos de entrada totalizaram 1500 ml e saídas 1200 ml. O resultado está correto.</p>
          </div>

          <ul class="lista-correcao">
            <li>
              <span>Soro Fisiológico (Entrada) - 1000ml</span>
              <span class="status-correto">Correto</span>
            </li>
            <li>
              <span>Diurese (Saída) - 800ml</span>
              <span class="status-correto">Correto</span>
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
import { useRouter } from 'vue-router'

const router = useRouter()
const voltarAoInicio = () => router.push('/tela-estudante')
</script>

<style scoped>
.fundo-painel { min-height: 100vh; padding-top: 20px;}
.painel-container { max-width: 1100px; margin: 30px auto; padding: 0 20px; }

.resultado-grid { display: grid; grid-template-columns: 1fr 2fr; gap: 20px; }
@media (max-width: 768px) { .resultado-grid { grid-template-columns: 1fr; } }

.cartao-balanco { background: #f8fafc; border: 1px solid #e2e8f0; border-top: 4px solid #16a34a; border-radius: 8px; padding: 30px; text-align: center; }
.cartao-balanco h3 { color: #475569; font-size: 16px; margin-bottom: 20px; }

.display-balanco { font-size: 42px; font-weight: 700; margin-bottom: 15px; }
.display-balanco.positivo { color: #16a34a; }

.badge-status { display: inline-block; padding: 6px 16px; border-radius: 20px; font-size: 14px; font-weight: 600; }
.badge-status.positivo { background-color: #dcfce7; color: #166534; }

.cartao-correcao { background: #ffffff; border-radius: 8px; padding: 30px; box-shadow: 0 4px 6px rgba(0,0,0,0.02); }
.cartao-correcao h3 { color: #1e293b; font-size: 18px; margin-bottom: 20px; }

.lista-correcao { list-style: none; margin-bottom: 25px; }
.lista-correcao li { display: flex; justify-content: space-between; align-items: center; padding: 12px 0; border-bottom: 1px solid #f1f5f9; font-size: 14px; }

.status-correto { background-color: #dcfce7; color: #166534; padding: 4px 10px; border-radius: 4px; font-size: 12px; font-weight: 600; }

.caixa-feedback { background-color: #f8fafc; border-left: 4px solid #3b82f6; padding: 15px; border-radius: 0 6px 6px 0; margin-bottom: 20px; }
.caixa-feedback h4 { font-size: 14px; color: #1e293b; margin-bottom: 5px; }
.texto-feedback { font-size: 13px; color: #475569; }

.acoes-formulario { margin-top: 25px; display: flex; align-items: center; gap: 15px; }
.btn-salvar { background-color: #1a56db; color: white; border: none; padding: 10px 20px; border-radius: 6px; cursor: pointer; text-decoration: none; font-weight: bold;}
.btn-salvar:hover { background-color: #1e40af; }

.text-align-left { text-align: left !important; }
</style>