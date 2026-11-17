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
                        <span v-else-if="modo === 'novaSenha'">Defina sua nova senha</span>
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
                        <label for="login-credencial">E-mail institucional, RA ou PUB</label>
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
                
                    <div class="grupo-input">
                        <label for="cad-nome">Nome Completo</label>
                        <input type="text" id="cad-nome" v-model="nome" placeholder="Digite seu nome" required>
                    </div>
                    <div class="grupo-input">
                        <label for="cad-email">E-mail institucional</label>
                        <input type="email" id="cad-email" v-model="email" placeholder="seu e-mail institucional" required>
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
                    3. NOVA SENHA (chegou pelo link do e-mail)
                    ========================================== -->
                <form v-else-if="modo === 'novaSenha'" class="login-formulario" @submit.prevent="salvarNovaSenha">
                    <div class="grupo-input">
                        <label for="nova-senha">Nova senha</label>
                        <input type="password" id="nova-senha" v-model="senha" placeholder="Mínimo de 6 caracteres" required minlength="6">
                    </div>
                    <div class="grupo-input">
                        <label for="nova-senha2">Repita a nova senha</label>
                        <input type="password" id="nova-senha2" v-model="confirmarSenha" placeholder="Digite novamente" required minlength="6">
                    </div>
                    <button type="submit" class="btn-entrar" :disabled="carregando">
                        {{ carregando ? 'Salvando...' : 'Salvar nova senha' }}
                    </button>
                </form>

                <!-- ==========================================
                    4. FORMULÁRIO DE RECUPERAÇÃO DE SENHA
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
import { supabase, abriuPeloLinkDeRecuperacao } from '@/lib/supabase'
import { paginaInicial } from '@/composables/useAuth'

const router = useRouter()

// Domínios institucionais aceitos (os mesmos que o banco aceita)
const DOMINIO_ESTUDANTE = 'senacminas.edu.br'
const DOMINIO_PROFESSOR = 'mg.senac.br'
const EMAIL_INSTITUCIONAL = /@(mg\.senac\.br|senacminas\.edu\.br)$/i

// Estados da interface
// 'login', 'cadastro', 'recuperar' ou 'novaSenha' (quando a pessoa chega pelo link do e-mail)
const modo = ref(abriuPeloLinkDeRecuperacao ? 'novaSenha' : 'login')
const carregando = ref(false)
const mensagemErro = ref('')
const mensagemSucesso = ref('')

// Campos dos formulários
const credencial = ref('') // No login: e-mail, RA ou PUB
const nome = ref('')
const email = ref('')
const senha = ref('')
const confirmarSenha = ref('')

// Função auxiliar para trocar de tela e limpar os campos/mensagens
const alterarModo = (novoModo) => {
    modo.value = novoModo
    mensagemErro.value = ''
    mensagemSucesso.value = ''
    senha.value = ''
    confirmarSenha.value = ''
    if (novoModo === 'login') email.value = ''
}

// Transforma o que a pessoa digitou no e-mail institucional:
// já tem @ -> usa como está | começa com "pub" -> professor | senão é um RA -> estudante
const montarEmail = (digitado) => {
    const texto = digitado.trim().toLowerCase()
    if (texto.includes('@')) return texto
        return texto.startsWith('pub') ? `${texto}@${DOMINIO_PROFESSOR}` : `${texto}@${DOMINIO_ESTUDANTE}`
}

// 1. LOGIN
const realizarLogin = async () => {
    carregando.value = true
    mensagemErro.value = ''
    mensagemSucesso.value = ''

    try {
        const { data, error } = await supabase.auth.signInWithPassword({
            email: montarEmail(credencial.value),
            password: senha.value,
        })

        if (error) throw error

        // O perfil (professor ou estudante) vem do banco, e não do que foi digitado
        const { data: usuario, error: erroPerfil } = await supabase
            .from('usuarios')
            .select('perfil')
            .eq('id', data.user.id)
            .single()

        if (erroPerfil || !usuario) {
            await supabase.auth.signOut()
            mensagemErro.value = 'Seu perfil não foi encontrado. Fale com o professor.'
            return
        }

        router.push(paginaInicial(usuario.perfil))
    } catch (error) {
        mensagemErro.value = error.message.includes('Email not confirmed')
        ? 'Confirme seu e-mail pelo link que enviamos antes de entrar.'
        : 'Credenciais inválidas. Tente novamente.'
    } finally {
        carregando.value = false
    }
}

// 2. CADASTRO (Primeiro Acesso)
const realizarCadastro = async () => {
    mensagemErro.value = ''
    mensagemSucesso.value = ''

    // Valida antes: o banco só aceita e-mail institucional
    if (!EMAIL_INSTITUCIONAL.test(email.value.trim())) {
        mensagemErro.value = 'Use o e-mail institucional (@senacminas.edu.br ou @mg.senac.br).'
        return
    }

    carregando.value = true

    try {
        const { error } = await supabase.auth.signUp({
            email: email.value.trim(),
            password: senha.value,
            options: {
                data: {
                    nome: nome.value.trim() // O banco usa o nome para criar o perfil; o perfil sai do e-mail
                }
            }
        })

        if (error) throw error

        mensagemSucesso.value = 'Cadastro realizado! Confirme seu e-mail pelo link que enviamos e depois faça login.'
        setTimeout(() => alterarModo('login'), 4000) // Volta pro login após 4 segundos
    } catch (error) {
        mensagemErro.value = error.message.includes('already registered')
        ? 'Este e-mail já está cadastrado.'
        : 'Erro ao realizar cadastro. Verifique os dados.'
    } finally {
        carregando.value = false
    }
}

// 3. RECUPERAÇÃO DE SENHA (pede o link)
const recuperarSenha = async () => {
    carregando.value = true
    mensagemErro.value = ''
    mensagemSucesso.value = ''

    try {
        const { error } = await supabase.auth.resetPasswordForEmail(email.value.trim(), {
            // O link do e-mail volta para esta mesma tela, que abre o formulário de nova senha.
            // Este endereço precisa estar nas Redirect URLs do Supabase (ex.: http://localhost:5173/**).
            redirectTo: `${window.location.origin}/`,
        })

        if (error) throw error

        mensagemSucesso.value = 'Link de recuperação enviado para o seu e-mail!'
    } catch (error) {
        mensagemErro.value = 'Erro ao tentar enviar o link de recuperação.'
    } finally {
        carregando.value = false
    }
}

// 4. NOVA SENHA (a pessoa chegou pelo link do e-mail e já tem uma sessão temporária)
const salvarNovaSenha = async () => {
    mensagemErro.value = ''
    mensagemSucesso.value = ''

    if (senha.value !== confirmarSenha.value) {
        mensagemErro.value = 'As senhas não são iguais.'
        return
    }

    carregando.value = true

    try {
        const { error } = await supabase.auth.updateUser({ password: senha.value })
        if (error) throw error

        await supabase.auth.signOut() // Sai da sessão temporária e pede o login com a senha nova
        window.history.replaceState(null, '', '/') // Limpa o endereço
        alterarModo('login')
        mensagemSucesso.value = 'Senha alterada! Entre com a nova senha.'
    } catch (error) {
        mensagemErro.value = 'Não foi possível salvar a senha. O link pode ter expirado: peça um novo.'
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
.alerta-sucesso { background-color: #d1e7dd; color: #0f5132; border: 1px solid #badbcc; padding: 12px; border-radius: 6px; margin-bottom: 20px; font-size: 14px; text-align: left; }
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