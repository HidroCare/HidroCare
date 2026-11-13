<template>
<!-- O router-view injeta dinamicamente a tela atual com base na URL (ex: /login, /escolha-cenario, /atividade) -->
    <router-view />
</template>

<script setup>
    import { onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'

const router = useRouter()

onMounted(async () => {
  // TUTORIAL: Busca o usuário logado no navegador
    const { data: { user }, error } = await supabase.auth.getUser()

  // Se o usuário existir e estivermos na tela de Login ('/'), pula direto pra área dele
    if (user && router.currentRoute.value.path === '/') {
        const perfil = user.user_metadata?.perfil
        if (perfil === 'professor') {
            router.push('/tela-professor')
        } else {
            router.push('/tela-estudante')
        }
    }

  // Bônus: Isso fica "escutando" a sessão. Se a sessão expirar, expulsa pro Login.
    supabase.auth.onAuthStateChange((event, session) => {
        if (event === 'SIGNED_OUT' || !session) {
        router.push('/')
        }
        })
    })
</script>

<style>
/* RESET BÁSICO E CONFIGURAÇÕES GLOBAIS */
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

body {
    background-color: #f4f6f9;
    min-height: 100vh;
}

.text-align-left { text-align: left !important; }
.mb-2 { margin-bottom: 8px; }
.mt-2 { margin-top: 8px; }
.mt-3 { margin-top: 15px; }
.mb-3 { margin-bottom: 15px; }
</style>