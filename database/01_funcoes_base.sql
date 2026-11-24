-- =====================================================================
-- HidroCare · 01 · Funções de base
-- Rodar PRIMEIRO. Pode ser rodado de novo sem problema.
--
-- is_admin() responde: "quem está logado é professor?"
-- Regra do projeto: professor = e-mail  pubXXXX@mg.senac.br
--                   estudante = qualquer outro e-mail (RA@senacminas.edu.br)
--
-- POR QUE O E-MAIL E NÃO A COLUNA "perfil"?
-- O e-mail da conta, depois de confirmado, não pode ser alterado pelo
-- próprio usuário. Já os dados que o usuário envia no cadastro podem ser.
-- Por isso a permissão se baseia no e-mail (e a confirmação de e-mail
-- precisa estar LIGADA no Supabase: Authentication > Providers > Email).
-- =====================================================================

create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select coalesce((auth.jwt() ->> 'email') ~* '^pub[^@]*@mg\.senac\.br$', false);
$$;

grant execute on function public.is_admin() to authenticated;
