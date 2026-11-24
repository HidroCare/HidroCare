-- =====================================================================
-- HidroCare · 07 · OPCIONAL · Aceitar cadastro só com e-mail institucional
-- Rodar só se sobrar tempo, DEPOIS de tudo funcionando.
--
-- Sem isto, a tela impede e-mails de outros domínios, mas o Supabase
-- aceita cadastros vindos de fora do site. Este gatilho faz o BANCO recusar.
--
-- CUIDADO: depois deste script, TODA conta nova (inclusive as de demonstração
-- criadas no painel) precisa de e-mail @mg.senac.br ou @senacminas.edu.br.
-- Se o cadastro quebrar por causa dele, desfaça com:
--   drop trigger validar_dominio_email on auth.users;
-- =====================================================================

create or replace function public.validar_dominio_email()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.email is null or new.email !~* '@(mg\.senac\.br|senacminas\.edu\.br)$' then
    raise exception 'Use o e-mail institucional (@mg.senac.br ou @senacminas.edu.br).';
  end if;
  return new;
end;
$$;

drop trigger if exists validar_dominio_email on auth.users;
create trigger validar_dominio_email
  before insert on auth.users
  for each row execute function public.validar_dominio_email();
