import { createRouter, createWebHistory } from 'vue-router'
import Login from '@/views/Login.vue'
import EscolhaCenario from '@/views/EscolhaCenario.vue'
import AtividadeEstudante from '@/views/AtividadeEstudante.vue'
import Resultado from '@/views/Resultado.vue'

const routes = [
    { path: '/', component: Login },
    { path: '/escolha-cenario', component: EscolhaCenario },
    { path: '/atividade', component: AtividadeEstudante },
    { path: '/resultado', component: Resultado }
]

const router = createRouter({
    history: createWebHistory(),
    routes
})

export default router