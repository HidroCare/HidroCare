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
    { path: '/tela-estudante', component: TelaEstudante, meta: { perfil: 'estudante' } },
    { path: '/tela-professor', component: TelaProfessor, meta: { perfil: 'professor' } },
    { path: '/cadastro-cenario', component: CadastroCenario, meta: { perfil: 'professor' } },
    { path: '/atividade', component: AtividadeEstudante, meta: { perfil: 'estudante' } },
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
    // A tela de login permanece acessível.
    if (to.path === '/') return true;

    // Verifica se existe uma sessão autenticada.
    const { data, error } = await supabase.auth.getSession();
    const usuario = data.session?.user;

    if (error || !usuario) {
        return '/';
    }

    // Verifica o perfil somente quando a rota exige um perfil específico.
    const perfilNecessario = to.meta.perfil;
    if (perfilNecessario) {
        const perfil = await buscarPerfil(usuario.id);
        // Perfil inexistente ou não identificado.
        if (!perfil?.perfil) {
            await supabase.auth.signOut();
            return '/';
        }

        // Impede o acesso quando o perfil não corresponde à rota.
        if (perfil.perfil !== perfilNecessario) {
            return paginaInicial(perfil.perfil);
        }
    }
    return true;
})

export default router
