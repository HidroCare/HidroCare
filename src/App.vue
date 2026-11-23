
<template>
  <!-- O router-view injeta dinamicamente a tela atual com base na URL -->
  <router-view />
</template>

<script setup>
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase, abriuPeloLinkDeRecuperacao } from '@/lib/supabase'
import { buscarPerfil, paginaInicial } from '@/composables/useAuth'

const router = useRouter()

onMounted(async () => {
    // Espera a primeira navegação terminar antes de verificar a rota atual.
    // Isso evita perder a tela ao atualizar a página (F5).
    await router.isReady()

    // Se já existe login e estamos na tela de Login ('/'), vai direto para a área do usuário.
    // Quem chegou pelo link de "esqueci a senha" fica no Login para definir a nova senha.
    const { data } = await supabase.auth.getSession()
    const usuario = data.session?.user

    if (usuario && router.currentRoute.value.path === '/' && !abriuPeloLinkDeRecuperacao) {
        const perfil = await buscarPerfil(usuario.id)
        router.push(paginaInicial(perfil?.perfil))
    }

    // Ao sair (ou se a sessão for encerrada), volta para o Login
    supabase.auth.onAuthStateChange((event) => {
        if (event === 'SIGNED_OUT') router.push('/')
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
