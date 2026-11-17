import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

const user = ref(null)
const perfilUsuario = ref(null)

// Perfil e nome vêm da tabela "usuarios" (definidos pelo banco a partir do e-mail),
// e não de dados que o próprio usuário digitou no cadastro.
export async function buscarPerfil(userId) {
    const { data, error } = await supabase
        .from('usuarios')
        .select('id, nome, email, perfil')
        .eq('id', userId)
        .maybeSingle()
    if (error) console.error('Erro ao carregar perfil:', error)
    return data ?? null
}

// Para onde cada perfil vai depois de entrar
export const paginaInicial = (perfil) =>
    perfil === 'professor' ? '/tela-professor' : '/tela-estudante'

async function carregarPerfil(u) {
    user.value = u
    if (!u) { perfilUsuario.value = null; return }
    perfilUsuario.value = await buscarPerfil(u.id)
}

supabase.auth.getSession().then(({ data }) => carregarPerfil(data.session?.user ?? null))

supabase.auth.onAuthStateChange((_e, session) => {
    // setTimeout evita travar o supabase-js ao chamar o banco dentro do callback
    setTimeout(() => carregarPerfil(session?.user ?? null), 0)
})

export function useAuth() {
    const isProfessor = computed(() => perfilUsuario.value?.perfil === 'professor')
    const nomeUsuario = computed(() => perfilUsuario.value?.nome || 'Usuário')

    return { user, perfilUsuario, isProfessor, nomeUsuario, carregarPerfil }
}