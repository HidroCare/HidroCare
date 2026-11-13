import { createRouter, createWebHistory } from 'vue-router'
import Login from '@/views/Login.vue'
import TelaEstudante from '@/views/TelaEstudante.vue'
import AtividadeEstudante from '@/views/AtividadeEstudante.vue'
import Resultado from '@/views/Resultado.vue'
import TelaProfessor from '@/views/TelaProfessor.vue'
import CadastroCenario from '@/views/CadastroCenario.vue'

const routes = [
    { path: '/', component: Login },
    { path: '/tela-estudante', component: TelaEstudante },
    { path: '/tela-professor', component: TelaProfessor },
    {path: '/cadastro-cenario', component: CadastroCenario},
    { path: '/atividade', component: AtividadeEstudante },
    { path: '/resultado', component: Resultado }
]

const router = createRouter({
    history: createWebHistory(),
    routes
})

export default router