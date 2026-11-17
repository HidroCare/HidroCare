import { createRouter, createWebHistory } from 'vue-router'
import Login from '@/views/Login.vue'
import TelaEstudante from '@/views/TelaEstudante.vue'
import AtividadeEstudante from '@/views/AtividadeEstudante.vue'
import Resultado from '@/views/Resultado.vue'
import TelaProfessor from '@/views/TelaProfessor.vue'
import CadastroCenario from '@/views/CadastroCenario.vue'
import { supabase } from '@/lib/supabase'
import { buscarPerfil, paginaInicial } from '@/composables/useAuth'

const routes = [
    { path: '/', component: Login },
    { path: '/tela-estudante', component: TelaEstudante },
    { path: '/tela-professor', component: TelaProfessor, meta: { soProfessor: true } },
    { path: '/cadastro-cenario', component: CadastroCenario, meta: { soProfessor: true } },
    { path: '/atividade', component: AtividadeEstudante },
    { path: '/resultado', component: Resultado }
]

const router = createRouter({
    history: createWebHistory(),
    routes
})

// Porteiro: sem login, só a tela de Login ('/') abre.
// As telas de professor só abrem para quem é professor NO BANCO (tabela usuarios).
// (a segurança de verdade continua nas regras do banco; isto só evita telas erradas)
router.beforeEach(async (to) => {
    if (to.path === '/') return true

    const { data } = await supabase.auth.getSession()
    const usuario = data.session?.user
    if (!usuario) return '/'

    if (to.meta.soProfessor) {
        const perfil = await buscarPerfil(usuario.id)
        if (perfil?.perfil !== 'professor') return paginaInicial(perfil?.perfil)
    }
    return true
})

export default router
