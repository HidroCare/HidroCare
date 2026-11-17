import { createClient } from '@supabase/supabase-js'

// Lido ANTES do createClient: o supabase-js limpa o endereço (#...) ao iniciar,
// e é nele que o link de "esqueci a senha" avisa que veio de recuperação.
export const abriuPeloLinkDeRecuperacao = window.location.hash.includes('type=recovery')

export const supabase = createClient(
    import.meta.env.VITE_SUPABASE_URL,
    import.meta.env.VITE_SUPABASE_ANON_KEY
)
