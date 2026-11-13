<template>
    <div class="fundo-tela">
        <main class="login-container">
        <div class="login-cartao">
            
            <!-- Cabeçalho Dinâmico -->
            <header class="login-cabecalho">
            <h1 class="logo-titulo">HidroCare</h1>
            <p class="logo-subtitulo">
                <span v-if="modo === 'login'">Acesse o sistema</span>
                <span v-else-if="modo === 'cadastro'">Crie sua conta</span>
                <span v-else>Recuperar senha</span>
            </p>
            </header>
            
            <!-- Mensagens de Feedback (Erro ou Sucesso) -->
            <div v-if="mensagemErro" class="alerta-erro">
            {{ mensagemErro }}
            </div>
            <div v-if="mensagemSucesso" class="alerta-sucesso">
            {{ mensagemSucesso }}
            </div>
            
            <!-- ==========================================
                1. FORMULÁRIO DE LOGIN
                ========================================== -->
            <form v-if="modo === 'login'" class="login-formulario" @submit.prevent="realizarLogin">
            <div class="grupo-input">
                <label for="login-credencial">E-mail, RA ou PUB</label>
                <input type="text" id="login-credencial" v-model="credencial" placeholder="Digite seu acesso" required>
            </div>
            
            <div class="grupo-input">
                <label for="login-senha">Senha</label>
                <input type="password" id="login-senha" v-model="senha" placeholder="Digite sua senha" required>
            </div>
            
            <button type="submit" class="btn-entrar" :disabled="carregando">
                {{ carregando ? 'Entrando...' : 'Entrar' }}
            </button>
            
            <footer class="login-rodape">
                <a href="#" class="link-senha" @click.prevent="alterarModo('recuperar')">Esqueceu a senha?</a>
                <a href="#" class="link-destaque" @click.prevent="alterarModo('cadastro')">Primeiro Acesso (Cadastrar)</a>
                <p class="texto-informativo mt-3">Acesso para Professores e Estudantes</p>
            </footer>
            </form>

            <!-- ==========================================
                2. FORMULÁRIO DE CADASTRO (Primeiro Acesso)
                ========================================== -->
            <form v-else-if="modo === 'cadastro'" class="login-formulario" @submit.prevent="realizarCadastro">
            <!-- NOVO CAMPO: Nome -->
            <div class="grupo-input">
                <label for="cad-nome">Nome Completo</label>
                <input type="text" id="cad-nome" v-model="nome" placeholder="Digite seu nome" required>
            </div>
            <div class="grupo-input">
                <label for="cad-email">E-mail (Para recuperação de senha)</label>
                <input type="email" id="cad-email" v-model="email" placeholder="seu@email.com" required>
            </div>

            <div class="grupo-input">
                <label for="cad-credencial">RA (Estudante) ou PUB (Professor)</label>
                <input type="text" id="cad-credencial" v-model="credencial" placeholder="Digite seu RA ou PUB" required>
            </div>
            
            <div class="grupo-input">
                <label for="cad-senha">Crie uma Senha</label>
                <input type="password" id="cad-senha" v-model="senha" placeholder="Mínimo de 6 caracteres" required minlength="6">
            </div>
            
            <button type="submit" class="btn-entrar" :disabled="carregando">
                {{ carregando ? 'Cadastrando...' : 'Cadastrar' }}
            </button>
            
            <footer class="login-rodape">
                <a href="#" class="link-senha" @click.prevent="alterarModo('login')">Voltar para o Login</a>
            </footer>
            </form>

            <!-- ==========================================
                3. FORMULÁRIO DE RECUPERAÇÃO DE SENHA
                ========================================== -->
            <form v-else class="login-formulario" @submit.prevent="recuperarSenha">
            <p class="texto-informativo mb-3">Enviaremos um link de recuperação para o seu e-mail cadastrado.</p>
            
            <div class="grupo-input">
                <label for="rec-email">E-mail Cadastrado</label>
                <input type="email" id="rec-email" v-model="email" placeholder="seu@email.com" required>
            </div>
            
            <button type="submit" class="btn-entrar" :disabled="carregando">
                {{ carregando ? 'Enviando...' : 'Enviar Link de Recuperação' }}
            </button>
            
            <footer class="login-rodape">
                <a href="#" class="link-senha" @click.prevent="alterarModo('login')">Voltar para o Login</a>
            </footer>
            </form>
            
        </div>
        </main>
    </div>
</template>
<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'

const router = useRouter()

// Estados da interface
const modo = ref('login')
const carregando = ref(false)
const mensagemErro = ref('')
const mensagemSucesso = ref('')

// Campos dos formulários
const credencial = ref('') 
const nome = ref('')
const email = ref('')
const senha = ref('')

