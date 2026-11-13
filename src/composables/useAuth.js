import { ref, computed } from 'vue' 
import { supabase } from '@/lib/supabase'

const user = ref(null)
const perfilUsuario = ref(null)


async function carregarPerfil(u) {
    user.value=u
    if(!u){ perfilUsuario.value = null; return;}
    const {data} = await supabase
    .from('usuarios')
    .select('*')
    .eq('id', u.id)
    .single()

    perfilUsuario.value =data
}
supabase.auth.getSession().then(({data})=> carregarPerfil(data.session?.user ?? null))

supabase.auth.onAuthStateChange((_e,session)=>{
    setTimeout(()=> carregarPerfil(session?.user ?? null),0)
})

export function useAuth(){
    const isProfessor= computed(()=>perfilUsuario.value?.perfil ==='professor')
    const nomeUsuario = computed(()=> perfilUsuario.value?.nome || 'Usuário')

    return{user,perfilUsuario,isProfessor,nomeUsuario,carregarPerfil}
}