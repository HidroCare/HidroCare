// Existe só por compatibilidade: o cliente oficial é o de src/lib/supabase.js.
// Dois createClient na mesma página criam dois "logins" concorrentes.
export { supabase, abriuPeloLinkDeRecuperacao } from '@/lib/supabase'