// Função auxiliar para trocar de tela
const alterarModo = (novoModo) => {
    modo.value = novoModo
    mensagemErro.value = ''
    mensagemSucesso.value = ''
    senha.value = ''
    if (novoModo === 'login') {
        email.value = ''
        credencial.value = ''
        nome.value = ''
    }
}

// 1. LOGIN
const realizarLogin = async () => {
    carregando.value = true
    mensagemErro.value = ''
    mensagemSucesso.value = ''

    try {
        const identificador = credencial.value.includes('@') 
            ? credencial.value 
            : `${credencial.value.toLowerCase()}@hidrocare.com`

        const { data, error } = await supabase.auth.signInWithPassword({
            email: identificador,
            password: senha.value,
        })

        if (error) throw error

        // CORREÇÃO AQUI: Lê o perfil direto do banco de dados (metadados do JWT)
        const perfil = data.user.user_metadata?.perfil

        if (perfil === 'professor') {
            router.push('/tela-professor')
        } else {
            router.push('/tela-estudante')
        }
    } catch (error) {
        mensagemErro.value = 'Credenciais inválidas. Tente novamente.'
    } finally {
        carregando.value = false
    }
}

// 2. CADASTRO (Primeiro Acesso)
const realizarCadastro = async () => {
    carregando.value = true
    mensagemErro.value = ''
    mensagemSucesso.value = ''

    try {
        // CORREÇÃO AQUI: Define as variáveis que faltavam antes de enviar pro banco
        const credencialFormatada = credencial.value.trim().toUpperCase()
        const tipoPerfil = credencialFormatada.startsWith('PUB') ? 'professor' : 'estudante'

        const { error } = await supabase.auth.signUp({
            email: email.value,
            password: senha.value,
            options: {
                data: {
                    ra: credencialFormatada, 
                    nome: nome.value, 
                    perfil: tipoPerfil
                }
            }
        })

        if (error) throw error

        mensagemSucesso.value = 'Cadastro realizado! Você já pode fazer login.'
        setTimeout(() => alterarModo('login'), 2000)
    } catch (error) {
        mensagemErro.value = error.message.includes('already registered') 
            ? 'Este e-mail já está cadastrado.' 
            : 'Erro ao realizar cadastro. Verifique os dados.'
    } finally {
        carregando.value = false
    }
}

// 3. RECUPERAÇÃO DE SENHA
const recuperarSenha = async () => {
    carregando.value = true
    mensagemErro.value = ''
    mensagemSucesso.value = ''

    try {
        const { error } = await supabase.auth.resetPasswordForEmail(email.value, {
            redirectTo: 'http://localhost:5173/redefinir-senha',
        })

        if (error) throw error

        mensagemSucesso.value = 'Link de recuperação enviado para o seu e-mail!'
    } catch (error) {
        mensagemErro.value = 'Erro ao tentar enviar o link de recuperação.'
    } finally {
        carregando.value = false
    }
}
</script>

<style scoped>
.fundo-tela { display: flex; justify-content: center; align-items: center; min-height: 100vh; }
.login-container { width: 100%; max-width: 420px; padding: 20px; }
.login-cartao { background-color: #ffffff; padding: 40px 35px; border-radius: 8px; box-shadow: 0 4px 15px rgba(0, 0, 0, 0.05); text-align: center; }
.login-cabecalho { margin-bottom: 30px; }
.logo-titulo { color: #1a56db; font-size: 32px; font-weight: 700; margin-bottom: 5px; }
.logo-subtitulo { color: #6c757d; font-size: 15px; }
.alerta-erro { background-color: #f8d7da; color: #842029; border: 1px solid #f5c2c7; padding: 12px; border-radius: 6px; margin-bottom: 20px; font-size: 14px; text-align: left; }
.login-form, .login-formulario { text-align: left; }
.grupo-input { margin-bottom: 20px; }
.grupo-input label { display: block; margin-bottom: 8px; color: #374151; font-weight: 500; font-size: 14px; }
.grupo-input input, .grupo-input select { width: 100%; padding: 12px 15px; border: 1px solid #d1d5db; border-radius: 6px; font-size: 15px; outline: none; transition: border-color 0.2s, box-shadow 0.2s; }
.grupo-input input:focus, .grupo-input select:focus { border-color: #1a56db; box-shadow: 0 0 0 3px rgba(26, 86, 219, 0.15); }
.btn-entrar { width: 100%; padding: 12px; background-color: #1a56db; color: white; border: none; border-radius: 6px; font-size: 16px; font-weight: 600; cursor: pointer; transition: background-color 0.2s; margin-bottom: 25px; margin-top: 10px; }
.btn-entrar:hover { background-color: #1e40af; }
.login-rodape { text-align: center; }
.link-senha { color: #1a56db; text-decoration: none; font-size: 14px; display: block; margin-bottom: 20px; }
.link-senha:hover { text-decoration: underline; }
.texto-informativo { color: #4b5563; font-size: 13px; margin-bottom: 8px; }
</style>